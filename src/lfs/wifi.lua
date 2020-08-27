local log = require("log")

log.info("Connecting to Wifi..")
local startWifiSetup = function()
  log.info("Entering Wifi setup mode")
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
  log.warn("Cannot connect to WiFi ", T.SSID, 'Reason Code:', T.reason)

  if T.reason == wifi.eventmon.reason.AUTH_EXPIRE then
    -- wifi password is incorrect, immediatly enter setup mode
    log.warn("Wifi password is incorrect")
    startWifiSetup()
  else
    wifiFailTimer:start()
  end
end)

if wifi.sta.getconfig() == "" then
  log.info("WiFi not configured")
  startWifiSetup()
  log.info("WiFi Setup started")
end

local bootApp = function()
  log.info("Booting Konnected application")
  require("server")
  log.info("Loaded: ", "server")
  require("application")
  log.info("Loaded: ", "application")
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
    log.info("Wifi connected with IP: ", ip, "Gateway:", gw)

    gpio.write(4, gpio.HIGH)
    enduser_setup.stop()

    sntp.sync({gw, 'time.google.com', 'pool.ntp.org'},
      function(sec)
        tm = rtctime.epoch2cal(sec)
        log.info("Current Date/Time:",
          string.format("%04d-%02d-%02d %02d:%02d:%02d UTC",
            tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"]))
        bootApp()
      end,
      function()
        log.info("Time sync failed!")
        bootApp()
      end)
  end
end)
