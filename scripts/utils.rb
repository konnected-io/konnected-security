require 'pty'
require 'expect'
require 'colorize'

PORT='/dev/cu.SLAB_USBtoUART'
IMG_PATH='~/Downloads/konnected-esp8266-v3.1.4.bin'

def get_device_id
  output = `esptool.py --port=#{PORT} chip_id`
  mac = output.match(/MAC: ([\w\:]+)/)[1]
  mac.gsub(':','').downcase
end

puts "Flashing latest firmware".yellow
system("esptool.py --port=#{PORT} write_flash --flash_mode dio 0x0 #{IMG_PATH}")
sleep(5)

def check_gpio(pin, i, r, w)
  w.printf("\n")
  w.printf("gpio.mode(#{pin}, gpio.INPUT, gpio.PULLUP)\n") unless pin == 9
  cmd = "print(gpio.read(#{pin}))\n"
  w.printf(cmd)
  result = r.expect(/^(\d)$/, 1)
  
  return false unless result
  r.expect('>')
  print "Zone #{i+1}: "
  expected = pin == 9 ? '0' : '1'
  pass = result[1] == expected
  puts(pass ? "OK".green : "FAIL".red)
  return pass
end

PTY.spawn("nodemcu-tool terminal --port=#{PORT}") do |r, w, pid|
  puts r.expect(/exit/)
  w.printf("\n\n")  
  r.expect('>')
  w.printf("node.restore()\n")
  r.expect('>')
  w.printf("print(wifi.sta.getmac())\n")
  r.expect('>')
  mac = r.expect(/([\w\:]{17})/, 1)[1]
  puts "\n\nDevice ID: #{mac.strip.gsub(':','')}"
  puts "Starting self-check".yellow
  
  [1,2,5,6,7,9].each_with_index do |pin, i|
    while true do 
      break if check_gpio(pin, i, r, w)
      puts "Zone #{i+1}: " + "ERR".yellow
      w.printf("\n\n")
    end
  end
  
  w.printf("gpio.mode(8, gpio.OUTPUT)\n")
  w.printf("gpio.write(8,1)\n")
  w.printf("print(gpio.read(8))\n")
  val = r.expect(/> (\d)$/, 5)[1]
  print "Zone OUT: "
  puts(val == '1' ? "OK".green : "FAIL".red)

  Process.kill('INT', pid)
end