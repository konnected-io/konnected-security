local sensorSend = { }

for i,sensor in pairs(sensors) do
	gpio.mode(sensor.pin, gpio.INPUT, gpio.PULLUP)
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
