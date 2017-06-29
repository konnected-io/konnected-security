require("httpd")
print("Heap: ", node.heap(), "Loaded: ", "httpd")
local deviceXML = require("ssdp")
print("Heap: ", node.heap(), "Loaded: ", "ssdp")

httpd_set("/", function(request, response)
  response:file("http_index.html")
end)

--httpd_set("/favicon.ico", function(request, response)
--  response:contentType("image/x-icon")
--  response:file("http_favicon.ico")
--end)

httpd_set("/Device.xml", function(request, response)
  response:contentType("text/xml")
  response:send(deviceXML)
end)

httpd_set("/settings", function(request, response)
  print("Heap: ", node.heap(), "HTTP: ", "Settings")
  if request.method == "GET" then
    if request.query then
      request.query.update = request.query.update or "false"
      request.query.force = request.query.force or "false"
      request.query.setfactory = request.query.setfactory or "false"
      request.query.restart = request.query.restart or "false"
    end
    if request.query.update == "true" then 
      require("variables_set").set("update_init", "{ force = "..request.query.force..", setfactory = "..request.query.setfactory.." }")
      require("restart")
    end  
    if request.query.restart == "true" then
      require("restart")
    end
    response:send("")
  end
  if request.contentType == "application/json" then
    if request.method == "PUT" then
      local var = require("variables_set")
      var.set("smartthings", table.concat({ "{ token = \"", request.body.token, "\",\r\n apiUrl = \"", request.body.apiUrl, "\" }" }))
      var.set("sensors",   require("variables_build").build(request.body.sensors))
      var.set("actuators", require("variables_build").build(request.body.actuators))

      print('Settings updated! Restarting in 5 seconds...')
      require("restart")
      
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
      response:send(cjson.encode(body))
    end
    if request.method == "PUT" then
      gpio.write(request.body.pin, request.body.state)
      blinktimer:start()
      response:send("")
    end
  end
end)

httpd_set("/status", function(request, response)
  print("Heap: ", node.heap(), "HTTP: ", "Status")
  local device = require("device")
  local body = {
    hwVersion = device.name .. " \/ " .. device.hwVersion,
    swVersion = device.swVersion,
    heap = node.heap(),
    ip = wifi.sta.getip(),
    mac = wifi.sta.getmac(),
    uptime = tmr.time()
  }
  response:send(cjson.encode(body))
end)
