local ssdp_deviceType = "urn:schemas-konnected-io:device:AlarmPanel:1"
local ssdp_deviceID = "uuid:8f655392-a778-4fee-97b9-4825918"..string.format("%x",node.chipid())
local ssdp_deviceXML = "<?xml version=\"1.0\"?>\r\n"..
				"<root xmlns=\"urn:schemas-upnp-org:device-1-0\">\r\n"..
				"\t<specVersion><major>1</major><minor>0</minor></specVersion>\r\n"..
				"\t<URLBase>http://"..wifi.sta.getip()..":80</URLBase>\r\n"..
				"\t<device>\r\n"..
				"\t\t<deviceType>"..ssdp_deviceType.."</deviceType>\r\n"..
				"\t\t<friendlyName>"..device.name.."</friendlyName>\r\n"..
				"\t\t<manufacturer>konnected.io</manufacturer>\r\n"..
				"\t\t<manufacturerURL>http://konnected.io/</manufacturerURL>\r\n"..
				"\t\t<modelDescription>Alarm Panel</modelDescription>\r\n"..
				"\t\t<modelName>"..device.name.."</modelName>\r\n"..
				"\t\t<modelNumber>"..device.hwVersion.."</modelNumber>\r\n"..
				"\t\t<serialNumber>"..node.chipid().."</serialNumber>\r\n"..
				"\t\t<UDN>"..ssdp_deviceID.."</UDN>\r\n"..
				"\t\t<presentationURL>/</presentationURL>\r\n"..
				"\t</device>\r\n</root>\r\n"
net.multicastJoin(wifi.sta.getip() ,"239.255.255.250")
local ssdp_sv = net.createServer(net.UDP)
ssdp_sv:listen(1900,"239.255.255.250")
ssdp_sv:on("receive", function(c, d, p, i)
	if string.match(d,"M-SEARCH") then
		if ( string.match(d, "urn.*%d") == ssdp_deviceType ) then
			local ssdp_resp = 
				"HTTP/1.1 200 OK\r\n"..
				"Cache-Control: max-age=120\r\n"..
				"ST: "..ssdp_deviceType.."\r\n"..
				"USN: "..ssdp_deviceID.."::"..ssdp_deviceType.."\r\n".."EXT:\r\n"..
				"SERVER: NodeMCU/"..string.format("%d.%d.%d",node.info()).." UPnP/1.1 "..device.name.."/"..device.hwVersion.."\r\n"..
				"LOCATION: http://"..wifi.sta.getip()..":80/Device.xml\r\n\r\n"
			c:send(ssdp_resp)
			ssdp_resp = nil
		end
	end
end)    
httpd_set("/Device.xml", function(request, response) 
	response:contentType("text/xml")
	response:send(ssdp_deviceXML)
end)
