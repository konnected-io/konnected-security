local function turnOffIn(pin, on_state, delay, times, pause)
  local off = on_state == 0 and 1 or 0
  times = times or 1
  print("Heap:", node.heap(), "Actuator Pin:", pin, "Momentary:", delay, "Repeat:", times, "Pause:", pause)

  tmr.create():alarm(delay, tmr.ALARM_SINGLE, function()
    print("Heap:", node.heap(), "Actuator Pin:", pin, "State:", off)
    gpio.write(pin, off)
    times = times - 1

    if times > 0 then
      tmr.create():alarm(pause, tmr.ALARM_SINGLE, function()
        print("Heap:", node.heap(), "Actuator Pin:", pin, "State:", on_state)
        gpio.write(pin, on_state)
        turnOffIn(pin, on_state, delay, times, pause)
      end)
    end
  end)
end

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
          turnOffIn(request.body.pin, request.body.state, request.body.momentary, request.body.times, request.body.pause)
          local off = on_state == 0 and 1 or 0
          response.send(cjson.encode({ pin = request.body.pin, state = off }))
        else
          local json = cjson.encode({ pin = request.body.pin, state = request.body.state })
          print(json)
          response.send(json)
        end
        blinktimer:start()
      end
    end
  end
}
return me