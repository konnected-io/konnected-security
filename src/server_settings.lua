local module = ...
local restartTimer = tmr.create()
restartTimer:register(2000, tmr.ALARM_SINGLE, function() node.restart() end)
local function process(request)
	if request.method == "GET" then
		if request.query then
			request.query.restart = request.query.restart or "false"
			request.query.restore = request.query.restore or "false"
		end
		if request.query.restart == "true" then
			restartTimer:start()
		end
		if request.query.restore == "true" then
			node.restore()
			restartTimer:start()
		end
		return ""
	end
	if request.contentType == "application/json" then
		if request.method == "PUT" then
			local setVar = require("variables_set")
			setVar("settings", table.concat(
				{ "{ token = \"", request.body.token, "\",\r\n apiUrl = \"", request.body.apiUrl, "\",\r\n blink = ", tostring(request.body.blink), " }" }))
			setVar("sensors",   require("variables_build")(request.body.sensors))
			setVar("actuators", require("variables_build")(request.body.actuators))
			setVar("dht_sensors", require("variables_build")(request.body.dht_sensors))

			print("Heap:", node.heap(), 'Settings updated! Restarting in 5 seconds...')
			restartTimer:start()

			return ""
		end
	end
end

return function(request)
	package.loaded[module] = nil
	module = nil
	return process(request)
end