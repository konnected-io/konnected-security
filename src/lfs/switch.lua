local module = ...

infiniteLoops = {}

local function turnOffIn(zone, pin, on_state, delay, times, pause)
  local off = on_state == 0 and 1 or 0
  times = times or -1

  if (times == -1) then
    infiniteLoops[pin] = true
  end

  local typeStr = "Actuator Pin:"
  local pinZone = pin
  if zone ~= nil then
    typeStr = "Actuator Zone:"
    pinZone = zone
  end

  print("Heap:", node.heap(), typeStr, pinZone, "Momentary:", delay, "Repeat:", times, "Pause:", pause)

  tmr.create():alarm(delay, tmr.ALARM_SINGLE, function()
    print("Heap:", node.heap(), typeStr, pinZone, "State:", off)
    gpio.write(pin, off)
    times = times - 1

    if (times > 0 or infiniteLoops[pin]) and pause then
      tmr.create():alarm(pause, tmr.ALARM_SINGLE, function()
        print("Heap:", node.heap(), typeStr, pinZone, "State:", on_state)
        gpio.write(pin, on_state)
        turnOffIn(zone, pin, on_state, delay, times, pause)
      end)
    end
  end)
end

local function updatePin(payload)
  local zone = payload.zone
  local pin = tonumber(payload.pin)
  local state = tonumber(payload.state)
  local times = tonumber(payload.times)

  if zone ~= nil then
    print("Heap:", node.heap(), "Actuator Zone:", zone, "State:", state)
    pin = zoneToPin(zone)
  else
    print("Heap:", node.heap(), "Actuator Pin:", pin, "State:", state)
  end

  if infiniteLoops[pin] then
    infiniteLoops[pin] = false
  end

  gpio.write(pin, state)

  blinktimer:start()
  if payload.momentary then
    turnOffIn(zone, pin, state, payload.momentary, times, payload.pause)
    if (times == -1) then state = -1 end -- this indicates an infinite repeat
  end

  if zone ~= nil then
    return { zone = zone, state = state }
  else
    return { pin = pin, state = state }
  end
end


return function(payload)
  package.loaded[module] = nil
  module = nil
  return updatePin(payload)
end