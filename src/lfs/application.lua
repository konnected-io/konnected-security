require("wipe")
local log = require("log")
local sensors = require("sensors")
local dht_sensors = require("dht_sensors")
local ds18b20_sensors = require("ds18b20_sensors")
local actuators = require("actuators")
local settings = require("settings")
local ds18b20 = require("ds18b20")
local sensorTimer = tmr.create()

-- globals
sensorPut = {}
actuatorGet = {}

-- initialize binary sensors
for i, sensor in pairs(sensors) do
  log.info("Initializing sensor pin:", sensor.pin)
  gpio.mode(sensor.pin, gpio.INPUT, gpio.PULLUP)
end

-- initialize actuators
for i, actuator in pairs(actuators) do
  local initialState = actuator.trigger == gpio.LOW and gpio.HIGH or gpio.LOW
  log.info("Initializing actuator pin:", actuator.pin, "on:", actuator.trigger or gpio.HIGH, "off:", initialState)
  gpio.write(actuator.pin, initialState)
  gpio.mode(actuator.pin, gpio.OUTPUT)
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
      log.info("Temperature:", temperature_string, "Humidity:", humidity_string)
      table.insert(sensorPut, { pin = pin, temp = temperature_string, humi = humidity_string })
    else
      log.info("DHT Status:", status)
    end
  end

  for i, sensor in pairs(dht_sensors) do
    local pollInterval = tonumber(sensor.poll_interval) or 0
    pollInterval = (pollInterval > 0 and pollInterval or 3) * 60 * 1000
    log.info("Polling DHT on pin " .. sensor.pin .. " every " .. pollInterval .. "ms")
    tmr.create():alarm(pollInterval, tmr.ALARM_AUTO, function() readDht(sensor.pin) end)
    readDht(sensor.pin)
  end
end

-- initialize ds18b20 temp sensors
if #ds18b20_sensors > 0 then

  local function ds18b20Callback(pin)
    local callbackFn = function(temps)
      for addr,value in pairs(temps) do
        print("Heap:", node.heap(), "Temperature:", value)
        table.insert(sensorPut, { pin = pin, temp = value,
          addr = string.format(('%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X'):format(addr:byte(1,8)))})
      end
    end
    return callbackFn
  end

  for i, sensor in pairs(ds18b20_sensors) do
    local pollInterval = tonumber(sensor.poll_interval) or 0
    pollInterval = (pollInterval > 0 and pollInterval or 3) * 60 * 1000
    log.info("Polling DS18b20 on pin " .. sensor.pin .. " every " .. pollInterval .. "ms")
    local callbackFn = ds18b20Callback(sensor.pin)
    tmr.create():alarm(pollInterval, tmr.ALARM_AUTO, function() ds18b20:read_temp(callbackFn, sensor.pin, ds18b20.C) end)
    ds18b20:read_temp(callbackFn, sensor.pin, ds18b20.C)
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
  require("aws_iot")()
end



