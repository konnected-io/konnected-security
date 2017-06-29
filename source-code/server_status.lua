local me = {
	process = function (request, response) 
		local device = require("device")
    local body = {
      hwVersion = device.name .. " \/ " .. device.hwVersion,
      swVersion = device.swVersion,
      heap = node.heap(),
      ip = wifi.sta.getip(),
      mac = wifi.sta.getmac(),
      uptime = tmr.time()
    }
    response.send(cjson.encode(body))
  end
}
return me