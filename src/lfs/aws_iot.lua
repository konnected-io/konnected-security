local module = ...

local mqtt = require('mqtt_ws')
local settings = require('settings')
local zoneToPin = require("zone_to_pin")
local device_id = wifi.sta.getmac():lower():gsub(':','')
local c = mqtt.Client(settings.aws)
local topics = settings.aws.topics

local sendTimer = tmr.create()
local timeout = tmr.create()
local mqttTimeout = tmr.create()
local heartbeat = tmr.create()

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
      local topic = sensor.topic or topics.sensor
		  sensor.device_id = device_id
			print("Heap:", node.heap(), "PUBLISH", "Message ID:", message_id, "Topic:", topic, "Payload:", sjson.encode(sensor))
			timeout:start()
			c:publish(topic, sensor)
			sensor.message_id = message_id
		end
	end
end)

heartbeat:register(200, tmr.ALARM_AUTO, function(t)
  local hb = require('server_status')()
  hb.topic = topics.heartbeat
  hb.timestamp = rtctime.get()
  table.insert(sensorPut, hb)
  t:interval(300000) -- 5 minutes
end)

mqttTimeout:register(10000, tmr.ALARM_SEMI, function(t)
	print("Heap:", node.heap(), 'Couldn\'t connect to AWS IoT! Restarting.')
	node.restart()
end)

local function startLoop()
	print("Heap:", node.heap(), 'Connecting to AWS IoT Endpoint:', settings.endpoint)

	local mqttFails = 0
	c:on('offline', function()
		mqttFails = mqttFails + 1
		print("Heap:", node.heap(), "mqtt: offline", "failures:", mqttFails)
		sendTimer:stop()

		if mqttFails >= 10 then
			tmr.create():alarm(3000, tmr.ALARM_SINGLE, function() node.restart() end) -- reboot in 3 sec
		else
			c:connect(settings.endpoint)
		end
	end)

	mqttTimeout:start()
  -- stripping -ats uses the endpoint with a smaller cert chain
	c:connect(string.gsub(settings.endpoint, "-ats", ""))
end

c:on('puback', function(_, message_id)
  print("Heap:", node.heap(), 'PUBACK', 'Message ID:', message_id)
	local sensor = sensorPut[1]
	if sensor and sensor.message_id == message_id then
		table.remove(sensorPut, 1)
		blinktimer:start()
		timeout:stop()
		sendTimer:start()
	end
end)

c:on('message', function(_, topic, message)
	print("Heap:", node.heap(), 'topic:', topic, 'msg:', message)
	local payload = sjson.decode(message)
	local endState = require("switch")(payload)

	-- publish the new state after actuating switch
	table.insert(sensorPut, endState)

	-- set state back to initial after momentary is complete
	if payload.momentary and payload.times ~= -1 then
		local pause = payload.pause or 0
		local times = payload.times or 1

		local revertIn = (payload.momentary + pause) * times - pause
		tmr.create():alarm(revertIn, tmr.ALARM_SINGLE, function()
			local revertState = { pin = endState.pin, state = endState.state == 0 and 1 or 0}
			if endState.zone ~= nil then
			  revertState = { zone = endState.zone, state = endState.state == 0 and 1 or 0}
			end
			table.insert(sensorPut, revertState)
		end)
	end
end)

c:on('connect', function()
	mqttTimeout:stop()
	print("Heap:", node.heap(), "mqtt: connected")
	print("Heap:", node.heap(), "Subscribing to topic:", topics.switch)
	c:subscribe(topics.switch)

	-- update current state of actuators upon boot
	for i, actuator in pairs(actuatorGet) do
		if actuator.zone ~= nil then
			table.insert(sensorPut, { zone = actuator.zone, state = gpio.read(zoneToPin(actuator.zone)) })
		else
			table.insert(sensorPut, { pin = actuator.pin, state = gpio.read(actuator.pin) })
		end
	end

	heartbeat:start()
	sendTimer:start()
end)

return function()
	package.loaded[module] = nil
	module = nil
	return startLoop()
end