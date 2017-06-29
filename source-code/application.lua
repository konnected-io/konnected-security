local sensors = require("sensors")
local actuators = require("actuators")
local smartthings = require("smartthings")
local sensorSend = {}
local dni = wifi.sta.getmac():gsub("%:", "")
local timeout = tmr.create()
local sensorTimer = tmr.create()
local sendTimer = tmr.create()
timeout:register(10000, tmr.ALARM_SEMI, node.restart)

for i, sensor in pairs(sensors) do
  print('Initializing sensor on pin ' .. sensor.pin)
  gpio.mode(sensor.pin, gpio.INPUT, gpio.PULLUP)
end

for i, actuator in pairs(actuators) do
  print('Initializing actuator on pin ' .. actuator.pin)
  gpio.mode(actuator.pin, gpio.OUTPUT)
  gpio.write(actuator.pin, gpio.LOW)
end

sensorTimer:alarm(200, tmr.ALARM_AUTO, function(t)
  for i, sensor in pairs(sensors) do
    if sensor.state ~= gpio.read(sensor.pin) then
      sensor.state = gpio.read(sensor.pin)
      table.insert(sensorSend, i)
    end
  end
end)

sendTimer:alarm(200, tmr.ALARM_AUTO, function(t)
  if sensorSend[1] then
    t:stop()
    local sensor = sensors[sensorSend[1]]
    timeout:start()
    http.put(
      table.concat({ smartthings.apiUrl, "\/device\/", dni, "\/", sensor.pin, "\/", gpio.read(sensor.pin) }),
      table.concat({ "Authorization: Bearer ", smartthings.token, "\r\n" }),
      "",
      function(code)
        timeout:stop()
        print("Heap:", node.heap(), "Success:", code)
        table.remove(sensorSend, 1)
        blinktimer:start()
        t:start()
      end)
    collectgarbage()
  end
end)

