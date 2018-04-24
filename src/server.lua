local device = require("device")

print("Heap: ", node.heap(), "UPnP: ", "Listening for UPnP discovery")
net.multicastJoin(wifi.sta.getip(), "239.255.255.250")
local upnp = net.createUDPSocket()
upnp:listen(1900, "0.0.0.0")
upnp:on("receive", function(c, d, port, ip)
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
      c:send(port, ip, resp)
      print("Heap: ", node.heap(), "Responded to UPnP Discovery request from " .. ip .. ":" .. port)
      resp = nil
    end
  end
end)


print("Heap: ", node.heap(), "HTTP: ", "Starting server at http://" .. wifi.sta.getip() .. ":" .. device.http_port)
local http = net.createServer(net.TCP, 10)
http:listen(device.http_port, function(conn)
  conn:on("receive", require("server_receiver").receive)
end)

