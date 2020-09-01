local module = ...

local log = require("log")

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

	elseif (request.method == "PUT" or request.method == "POST") and request.contentType == "application/json" then
		-- Ensure the settings lock flag isn't present
		local device_config = file.exists("device_config.lc") and require("device_config") or {}
		if device_config.lock_sig and device_config.lock_sig ~= "" then
			return '{ "msg":"settings are locked" }', nil, 409
		end

		local setVar = require("variables_set")
		setVar("settings", require("variables_build")({
			token = request.body.token,
			endpoint = (request.body.endpoint or request.body.apiUrl),
			endpoint_type = request.body.endpoint_type,
			blink = request.body.blink,
			discovery = request.body.discovery,
			aws = request.body.aws
		}))
		setVar("sensors",   require("variables_build")(request.body.sensors))
		setVar("actuators", require("variables_build")(request.body.actuators))
		setVar("dht_sensors", require("variables_build")(request.body.dht_sensors))
		setVar("ds18b20_sensors", require("variables_build")(request.body.ds18b20_sensors))

		log.warn('Settings updated! Reboot in 5s')
		restartTimer:start()

		return ""
	end
end

return function(request)
	package.loaded[module] = nil
	module = nil
	return process(request)
end