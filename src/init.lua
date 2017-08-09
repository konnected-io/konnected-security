print("Heap: ", node.heap(), "Initializing device")
require("start")
print("Heap: ", node.heap(), "Loaded: ", "Startup (compiler & blinker)")
print("Heap: ", node.heap(), "Connecting to Wifi..")
local startCountDown = 0

wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
  print("Heap: ", node.heap(), "Cannot connect to WiFi:", T.SSID, T.BSSID, T.reason)
  enduser_setup.manual(false)
  enduser_setup.start()
  wifi.eventmon.unregister(wifi.eventmon.STA_DISCONNECTED)
  print("Heap: ", node.heap(), "WiFi Setup started")
end)

if wifi.sta.getconfig() == "" then
  print("Heap: ", node.heap(), "WiFi not configured")
  startCountDown = 5
  enduser_setup.manual(false)
  enduser_setup.start()
  print("Heap: ", node.heap(), "WiFi Setup started")
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
        wifi.eventmon.unregister(wifi.eventmon.STA_DISCONNECTED)
        require("server")
        print("Heap: ", node.heap(), "Loaded: ", "server")
        require("application")
        print("Heap: ", node.heap(), "Loaded: ", "application")
      end
    end
  end
end)

