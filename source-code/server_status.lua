local me = {
  process = function (request, response) 
    local ip, nm, gw = wifi.sta.getip()
    local device = require("device")
    local body = {
      hwVersion = device.name .. " \/ " .. device.hwVersion,
      swVersion = device.swVersion,
      heap = node.heap(),
      uptime = tmr.time(),
      ip = ip,
      nm = nm,
      gw = gw,
      mac = wifi.sta.getmac(),
      rssi = wifi.sta.getrssi()
    }
    response.send(cjson.encode(body))
  end
}
return me
