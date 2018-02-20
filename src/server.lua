local device = require("device")

print("Heap: ", node.heap(), "UPnP: ", "Listening for UPnP discovery")
net.multicastJoin(wifi.sta.getip(), "239.255.255.250")
local upnp = net.createServer(net.UDP)
upnp:listen(1900, "239.255.255.250")
upnp:on("receive", function(c, d)
  if string.match(d, "M-SEARCH") then
    local urn = d:match("ST: (urn:[%w%p]*)")
    if (urn == device.urn or string.match(d, "ST: ssdp:all")) then
      local resp =
      "HTTP/1.1 200 OK\r\n" ..
        "Cache-Control: max-age=120\r\n" ..
        "ST: " .. device.urn .. "\r\n" ..
        "USN: " .. device.id .. "::" .. device.urn .. "\r\n" .. "EXT:\r\n" ..
        "SERVER: NodeMCU/" .. string.format("%d.%d.%d", node.info()) .. " UPnP/1.1 " .. device.name .. "/" .. device.swVersion .. "\r\n" ..
        "LOCATION: http://" .. wifi.sta.getip() .. ":" .. device.http_port .. "/Device.xml\r\n\r\n"
      c:send(resp)
      print("Heap: ", node.heap(), "Responded to UPnP Discovery request")
      resp = nil
    end
  end
end)


print("Heap: ", node.heap(), "HTTP: ", "Starting server at http://" .. wifi.sta.getip() .. ":" .. device.http_port)
local http = net.createServer(net.TCP, 10)
http:listen(device.http_port, function(conn)
  conn:on("receive", function( sck, payload )

    -- Some clients send POST data in multiple chunks.
    -- Collect data packets until the size of HTTP body meets the Content-Length stated in header
    -- this snippet borrowed from https://github.com/marcoskirsch/nodemcu-httpserver/blob/master/httpserver.lua
    if payload:find("Content%-Length:") or bBodyMissing then
      if fullPayload then fullPayload = fullPayload .. payload else fullPayload = payload end
      if (tonumber(string.match(fullPayload, "%d+", fullPayload:find("Content%-Length:")+16)) > #fullPayload:sub(fullPayload:find("\r\n\r\n", 1, true)+4, #fullPayload)) then
        bBodyMissing = true
        return
      else
        payload = fullPayload
        fullPayload, bBodyMissing = nil
      end
    end
    collectgarbage()

    local request =  require("httpd_req").new(payload)
    local response = require("httpd_res").new(sck)
    
    if request.path == "/" then
      response.file("http_index.html")
    end
    
    if request.path == "/favicon.ico" then
      response.file("http_favicon.ico", "image/x-icon")
    end
    
    if request.path == "/Device.xml" then
      response.send(dofile("ssdp.lc"), "text/xml")
      print("Heap: ", node.heap(), "HTTP: ", "Discovery")
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

