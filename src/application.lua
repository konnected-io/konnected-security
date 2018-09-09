local sensors = require("sensors")
local dht_sensors = require("dht_sensors")
local ds18b20_sensors = require("ds18b20_sensors")
local actuators = require("actuators")
local settings = require("settings")
local sensorPut = {}
local actuatorGet = {}
local dni = wifi.sta.getmac():gsub("%:", "")
local timeout = tmr.create()
local sensorTimer = tmr.create()
local sendTimer = tmr.create()

timeout:register(10000, tmr.ALARM_SEMI, node.restart)

-- initialize binary sensors
for i, sensor in pairs(sensors) do
  print("Heap:", node.heap(), "Initializing sensor pin:", sensor.pin)
  gpio.mode(sensor.pin, gpio.INPUT, gpio.PULLUP)
end

-- initialize actuators
for i, actuator in pairs(actuators) do
  table.insert(actuatorGet, actuator)
end

-- initialize DHT sensors
if #dht_sensors > 0 then
  require("dht")

  local function readDht(pin)
    local status, temp, humi, temp_dec, humi_dec = dht.read(pin)
    if status == dht.OK then
      local temperature_string = temp .. "." .. math.abs(temp_dec)
      local humidity_string = humi .. "." .. humi_dec
      print("Heap:", node.heap(), "Temperature:", temperature_string, "Humidity:", humidity_string)
      table.insert(sensorPut, { pin = pin, temp = temperature_string, humi = humidity_string })
    else
      print("Heap:", node.heap(), "DHT Status:", status)
    end
  end

  for i, sensor in pairs(dht_sensors) do
    local pollInterval = (sensor.poll_interval > 0 and sensor.poll_interval or 3) * 60 * 1000
    print("Heap:", node.heap(), "Polling DHT on pin " .. sensor.pin .. " every " .. pollInterval .. "ms")
    tmr.create():alarm(pollInterval, tmr.ALARM_AUTO, function() readDht(sensor.pin) end)
    readDht(sensor.pin)
  end
end

-- initialize ds18b20 temp sensors
if #ds18b20_sensors > 0 then

  local function ds18b20Callback(pin)
    local callbackFn = function(i, rom, res, temp, temp_dec, par)
      local temperature_string = temp .. "." .. math.abs(temp_dec)
      print("Heap:", node.heap(), "Temperature:", temperature_string, "Resolution:", res)
      if (res >= 12) then
        table.insert(sensorPut, { pin = pin, temp = temperature_string,
          addr = string.format("%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X",
            string.match(rom, "(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)")) })
      end
    end
    return callbackFn
  end

  for i, sensor in pairs(ds18b20_sensors) do
    local pollInterval = (sensor.poll_interval > 0 and sensor.poll_interval or 3) * 60 * 1000
    print("Heap:", node.heap(), "Polling DS18b20 on pin " .. sensor.pin .. " every " .. pollInterval .. "ms")
    local callbackFn = ds18b20Callback(sensor.pin)
    ds18b20.setup(sensor.pin)
    ds18b20.setting({}, 12)
    tmr.create():alarm(pollInterval, tmr.ALARM_AUTO, function() ds18b20.read(callbackFn, {}) end)
    ds18b20.read(callbackFn, {})
  end
end

-- Poll every configured binary sensor and insert into the request queue when changed
sensorTimer:alarm(200, tmr.ALARM_AUTO, function(t)
  for i, sensor in pairs(sensors) do
    if sensor.state ~= gpio.read(sensor.pin) then
      sensor.state = gpio.read(sensor.pin)
      table.insert(sensorPut, { pin = sensor.pin, state = sensor.state })
    end
  end
end)

-- print HTTP status line
local printHttpResponse = function(code, data)
  print("printHttpResponse")
  local a = { "Heap:", node.heap(), "HTTP Call:", code }
  for k, v in pairs(data) do
    table.insert(a, k)
    table.insert(a, v)
  end
  print(unpack(a))
end

-- This loop makes the HTTP requests to the home automation service to get or update device state
sendTimer:alarm(200, tmr.ALARM_AUTO, function(t)

  -- gets state of actuators
  if actuatorGet[1] then
    t:stop()
    local actuator = actuatorGet[1]
    timeout:start()

    http.get(table.concat({ settings.apiUrl, "/device/", dni, '?pin=', actuator.pin }),
      table.concat({ "Authorization: Bearer ", settings.token, "\r\nAccept: application/json\r\n" }),
      function(code, response)
        timeout:stop()
        local pin, state
        if response then
          pin = tonumber(response:match('"pin":(%d)'))
          state = tonumber(response:match('"state":(%d)'))
        end
        printHttpResponse(code, {pin = pin, state = state})

        gpio.mode(actuator.pin, gpio.OUTPUT)
        if pin == actuator.pin and code >= 200 and code < 300 and state then
          gpio.write(actuator.pin, state)
        else
          state = actuator.trigger == gpio.LOW and gpio.HIGH or gpio.LOW
          gpio.write(actuator.pin, state)
        end
        print("Heap:", node.heap(), "Initialized actuator Pin:", actuator.pin, "Trigger:", actuator.trigger, "Initial state:", state)

        table.remove(actuatorGet, 1)
        blinktimer:start()
        t:start()
      end)

  -- update state of sensors when needed
  elseif sensorPut[1] then
    t:stop()
    local sensor = sensorPut[1]
    timeout:start()
    http.put(table.concat({ settings.apiUrl, "/device/", dni }),
      table.concat({ "Authorization: Bearer ", settings.token, "\r\nAccept: application/json\r\nContent-Type: application/json\r\n" }),
      sjson.encode(sensor),
      function(code)
        timeout:stop()
        printHttpResponse(code, sensor)

        -- check for success and retry if necessary
        if code >= 200 and code < 300 then
          table.remove(sensorPut, 1)
        else
          -- retry up to 10 times then reboot as a failsafe
          local retry = sensor.retry or 0
          if retry == 10 then node.restart() end
          sensor.retry = retry + 1
          sensorPut[1] = sensor
        end

        blinktimer:start()
        t:start()
      end)
  end

  collectgarbage()
end)

print("Heap:", node.heap(), "Endpoint:", settings.apiUrl)