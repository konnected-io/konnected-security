require("wipe")
local sensors = require("sensors")
local dht_sensors = require("dht_sensors")
local ds18b20_sensors = require("ds18b20_sensors")
local actuators = require("actuators")
local settings = require("settings")
local sensorTimer = tmr.create()

-- globals
sensorPut = {}
actuatorGet = {}

-- initialize binary sensors
for i, sensor in pairs(sensors) do
  print("Heap:", node.heap(), "Initializing sensor pin:", sensor.pin)
  gpio.mode(sensor.pin, gpio.INPUT, gpio.PULLUP)
end

-- initialize actuators
for i, actuator in pairs(actuators) do
  print("Heap:", node.heap(), "Initializing actuator pin:", actuator.pin)
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
    local pollInterval = tonumber(sensor.poll_interval) or 0
    pollInterval = (pollInterval > 0 and pollInterval or 3) * 60 * 1000
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
    local pollInterval = tonumber(sensor.poll_interval) or 0
    pollInterval = (pollInterval > 0 and pollInterval or 3) * 60 * 1000
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


-- Support different communication methods for reporting to upstream platforms
local endpoint_type = settings.endpoint_type or 'rest'

-- REST is the default communication method and is used by the original SmartThings, Hubitat, Home Assistant,
-- and OpenHab integrations.
if endpoint_type == 'rest' then
  require("rest_endpoint")(settings)

-- AWS IoT is used for the Konnected Cloud Connector or custom integrations build on AWS
elseif endpoint_type == 'aws_iot' then
  require("aws_iot")(settings)
end



