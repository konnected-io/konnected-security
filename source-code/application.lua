local sensorSend = { }

for i,sensor in pairs(sensors) do
  print('Initializing sensor on pin ' .. sensor.pin)
  gpio.mode(sensor.pin, gpio.INPUT, gpio.PULLUP)
end

for i,actuator in pairs(actuators) do
  print('Initializing actuator on pin ' .. actuator.pin)
  gpio.mode(actuator.pin, gpio.OUTPUT)
  gpio.write(actuator.pin, gpio.LOW)
end

tmr.create():alarm(200, tmr.ALARM_AUTO,function(t)
	for i, sensor in pairs(sensors) do
		if sensor.state ~= gpio.read(sensor.pin) then
			sensor.state = gpio.read(sensor.pin)
			table.insert(sensorSend, i)
		end		
	end
end)

tmr.create():alarm(200, tmr.ALARM_AUTO, function(t)
	if sensorSend[1] then
		t:stop()
		local sensor = sensors[sensorSend[1]]
		http.put(smartthings.apiUrl.."\/device\/"..wifi.sta.getmac():gsub("%:", "").."\/"..sensor.pin.."\/"..gpio.read(sensor.pin), "Authorization: Bearer "..smartthings.token.."\r\n", "", function(stat, b, h) 
			table.remove(sensorSend, 1)
			t:start()
		end)
	end
end)

tmr.create():alarm(5000, tmr.ALARM_AUTO, function()
  print("Memory: " .. node.heap())
end)
