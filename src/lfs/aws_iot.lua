local module = ...

local mqtt = require('mqtt_ws')
local settings = require('settings')
local device_id = wifi.sta.getmac():lower():gsub(':','')
local c = mqtt.Client(settings.aws)
local topics = settings.aws.topics

local function mqtt_ws_endpoint()
	if settings.aws.secret_key and settings.aws.access_key then
		local aws_sig = require('aws_sig')
		local url = aws_sig.createSignature(
			settings.aws.access_key, settings.aws.secret_key, settings.aws.session_token,
			settings.aws.region, 'iotdevicegateway', 'GET', settings.endpoint, '')

		aws_sig = nil
		package.loaded.aws_sig = nil
		return url
	else
		return settings.endpoint
	end
end

local sendTimer = tmr.create()
local timeout = tmr.create()

timeout:register(3000, tmr.ALARM_SEMI, function()
	sensorPut[1].retry = (sensorPut[1].retry or 0) + 1
	sensorPut[1].message_id = nil
	sendTimer:start()
end)

sendTimer:register(200, tmr.ALARM_AUTO, function(t)
	local sensor = sensorPut[1]
	if sensor then
		t:stop()

		if sensor.retry and sensor.retry > 0 then
			print("Heap:", node.heap(), "Retry:", sensor.retry)
		end

		if sensor.retry and sensor.retry > 10 then
			print("Heap:", node.heap(), "Retried 10 times and failed. Rebooting in 30 seconds.")
			for k, v in pairs(sensorPut) do sensorPut[k] = nil end -- remove all pending sensor updates
			tmr.create():alarm(30000, tmr.ALARM_SINGLE, function() node.restart() end) -- reboot in 30 sec
		else
			local message_id = c.msg_id
		  sensor.device_id = device_id
			print("Heap:", node.heap(), "PUBLISH", "Message ID:", message_id, "Topic:", topics.sensor, "Payload:", sjson.encode(sensor))
			timeout:start()
			c:publish(topics.sensor, sensor)
			sensor.message_id = message_id
		end
	end
end)

local function startLoop()
	print("Heap:", node.heap(), 'Connecting to AWS IoT Endpoint:', settings.endpoint)

	c:on('offline', function()
		print("Heap:", node.heap(), "mqtt: offline")
		sendTimer:stop()
		c:connect(mqtt_ws_endpoint())
	end)

	c:connect(mqtt_ws_endpoint())
end

c:on('puback', function(_, message_id)
	local sensor = sensorPut[1]
	if sensor.message_id == message_id then
		print("Heap:", node.heap(), 'PUBACK', 'Message ID:', message_id)
		table.remove(sensorPut, 1)
		blinktimer:start()
		timeout:stop()
		sendTimer:start()
	end
end)

c:on('message', function(_, topic, message)
	print("Heap:", node.heap(), 'topic:', topic, 'msg:', message)
	local payload = sjson.decode(message)
	require("switch")(payload)

	-- publish the new state after actuating switch
	table.insert(sensorPut, { pin = payload.pin, state = gpio.read(payload.pin) })
end)

c:on('connect', function()
	print("Heap:", node.heap(), "mqtt: connected")
	print("Heap:", node.heap(), "Subscribing to topic:", topics.switch)
	c:subscribe(topics.switch)

	-- update current state of actuators upon boot
	for i, actuator in pairs(actuatorGet) do
		table.insert(sensorPut, { pin = actuator.pin, state = gpio.read(actuator.pin) })
	end

	sendTimer:start()
end)

return function()
	package.loaded[module] = nil
	module = nil
	return startLoop()
end