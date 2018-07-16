local module = ...

local function discoveryXML()
  local device = require("device")
  local deviceXML = { "<?xml version=\"1.0\"?>\r\n", "<root xmlns=\"urn:schemas-upnp-org:device-1-0\" configId=\"" .. device.http_port .. "\">\r\n" }
  table.insert(deviceXML, "  <specVersion><major>1</major><minor>0</minor></specVersion>\r\n" )
  table.insert(deviceXML, "  <URLBase>http://" .. wifi.sta.getip() .. ":" .. device.http_port .. "</URLBase>\r\n" )
  table.insert(deviceXML, "  <device>\r\n    <deviceType>" .. device.urn .. "</deviceType>\r\n" )
  table.insert(deviceXML, "    <friendlyName>" .. device.name .. "</friendlyName>\r\n" )
  table.insert(deviceXML, "    <manufacturer>konnected.io</manufacturer>\r\n" )
  table.insert(deviceXML, "    <manufacturerURL>http://konnected.io/</manufacturerURL>\r\n" )
  table.insert(deviceXML, "    <modelDescription>Konnected Security</modelDescription>\r\n" )
  table.insert(deviceXML, "    <modelName>" .. device.name .. "</modelName>\r\n" )
  table.insert(deviceXML, "    <modelNumber>" .. device.swVersion .. "</modelNumber>\r\n" )
  table.insert(deviceXML, "    <serialNumber>" .. node.chipid() .. "</serialNumber>\r\n" )
  table.insert(deviceXML, "    <UDN>" .. device.id .. "</UDN>\r\n" )
  table.insert(deviceXML, "    <presentationURL>/</presentationURL>\r\n" )
  table.insert(deviceXML, "  </device>\r\n</root>\r\n" )
  return table.concat(deviceXML)
end

return function()
  package.loaded[module] = nil
  module = nil
  return discoveryXML()
end