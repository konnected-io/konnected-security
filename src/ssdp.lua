local device = require("device")
local deviceIP = wifi.sta.getip()
local devicePort = math.floor(node.chipid()/1000) + 8000
local deviceType = "urn:schemas-konnected-io:device:" .. device.name .. ":1"
local deviceID = "uuid:8f655392-a778-4fee-97b9-4825918" .. string.format("%x", node.chipid())
local deviceXML = { "<?xml version=\"1.0\"?>\r\n", "<root xmlns=\"urn:schemas-upnp-org:device-1-0\">\r\n", "\t<specVersion><major>1</major><minor>0</minor></specVersion>\r\n" }
  table.insert(deviceXML, "\t<URLBase>http://" .. deviceIP .. ":" .. devicePort .. "</URLBase>\r\n" )
  table.insert(deviceXML, "\t<device>\r\n\t\t<deviceType>" .. deviceType .. "</deviceType>\r\n" )
  table.insert(deviceXML, "\t\t<friendlyName>" .. device.name .. "</friendlyName>\r\n" )
  table.insert(deviceXML, "\t\t<manufacturer>konnected.io</manufacturer>\r\n" )
  table.insert(deviceXML, "\t\t<manufacturerURL>http://konnected.io/</manufacturerURL>\r\n" )
  table.insert(deviceXML, "\t\t<modelDescription>Konnected Security</modelDescription>\r\n" )
  table.insert(deviceXML, "\t\t<modelName>" .. device.name .. "</modelName>\r\n" )
  table.insert(deviceXML, "\t\t<modelNumber>" .. device.hwVersion .. "</modelNumber>\r\n" )
  table.insert(deviceXML, "\t\t<serialNumber>" .. node.chipid() .. "</serialNumber>\r\n" )
  table.insert(deviceXML, "\t\t<UDN>" .. deviceID .. "</UDN>\r\n" )
  table.insert(deviceXML, "\t\t<presentationURL>/</presentationURL>\r\n" )
  table.insert(deviceXML, "\t</device>\r\n</root>\r\n" )
deviceXML = table.concat(deviceXML)

net.multicastJoin(deviceIP, "239.255.255.250")

local srv = net.createServer(net.UDP)
srv:listen(1900, "239.255.255.250")
srv:on("receive", function(c, d, p, i)
  if string.match(d, "M-SEARCH") then
    if (string.match(d, "urn.*%d") == deviceType) then
      local resp =
        "HTTP/1.1 200 OK\r\n" ..
        "Cache-Control: max-age=120\r\n" ..
        "ST: " .. deviceType .. "\r\n" ..
        "USN: " .. deviceID .. "::" .. deviceType .. "\r\n" .. "EXT:\r\n" ..
        "SERVER: NodeMCU/" .. string.format("%d.%d.%d", node.info()) .. " UPnP/1.1 " .. device.name .. "/" .. device.hwVersion .. "\r\n" ..
        "LOCATION: http://" .. deviceIP .. ":" .. devicePort .. "/Device.xml\r\n\r\n"
      c:send(resp)
      resp = nil
    end
  end
end)

return deviceXML
