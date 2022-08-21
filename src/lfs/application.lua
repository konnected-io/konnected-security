require("wipe")
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
function zoneToPin(zone)
  -- handle strings or numbers
  --return zoneMap[zone] or zoneMap[tonumber(zone)]
  if zone == 1 or zone == '1' then return 1 end
  if zone == 2 or zone == '2' then return 2 end
  if zone == 3 or zone == '3' then return 5 end
  if zone == 4 or zone == '4' then return 6 end
  if zone == 5 or zone == '5' then return 7 end
  if zone == 6 or zone == '6' then return 9 end
  if zone == "out" then return 8 end
end

local function getDevicePin(device)
  if device.zone ~= nil then
    return zoneToPin(device.zone)
  else
    return device.pin
  end
end

-- initialize binary sensors
for i, sensor in pairs(sensors) do
  local pin = getDevicePin(sensor)
  if sensor.zone ~= nil then
    print("Heap:", node.heap(), "Initializing sensor zone:", sensor.zone)
  else
    print("Heap:", node.heap(), "Initializing sensor pin:", pin)
  end

  gpio.mode(pin, gpio.INPUT, gpio.PULLUP)
end

-- initialize actuators
for i, actuator in pairs(actuators) do
  local pin = getDevicePin(actuator)
  local initialState = actuator.trigger == gpio.LOW and gpio.HIGH or gpio.LOW
  if actuator.zone ~= nil then
    print("Heap:", node.heap(), "Initializing actuator zone:", actuator.zone, "on:", actuator.trigger or gpio.HIGH, "off:", initialState)
  else
    print("Heap:", node.heap(), "Initializing actuator pin:", pin, "on:", actuator.trigger or gpio.HIGH, "off:", initialState)
  end

  gpio.write(pin, initialState)
  gpio.mode(pin, gpio.OUTPUT)
  table.insert(actuatorGet, actuator)
end

-- initialize DHT sensors
if #dht_sensors > 0 then
  require("dht")

  local function readDht(sensor)
    local status, temp, humi, temp_dec, humi_dec = dht.read(getDevicePin(sensor))
    if status == dht.OK then
      local temperature_string = temp .. "." .. math.abs(temp_dec)
      local humidity_string = humi .. "." .. humi_dec
      print("Heap:", node.heap(), "Temperature:", temperature_string, "Humidity:", humidity_string)
      if sensor.zone ~= nil then
        table.insert(sensorPut, { zone = sensor.zone, temp = temperature_string, humi = humidity_string })
      else
        table.insert(sensorPut, { pin = sensor.pin, temp = temperature_string, humi = humidity_string })
      end
    else
      print("Heap:", node.heap(), "DHT Status:", status)
    end
  end

  for i, sensor in pairs(dht_sensors) do
    local pollInterval = tonumber(sensor.poll_interval) or 0
    pollInterval = (pollInterval > 0 and pollInterval or 3) * 60 * 1000
    if sensor.zone ~= nil then
      print("Heap:", node.heap(), "Polling DHT on zone " .. sensor.zone .. " every " .. pollInterval .. "ms")
    else
      print("Heap:", node.heap(), "Polling DHT on pin " .. sensor.pin .. " every " .. pollInterval .. "ms")
    end
    tmr.create():alarm(pollInterval, tmr.ALARM_AUTO, function() readDht(sensor) end)
    readDht(sensor)
  end
end

-- initialize ds18b20 temp sensors
if #ds18b20_sensors > 0 then

  local function ds18b20Callback(sensor)
    local callbackFn = function(temps)
      for addr,value in pairs(temps) do
        print("Heap:", node.heap(), "Temperature:", value)
        local addrStr = string.format(('%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X'):format(addr:byte(1,8)))
        if sensor.zone ~= nil then
          table.insert(sensorPut, { zone = sensor.zone, temp = value, addr = addrStr })
        else
          table.insert(sensorPut, { pin = sensor.pin, temp = value, addr = addrStr })
        end
      end
    end
    return callbackFn
  end

  for i, sensor in pairs(ds18b20_sensors) do
    local pin = getDevicePin(sensor)
    local pollInterval = tonumber(sensor.poll_interval) or 0
    pollInterval = (pollInterval > 0 and pollInterval or 3) * 60 * 1000
    if sensor.zone ~= nil then
      print("Heap:", node.heap(), "Polling DS18b20 on zone " .. sensor.zone .. " every " .. pollInterval .. "ms")
    else
      print("Heap:", node.heap(), "Polling DS18b20 on pin " .. pin .. " every " .. pollInterval .. "ms")
    end

    local callbackFn = ds18b20Callback(sensor)
    tmr.create():alarm(pollInterval, tmr.ALARM_AUTO, function() ds18b20:read_temp(callbackFn, pin, ds18b20.C) end)
    ds18b20:read_temp(callbackFn, pin, ds18b20.C)
  end
end

-- Poll every configured binary sensor and insert into the request queue when changed
sensorTimer:alarm(200, tmr.ALARM_AUTO, function(t)
  for i, sensor in pairs(sensors) do
    if sensor.state ~= gpio.read(getDevicePin(sensor)) then
      sensor.state = gpio.read(getDevicePin(sensor))
      if sensor.zone ~= nil then
        table.insert(sensorPut, { zone = sensor.zone, state = sensor.state })
      else
        table.insert(sensorPut, { pin = sensor.pin, state = sensor.state })
      end
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



