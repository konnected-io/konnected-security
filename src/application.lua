local sensors = require("sensors")
local dht_sensors = require("dht_sensors")
local actuators = require("actuators")
local smartthings = require("smartthings")
local sensorSend = {}
local dni = wifi.sta.getmac():gsub("%:", "")
local timeout = tmr.create()
local sensorTimer = tmr.create()
local sendTimer = tmr.create()

-- hack to ensure pin D8 stays low after boot so it can be used with a high-level trigger relay
gpio.mode(8, gpio.OUTPUT)
gpio.write(8, gpio.LOW)

timeout:register(10000, tmr.ALARM_SEMI, node.restart)

for i, sensor in pairs(sensors) do
  print("Heap:", node.heap(), "Initializing sensor pin:", sensor.pin)
  gpio.mode(sensor.pin, gpio.INPUT, gpio.PULLUP)
end

for i, actuator in pairs(actuators) do
  print("Heap:", node.heap(), "Initializing actuator pin:", actuator.pin, "Trigger:", actuator.trigger)
  gpio.mode(actuator.pin, gpio.OUTPUT)
  gpio.write(actuator.pin, actuator.trigger == gpio.LOW and gpio.HIGH or gpio.LOW)
end

if #dht_sensors > 0 then
  require("dht")
  local temperatureTimer = tmr.create()
  local function readDht()
    for i, sensor in pairs(dht_sensors) do
      local status, temp, humi, temp_dec, humi_dec = dht.read(sensor.pin)
      if status == dht.OK then
        local temperature_string = temp .. "," .. temp_dec
        local humidity_string = humi .. "," .. humi_dec
        print("Heap:", node.heap(), "Temperature:", temperature_string, "Humidity:", humidity_string)
        table.insert(sensorSend, { pin = sensor.pin, val = temperature_string .. "_" .. humidity_string })
      end
    end
  end

  temperatureTimer:alarm(180000, tmr.ALARM_AUTO, readDht)
  readDht()
end

sensorTimer:alarm(200, tmr.ALARM_AUTO, function(t)
  for i, sensor in pairs(sensors) do
    if sensor.state ~= gpio.read(sensor.pin) then
      sensor.state = gpio.read(sensor.pin)
      table.insert(sensorSend, {pin = sensor.pin, val = sensor.state})
    end
  end
end)

sendTimer:alarm(200, tmr.ALARM_AUTO, function(t)
  if sensorSend[1] then
    t:stop()
    local sensor = sensorSend[1]
    timeout:start()
    http.put(
      table.concat({ smartthings.apiUrl, "/device/", dni, "/", sensor.pin, "/", sensor.val }),
      table.concat({ "Authorization: Bearer ", smartthings.token, "\r\n" }),
      "",
      function(code)
        timeout:stop()
        print("Heap:", node.heap(), "HTTP Call:", code, "Pin:", sensor.pin, "State:", sensor.val)
        table.remove(sensorSend, 1)
        blinktimer:start()
        t:start()
      end)
    collectgarbage()
  end
end)
