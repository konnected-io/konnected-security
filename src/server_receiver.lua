local function httpReceiver(sck, payload)
  print("Heap: ", node.heap(), "Receiving incoming request")

  local request =  require("httpd_req").new(payload)
  print("Heap: ", node.heap(), "Loaded httpd_req objects")
  local response = require("httpd_res")

  if request.path == "/" then
    print("Heap: ", node.heap(), "HTTP: ", "Index")
    response.file(sck, "http_index.html")
  end

  if request.path == "/favicon.ico" then
    response.file(sck, "http_favicon.ico", "image/x-icon")
  end

  if request.path == "/Device.xml" then
    response.text(sck, dofile("ssdp.lc"), "text/xml")
    print("Heap: ", node.heap(), "HTTP: ", "Discovery")
  end

  if request.path == "/settings" then
    print("Heap: ", node.heap(), "HTTP: ", "Settings")
    response.text(sck, require("server_settings").process(request))
  end

  if request.path == "/device" then
    print("Heap: ", node.heap(), "HTTP: ", "Device")
    response.text(sck, require("server_device").process(request))
  end

  if request.path == "/status" then
    print("Heap: ", node.heap(), "HTTP: ", "Status")
    response.text(sck, require("server_status").process())
    print("Heap: ", node.heap(), "HTTP: ", "Sent Status")
  end

  sck, request, response = nil
  collectgarbage()
end

local me = {
  receive = httpReceiver
}
return me