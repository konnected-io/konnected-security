require("httpd")
require("ssdp")
httpd_set("/", function(request, response) 
    response:file("http_index.html")
end)
httpd_set("/favicon.ico", function(request, response) 
    response:contentType("image/x-icon")
    response:file("http_favicon.ico")
end)
httpd_set("/settings", function(request, response) 
	if request.contentType == "application/json" then
		if request.method == "PUT" then
			local sensors = "{ "
			for i,sensor in pairs(request.body.sensors) do
				if i == #request.body.sensors then 
					sensors = sensors.."\r\n{ pin = "..sensor.pin.." }"
				else
					sensors = sensors.."\r\n{ pin = "..sensor.pin.." },"
				end
				gpio.mode(sensor.pin, gpio.INPUT, gpio.PULLUP)
			end
			sensors = sensors.." }"
			variables_set("smartthings", "{ token = \"" .. request.body.token .. "\",\r\n apiUrl = \""..request.body.apiUrl.."\" }")
			variables_set("sensors", sensors)
			require("application")
			response:contentType("application/json")
			response:status("204")
			response:send("")
		end            
	end
end)
httpd_set("/device", function(request, response) 
	if request.contentType == "application/json" then
		if request.method == "GET" then
			local body = {
				pin = request.body.pin,
				state = gpio.read(request.body.pin)
			}
			response:contentType("application/json")
			response:send(cjson.encode(body))
		end
		if request.method == "PUT" then
			gpio.mode(request.body.pin, gpio.OUTPUT)
			gpio.write(request.body.pin, request.body.state)
			response:contentType("application/json")
			response:status("204")
			response:send("")
		end  
	end
end)
httpd_set("/status", function(request, response)     
	local body = {
		hwVersion = device.name.." \/ "..device.hwVersion,
		swVersion = device.swVersion,
		heap = node.heap(),
		ip = wifi.sta.getip(),
		mac = wifi.sta.getmac(),
		uptime = tmr.time()		
	}
    response:contentType("application/json")
    response:send(cjson.encode(body))
end)
httpd_set("/restart", function(request, response)     
	tmr.create():alarm(10000, tmr.ALARM_AUTO, function(t) 
		node.restart()
	end)
    response:contentType("application/json")
	response:status("204")
    response:send("")
end)