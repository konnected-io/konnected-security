require("httpd")
print("Heap: ", node.heap(), "Loaded: ", "httpd")
require("ssdp")
print("Heap: ", node.heap(), "Loaded: ", "ssdp")

httpd_set("/", function(request, response)
  response:file("http_index.html")
end)

--httpd_set("/favicon.ico", function(request, response)
--  response:contentType("image/x-icon")
--  response:file("http_favicon.ico")
--end)

httpd_set("/settings", function(request, response)
  print("Heap: ", node.heap(), "HTTP: ", "Settings")
  if request.method == "GET" then
    if request.query then
      request.query.update = request.query.update or "false"
      request.query.force = request.query.force or "false"
      request.query.setfactory = request.query.setfactory or "false"
      request.query.restart = request.query.restart or "false"
    end
    if request.query.restart == "true" then
      local _ = tmr.create():alarm(5000, tmr.ALARM_SINGLE, function() node.restart() end)
    end
    if request.query.update == "true" then 
      require("variables_set").set("update_init", "{ force = "..request.query.force..", setfactory = "..request.query.setfactory.." }")
      local _ = tmr.create():alarm(5000, tmr.ALARM_SINGLE, function() node.restart() end)
    end  
    response:send("")
  end
  if request.contentType == "application/json" then
    if request.method == "PUT" then
      
      require("variables_set").set("smartthings", table.concat({ "{ token = \"", request.body.token, "\",\r\n apiUrl = \"", request.body.apiUrl, "\" }" }))
      require("variables_set").set("sensors",   require("variables_build").build(request.body.sensors))
      require("variables_set").set("actuators", require("variables_build").build(request.body.actuators))

      print('Settings updated! Restarting in 2 seconds...')
      local _ = tmr.create():alarm(2000, tmr.ALARM_SINGLE, function() node.restart() end)

      response:contentType("application/json")
      response:status("204")
      response:send("")
    end
  end
end)

httpd_set("/device", function(request, response)
  print("Heap: ", node.heap(), "HTTP: ", "Device")
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
  print("Heap: ", node.heap(), "HTTP: ", "Status")
  local body = {
    hwVersion = require("device").name .. " \/ " .. require("device").hwVersion,
    swVersion = require("device").swVersion,
    heap = node.heap(),
    ip = wifi.sta.getip(),
    mac = wifi.sta.getmac(),
    uptime = tmr.time()
  }
  response:contentType("application/json")
  response:send(cjson.encode(body))
end)
