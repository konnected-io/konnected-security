local deviceXML = require("ssdp")
print("Heap: ", node.heap(), "Loaded: ", "ssdp")

local srv = net.createServer(net.TCP, 10)
local port = math.floor(node.chipid()/1000) + 8000
srv:listen(port, function(conn) 
  conn:on("receive", function( sck, data )
    local request =  require("httpd_req").new(data)
    local response = require("httpd_res").new(sck)
    
    if request.path == "/" then
      response.file("http_index.html")
    end
    
    if request.path == "/favicon.ico" then
      response.contentType("image/x-icon")
      response.file("http_favicon.ico")
    end
    
    if request.path == "/Device.xml" then
      response.send(deviceXML, "text/xml")
    end
    
    if request.path == "/settings" then
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
        response.send("")
      end
      if request.contentType == "application/json" then
        if request.method == "PUT" then
          local var = require("variables_set")
          var.set("smartthings", table.concat({ "{ token = \"", request.body.token, "\",\r\n apiUrl = \"", request.body.apiUrl, "\" }" }))
          var.set("sensors",   require("variables_build").build(request.body.sensors))
          var.set("actuators", require("variables_build").build(request.body.actuators))

          print('Settings updated! Restarting in 5 seconds...')
          require("restart")
          
          response.send("")
        end
      end
    end
    
    if request.path == "/device" then
      print("Heap: ", node.heap(), "HTTP: ", "Device")
      if request.contentType == "application/json" then
        if request.method == "GET" then
          local body = {
            pin = request.body.pin,
            state = gpio.read(request.body.pin)
          }
          response.send(cjson.encode(body))
        end
        if request.method == "PUT" then
          gpio.write(request.body.pin, request.body.state)
          blinktimer:start()
          response.send("")
        end
      end
    end
    
    if request.path == "/status" then
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
      response.send(cjson.encode(body))
    end
  end)
end)

