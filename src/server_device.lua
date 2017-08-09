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
        gpio.write(request.body.pin, request.body.state)
        blinktimer:start()
        response.send("")
      end
    end
  end
}
return me