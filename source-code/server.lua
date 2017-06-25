require("httpd")
print("Heap: ", node.heap(), "Loaded: ", "httpd")
require("ssdp")
print("Heap: ", node.heap(), "Loaded: ", "ssdp")

httpd_set("/", function(request, response)
  response:file("http_index.html")
end)

httpd_set("/favicon.ico", function(request, response)
  response:contentType("image/x-icon")
  response:file("http_favicon.ico")
end)

httpd_set("/settings", function(request, response)
  local function buildValue(objects)
    local out = {}
    table.insert(out, "{ ")
    for i, object in pairs(objects) do
       table.insert(out, "\r\n{ pin = ")
       table.insert(out, object.pin)
       table.insert(out, " }")
      if i < #objects then
        table.insert(out, ",")
      end
    end
    table.insert(out, " }")
    return table.concat(out)
  end

  if request.contentType == "application/json" then
    if request.method == "PUT" then
      local function variables_set(name, value)
        local fnc = string.match(name, ".*%.")
        local fn = "var_" .. name .. '.lua'
        local f = file.open(fn, "w")
        f.writeline(name .. " = " .. value)
        f.close()
        node.compile(fn)
        file.remove(fn)
        print("Heap: ", node.heap(), "Wrote: ", fn)
        collectgarbage()
      end
      variables_set("smartthings", table.concat({ "{ token = \"", request.body.token, "\",\r\n apiUrl = \"", request.body.apiUrl, "\" }" }))
      variables_set("sensors", buildValue(request.body.sensors))
      variables_set("actuators", buildValue(request.body.actuators))

      print('Settings updated! Restarting in 2 seconds...')
      tmr.create():alarm(2000, tmr.ALARM_SINGLE, node.restart)

      response:contentType("application/json")
      response:status("204")
      response:send("")
    end
  end
end)

httpd_set("/device", function(request, response)
  if request.contentType == "application/json" then
    if request.method == "GET" then
      local body = {
        pin = request.body.pin,
        state = gpio.read(request.body.pin)
      }
      response:contentType("application/json")
      response:send(cjson.encode(body))
    end
    if request.method == "PUT" then
      gpio.write(request.body.pin, request.body.state)
      blinktimer:start()
      response:contentType("application/json")
      response:status("204")
      response:send("")
    end
  end
end)

httpd_set("/status", function(request, response)
  local body = {
    hwVersion = device.name .. " \/ " .. device.hwVersion,
    swVersion = device.swVersion,
    heap = node.heap(),
    ip = wifi.sta.getip(),
    mac = wifi.sta.getmac(),
    uptime = tmr.time()
  }
  response:contentType("application/json")
  response:send(cjson.encode(body))
end)

httpd_set("/restart", function(request, response)
  tmr.create():alarm(5000, tmr.ALARM_SINGLE, node.restart)
  response:contentType("application/json")
  response:status("204")
  response:send("")
end)