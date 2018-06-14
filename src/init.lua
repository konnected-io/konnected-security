print("Heap: ", node.heap(), "Initializing Konnected (" .. string.gsub(wifi.sta.getmac(), ":", "") .. ")")
require("start")
print("Heap: ", node.heap(), "Version: ", require("device").swVersion)
print("Heap: ", node.heap(), "Connecting to Wifi..")

-- hack to ensure pin D8 stays low after boot so it can be used with a high-level trigger relay
gpio.mode(8, gpio.OUTPUT)
gpio.write(8, gpio.LOW)

local startWifiSetup = function()
  print("Heap: ", node.heap(), "Entering Wifi setup mode")
  wifi.eventmon.unregister(wifi.eventmon.STA_DISCONNECTED)
  wifiFailTimer:unregister()
  wifiFailTimer = nil
  enduser_setup.manual(false)
  enduser_setup.start()
  failsafeTimer:start()
end

-- wait 30 seconds before entering wifi setup mode in case of a momentary outage
wifiFailTimer = tmr.create()
wifiFailTimer:register(30000, tmr.ALARM_SINGLE, function() startWifiSetup() end)

-- failsafe: reboot after 5 minutes in case of extended wifi outage
failsafeTimer = tmr.create()
failsafeTimer:register(300000, tmr.ALARM_SINGLE, function() node.restart() end)

wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
  print("Heap: ", node.heap(), "Cannot connect to WiFi ", T.SSID, 'Reason Code:', T.reason)

  if T.reason == wifi.eventmon.reason.AUTH_EXPIRE then
    -- wifi password is incorrect, immediatly enter setup mode
    print("Heap: ", node.heap(), "Wifi password is incorrect")
    startWifiSetup()
  else
    wifiFailTimer:start()
  end
end)

if wifi.sta.getconfig() == "" then
  print("Heap: ", node.heap(), "WiFi not configured")
  startWifiSetup()
  print("Heap: ", node.heap(), "WiFi Setup started")
end

local _ = tmr.create():alarm(900, tmr.ALARM_AUTO, function(t)
  require("led_flip").flip()
  if wifi.sta.getip() then
    wifi.eventmon.unregister(wifi.eventmon.STA_DISCONNECTED)
    t:unregister()
    t = nil
    if wifiFailTimer then
      wifiFailTimer:unregister()
      wifiFailTimer = nil
    end
    failsafeTimer:unregister()
    failsafeTimer = nil
    print("Heap: ", node.heap(), "Wifi connected with IP: ", wifi.sta.getip())

    gpio.write(4, gpio.HIGH)
    enduser_setup.stop()
    require("server")
    print("Heap: ", node.heap(), "Loaded: ", "server")
    require("application")
    print("Heap: ", node.heap(), "Loaded: ", "application")
  end
end)

