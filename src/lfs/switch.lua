local module = ...

local log = require("log")

infiniteLoops = {}

local function turnOffIn(pin, on_state, delay, times, pause)
  local off = on_state == 0 and 1 or 0
  times = times or -1

  if (times == -1) then
    infiniteLoops[pin] = true
  end

  log.info("Act Pin:", pin, "Mom:", delay, "Repeat:", times, "Pause:", pause)

  tmr.create():alarm(delay, tmr.ALARM_SINGLE, function()
    log.info("Act Pin:", pin, "State:", off)
    gpio.write(pin, off)
    times = times - 1

    if (times > 0 or infiniteLoops[pin]) and pause then
      tmr.create():alarm(pause, tmr.ALARM_SINGLE, function()
        log.info("Act Pin:", pin, "State:", on_state)
        gpio.write(pin, on_state)
        turnOffIn(pin, on_state, delay, times, pause)
      end)
    end
  end)
end

local function updatePin(payload)
  local pin = tonumber(payload.pin)
  local state = tonumber(payload.state)
  local times = tonumber(payload.times)
  log.info("Act Pin:", pin, "State:", state)

  if infiniteLoops[pin] then
    infiniteLoops[pin] = false
  end

  gpio.write(pin, state)

  blinktimer:start()
  if payload.momentary then
    turnOffIn(pin, state, payload.momentary, times, payload.pause)
    if (times == -1) then state = -1 end -- this indicates an infinite repeat
    return { pin = pin, state = state }
  else
    return { pin = pin, state = state }
  end
end


return function(payload)
  package.loaded[module] = nil
  module = nil
  return updatePin(payload)
end