local module = ...

local function ssdpResponse(c, d, port, ip)
  local device = require("device")
  if string.match(d, "M-SEARCH") then
    local urn = d:match("ST: (urn:[%w%p]*)")
    if (urn == device.urn or string.match(d, "ST: ssdp:all")) then
      local resp =
      "HTTP/1.1 200 OK\r\n" ..
        "CACHE-CONTROL: max-age=1800\r\n" ..
        "ST: " .. device.urn .. "\r\n" ..
        "USN: " .. device.id .. "::" .. device.urn .. "\r\n" .. "EXT:\r\n" ..
        "SERVER: NodeMCU/" .. string.format("%d.%d.%d", node.info()) .. " UPnP/1.1 " .. device.name .. "/" .. device.swVersion .. "\r\n" ..
        "LOCATION: http://" .. wifi.sta.getip() .. ":" .. device.http_port .. "/Device.xml\r\n\r\n"
      c:send(port, ip, resp)
      resp = nil
      print("Heap: ", node.heap(), "Responded to UPnP Discovery request from " .. ip .. ":" .. port)
    end
  end
end

return function(c, d, port, ip)
  package.loaded[module] = nil
  module = nil
  return ssdpResponse(c, d, port, ip)
end