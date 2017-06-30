local deviceXML = require("ssdp")


local srv = net.createServer(net.TCP, 10)
local port = math.floor(node.chipid()/1000) + 8000
print("Heap: ", node.heap(), "HTTP: ", "Starting server at http://" .. wifi.sta.getip() .. ":" .. port)
srv:listen(port, function(conn) 
  conn:on("receive", function( sck, data )
    local request =  require("httpd_req").new(data)
    local response = require("httpd_res").new(sck)
    
    if request.path == "/" then
      response.file("http_index.html")
    end
    
    if request.path == "/favicon.ico" then
      response.file("http_favicon.ico", "image/x-icon")
    end
    
    if request.path == "/Device.xml" then
      response.send(deviceXML, "text/xml")
    end
    
    if request.path == "/settings" then
      print("Heap: ", node.heap(), "HTTP: ", "Settings")
      require("server_settings").process(request,response)
    end
    
    if request.path == "/device" then
      print("Heap: ", node.heap(), "HTTP: ", "Device")
      require("server_device").process(request,response)
    end
    
    if request.path == "/status" then
      print("Heap: ", node.heap(), "HTTP: ", "Status")
      require("server_status").process(request,response)
    end
  end)
end)

