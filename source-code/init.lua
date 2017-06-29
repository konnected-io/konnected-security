print("Heap: ", node.heap(), "Initializing device")
require("compile")
print("Heap: ", node.heap(), "Loaded: ", "compile")
require("variables")
print("Heap: ", node.heap(), "Loaded: ", "variables")

if wifi.sta.getconfig() == "" then 
  enduser_setup.manual(false)
  enduser_setup.start()
  print("Heap: ", node.heap(), "End User Setup started")
end

local _ = tmr.create():alarm(700, tmr.ALARM_AUTO, function(t)
  require("led_flip").flip()
  if wifi.sta.getip() then
    t:unregister()
    t = nil
    print("Heap: ", node.heap(), "Wifi connected with IP: ", wifi.sta.getip())
    if file.exists("update_init.lc")then
      require("update")
    else 
      gpio.write(4, gpio.HIGH)
      enduser_setup.stop()
      require("server")
      print("Heap: ", node.heap(), "Loaded: ", "server")
      require("application")
      print("Heap: ", node.heap(), "Loaded: ", "application")
    end
  end
end)

