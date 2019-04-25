-- reset settings by holding the FLASH button (D3) for 8 seconds
gpio.mode(3, gpio.INT)

local wipeTmr = tmr.create()
wipeTmr:register(8000, tmr.ALARM_SEMI, function()
  gpio.write(4, gpio.LOW)
  tmr.create():alarm(3000, tmr.ALARM_SINGLE, function()
    local setVar = require("variables_set")
    setVar("settings", require("variables_build")({}))
    setVar("sensors",   require("variables_build")({}))
    setVar("actuators", require("variables_build")({}))
    setVar("dht_sensors", require("variables_build")({}))
    setVar("ds18b20_sensors", require("variables_build")({}))

    print("Heap:", node.heap(), 'Settings updated! Restarting now')
    node.restart()
  end)
end)

local function pressed(level)
  if level == gpio.LOW then
    print("Heap:", node.heap(), "FLASH button pressed")
    wipeTmr:start()
  else
    print("Heap:", node.heap(), "FLASH button released")
    wipeTmr:stop()
  end
end

gpio.trig(3, "both", pressed)
