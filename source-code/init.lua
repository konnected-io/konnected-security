print("Starting.. Memory: " .. node.heap())
require("compile")
require("variables")
enduser_setup.manual(false)
enduser_setup.start()
gpio.mode(4, gpio.OUTPUT)
tmr.create():alarm(700, tmr.ALARM_AUTO, function(t)
  if gpio.read(4) == gpio.LOW then
    gpio.write(4, gpio.HIGH)
  else
    gpio.write(4, gpio.LOW)
  end
  if wifi.sta.getip() then
    t:unregister()
    t = nil
    gpio.write(4, gpio.LOW)
    enduser_setup.stop()
    require("server")
    require("application")
    print("Started.. Memory: " .. node.heap() .. " IP: " .. wifi.sta.getip())
  end
end)







