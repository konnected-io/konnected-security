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

tmr.create():alarm(700, tmr.ALARM_AUTO, function(t)
  if gpio.read(4) == gpio.LOW then
    gpio.write(4, gpio.HIGH)
  else
    gpio.write(4, gpio.LOW)
  end
  if wifi.sta.getip() then
    t:unregister()
    t = nil
    print("Heap: ", node.heap(), "Wifi connected with IP: ", wifi.sta.getip())
    if (update) then
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

