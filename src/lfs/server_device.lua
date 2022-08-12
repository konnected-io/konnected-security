local module = ...

local function process(request)
  if request.method == "GET" then
    if request.query then
      request.query.pin = request.query.pin or "all"
      request.query.zone = request.query.zone or "all"
    end
    local body = {}
    if request.query.pin == "all" or request.query.zone == "all" then
      local sensors = require("sensors")
      for i, sensor in pairs(sensors) do
        if sensor.pin ~= nil then
          table.insert(body, { pin = sensor.pin, state = sensor.state })
        else
          table.insert(body, { zone = sensor.zone, state = sensor.state })
        end
      end
    elseif request.query.pin then
      body = { {
        pin = request.query.pin,
        state = gpio.read(request.query.pin)
      } }
    else
      body = { {
        zone = request.query.zone,
        state = gpio.read(require("zone_to_pin")(request.query.zone))
      } }
    end
    return sjson.encode(body)
  end

  if request.contentType == "application/json" then
    if request.method == "PUT" then
      if request.body[1] then
        local ret = {}
        for i in pairs(request.body) do
          table.insert(ret, require("switch")(request.body[i]))
        end
        return sjson.encode(ret)
      else
        return sjson.encode(require("switch")(request.body))
      end
    end
  end
end

return function(request)
  package.loaded[module] = nil
  module = nil
  return process(request)
end