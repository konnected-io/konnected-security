print("Heap: ", node.heap(), "Initializing device")
require("start")
print("Heap: ", node.heap(), "Loaded: ", "Startup (compiler & blinker)")
print("Heap: ", node.heap(), "Connecting to Wifi..")
local startCountDown = 0

if wifi.sta.getconfig() == "" then 
  startCountDown = 5
  enduser_setup.manual(false)
  enduser_setup.start()
  print("Heap: ", node.heap(), "End User Setup started")
end


local _ = tmr.create():alarm(900, tmr.ALARM_AUTO, function(t)
  require("led_flip").flip()
  if wifi.sta.getip() then
    t:unregister()
    t = nil
    print("Heap: ", node.heap(), "Wifi connected with IP: ", wifi.sta.getip())
    if file.exists("update_init.lc")then
      require("update")
    else 
      if startCountDown > 1 then
        startCountDown = startCountDown - 1
      else
        startCountDown = nil
        gpio.write(4, gpio.HIGH)
        enduser_setup.stop()
        require("server")
        print("Heap: ", node.heap(), "Loaded: ", "server")
        require("application")
        print("Heap: ", node.heap(), "Loaded: ", "application")
      end
    end
  end
end)

