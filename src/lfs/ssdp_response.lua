local module = ...

local log = require("log")

local function ssdpResponse(c, d, port, ip)
  if string.match(d, "M-SEARCH") then
    local device = require("device")
    local urn = d:match("ST: (urn:[%w%p]*)")
    if (urn == device.urn or string.match(d, "ST: ssdp:all")) then
      log.info("Resp to UPnP Disc request from " .. ip .. ":" .. port)
      local resp =
      "HTTP/1.1 200 OK\r\n" ..
        "CACHE-CONTROL: max-age=1800\r\n" ..
        "ST: " .. device.urn .. "\r\n" ..
        "USN: " .. device.id .. "::" .. device.urn .. "\r\n" .. "EXT:\r\n" ..
        "SERVER: NodeMCU/" .. string.format("%d.%d.%d", node.info()) .. " UPnP/1.1 " .. device.name .. "/" .. device.swVersion .. "\r\n" ..
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