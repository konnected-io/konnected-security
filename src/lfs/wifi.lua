print("Heap: ", node.heap(), "Connecting to Wifi..")
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
    local ip, nm, gw = wifi.sta.getip()
    print("Heap: ", node.heap(), "Wifi connected with IP: ", ip, "Gateway:", gw)

    gpio.write(4, gpio.HIGH)
    enduser_setup.stop()

    sntp.sync({gw, 'time.google.com', 'pool.ntp.org'},
      function(sec)
        tm = rtctime.epoch2cal(sec)
        print("Heap: ", node.heap(), "Current Time set:",
          string.format("%04d-%02d-%02d %02d:%02d:%02d UTC",
            tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"]))
        require("server")
        print("Heap: ", node.heap(), "Loaded: ", "server")
        require("application")
        print("Heap: ", node.heap(), "Loaded: ", "application")
      end,
      function()
        print("Heap: ", node.heap(), "Time sync failed!")
      end)
  end
end)

