local module = ...

local function ssdpResponse(c, d, port, ip)
  if string.match(d, "M-SEARCH") then
    local device = require("device")
    local info = node.info("sw_version")
    local urn = d:match("ST: (urn:[%w%p]*)")
    if (string.match(d, "ST:%s*ssdp:all") or (urn and device.urn:sub(1, #urn) == urn)) then
      print("Heap: ", node.heap(), "Responding to UPnP Discovery request from " .. ip .. ":" .. port)
      local resp =
      "HTTP/1.1 200 OK\r\n" ..
        "CACHE-CONTROL: max-age=1800\r\n" ..
        "ST: " .. device.urn .. "\r\n" ..
        "USN: " .. device.id .. "::" .. device.urn .. "\r\n" .. "EXT:\r\n" ..
        "SERVER: NodeMCU/" .. string.format("%d.%d.%d", info.node_version_major, info.node_version_minor, info.node_version_revision) .. " UPnP/1.1 " .. device.name .. "/" .. device.swVersion .. "\r\n" ..
        "LOCATION: http://" .. wifi.sta.getip() .. ":" .. device.http_port .. "/Device.xml\r\n\r\n"
      c:send(port, ip, resp)
      resp = nil
    end
  end
end

return function(c, d, port, ip)
  package.loaded[module] = nil
  module = nil
  return ssdpResponse(c, d, port, ip)
end