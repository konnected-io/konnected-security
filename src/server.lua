local device = require("device")

print("Heap: ", node.heap(), "UPnP: ", "Listening for UPnP discovery")
net.multicastJoin(wifi.sta.getip(), "239.255.255.250")
local upnp = net.createUDPSocket()
upnp:listen(1900, "0.0.0.0")
upnp:on("receive", function(c, d, port, ip)
  require("ssdp_response")(c, d, port, ip)
end)

print("Heap: ", node.heap(), "HTTP: ", "Starting server at http://" .. wifi.sta.getip() .. ":" .. device.http_port)
local http = net.createServer(net.TCP, 10)
http:listen(device.http_port, function(conn)
  conn:on("receive", function(c, payload)
    require("server_receiver")(c, payload)
  end)
end)

