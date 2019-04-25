local module = ...

local function ssdpNotify(nt, usn)
  local device = require("device")
  return table.concat({
    "NOTIFY * HTTP/1.1\r\n",
    "CACHE-CONTROL: max-age=1800\r\n",
    "NT: ", nt, "\r\n",
    "USN: ", device.id, usn, "\r\n",
    "NTS: ssdp:alive\r\n",
    "SERVER: NodeMCU/", string.format("%d.%d.%d", node.info()), " UPnP/1.1 ", device.name, "/", device.swVersion, "\r\n",
    "LOCATION: http://", wifi.sta.getip(), ":", device.http_port, "/Device.xml\r\n",
    "BOOTID.UPNP.ORG: 1\r\n",
    "CONFIGID.UPNP.ORG: ", device.http_port, "\r\n\r\n"
  })
end

return function(nt, usn)
  package.loaded[module] = nil
  module = nil
  return ssdpNotify(nt, usn)
end