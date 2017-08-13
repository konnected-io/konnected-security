local me = {
	process = function (request, response) 
		if request.contentType == "application/json" then
      if request.method == "GET" then
        if request.query then
          request.query.pin = request.query.pin or "all"
        end
        local body = {}
        if request.query.pin == "all" then
          local sensors = require("sensors")
          for i, sensor in pairs(sensors) do
            table.insert(body, { pin = sensor.pin, state = sensor.state })
          end         
        else
          local body = { {
            pin = request.query.pin,
            state = gpio.read(request.query.pin)
          } }
        end
        response.send(cjson.encode(body))
      end
      if request.method == "PUT" then
        print("Heap:", node.heap(), "Actuator Pin:", request.body.pin, "State:", request.body.state)
        gpio.write(request.body.pin, request.body.state)
        if request.body.momentary then
          print("Heap:", node.heap(), "Actuator Pin:", request.body.pin, "Momentary:", request.body.momentary)
          tmr.create():alarm(request.body.momentary, tmr.ALARM_SINGLE, function()
            local off
            if request.body.state == 0 then off = 1 else off = 0 end
            print("Heap:", node.heap(), "Actuator Pin:", request.body.pin, "State:", off)
            gpio.write(request.body.pin, off)
          end)
        end
        blinktimer:start()
        response.send("")
      end
    end
  end
}
return me