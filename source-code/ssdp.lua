local device = require("device")
local device_ip = wifi.sta.getip()
local ssdp_deviceType = "urn:schemas-konnected-io:device:" .. device.name .. ":1"
local ssdp_deviceID = "uuid:8f655392-a778-4fee-97b9-4825918" .. string.format("%x", node.chipid())
local ssdp_deviceXML = { "<?xml version=\"1.0\"?>\r\n", "<root xmlns=\"urn:schemas-upnp-org:device-1-0\">\r\n", "\t<specVersion><major>1</major><minor>0</minor></specVersion>\r\n" }
  table.insert(ssdp_deviceXML, "\t<URLBase>http://" .. device_ip .. ":80</URLBase>\r\n" )
  table.insert(ssdp_deviceXML, "\t<device>\r\n\t\t<deviceType>" .. ssdp_deviceType .. "</deviceType>\r\n" )
  table.insert(ssdp_deviceXML, "\t\t<friendlyName>" .. device.name .. "</friendlyName>\r\n" )
  table.insert(ssdp_deviceXML, "\t\t<manufacturer>konnected.io</manufacturer>\r\n" )
  table.insert(ssdp_deviceXML, "\t\t<manufacturerURL>http://konnected.io/</manufacturerURL>\r\n" )
  table.insert(ssdp_deviceXML, "\t\t<modelDescription>Alarm Panel</modelDescription>\r\n" )
  table.insert(ssdp_deviceXML, "\t\t<modelName>" .. device.name .. "</modelName>\r\n" )
  table.insert(ssdp_deviceXML, "\t\t<modelNumber>" .. device.hwVersion .. "</modelNumber>\r\n" )
  table.insert(ssdp_deviceXML, "\t\t<serialNumber>" .. node.chipid() .. "</serialNumber>\r\n" )
  table.insert(ssdp_deviceXML, "\t\t<UDN>" .. ssdp_deviceID .. "</UDN>\r\n" )
  table.insert(ssdp_deviceXML, "\t\t<presentationURL>/</presentationURL>\r\n" )
  table.insert(ssdp_deviceXML, "\t</device>\r\n</root>\r\n" )
ssdp_deviceXML = table.concat(ssdp_deviceXML)

net.multicastJoin(device_ip, "239.255.255.250")

local ssdp_sv = net.createServer(net.UDP)
ssdp_sv:listen(1900, "239.255.255.250")
ssdp_sv:on("receive", function(c, d, p, i)
  if string.match(d, "M-SEARCH") then
    if (string.match(d, "urn.*%d") == ssdp_deviceType) then
      local httpd_port = math.floor(node.chipid()/1000) + 8000
      local ssdp_resp =
        "HTTP/1.1 200 OK\r\n" ..
        "Cache-Control: max-age=120\r\n" ..
        "ST: " .. ssdp_deviceType .. "\r\n" ..
        "USN: " .. ssdp_deviceID .. "::" .. ssdp_deviceType .. "\r\n" .. "EXT:\r\n" ..
        "SERVER: NodeMCU/" .. string.format("%d.%d.%d", node.info()) .. " UPnP/1.1 " .. device.name .. "/" .. device.hwVersion .. "\r\n" ..
        "LOCATION: http://" .. device_ip .. ":" .. httpd_port .. "/Device.xml\r\n\r\n"
      c:send(ssdp_resp)
      ssdp_resp = nil
    end
  end
end)

return ssdp_deviceXML
