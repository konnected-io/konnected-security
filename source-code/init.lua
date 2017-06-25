print("Starting.. Memory: " .. node.heap())
require("compile")
require("variables")
print("Heap: ", node.heap(), "Loaded: ", "variables")

enduser_setup.manual(false)
enduser_setup.start()

tmr.create():alarm(700, tmr.ALARM_AUTO, function(t)
  if gpio.read(4) == gpio.LOW then
    gpio.write(4, gpio.HIGH)
  else
    gpio.write(4, gpio.LOW)
  end
  if wifi.sta.getip() then
    t:unregister()
    t = nil
    gpio.write(4, gpio.HIGH)
    enduser_setup.stop()
    require("server")
    print("Heap: ", node.heap(), "Loaded: ", "server")
    require("application")
    print("Heap: ", node.heap(), "Loaded: ", "application")
    print("Started.. Memory: " .. node.heap() .. " IP: " .. wifi.sta.getip())
  end
end)