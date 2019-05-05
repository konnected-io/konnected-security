local config = require('aws_config')
local mqtt = require('mqtt_ws')

function aws_sign_url(url)
	local aws_sig = require('aws_sig')
	local url = aws_sig.createSignature(config.AWS_ACCESS_KEY, config.AWS_SECRET_KEY, config.AWS_REGION, 'iotdevicegateway', 'GET', config.AWS_MQTT_URL, '')
	aws_sig = nil
	package.loaded.aws_sig = nil
	return url
end

local c = mqtt.Client()

c:on('message', function(_, topic, message)
	print('topic:', topic, 'msg:', message)
	local data = sjson.decode(message)
end)

c:on('connect', function()
	print("mqtt: connected")
	c:subscribe("/things/" .. (config.THING_NAME or wifi.sta.getmac():lower()))
--  c:publish('/things/' .. wifi.sta.getmac():lower(), {pin=1, state=1})
end)

c:on('offline', function()
	print("mqtt: offline")
	c:connect(aws_sign_url(config.AWS_MQTT_URL))
end)

print('connecting to amazon mqtt gateway')
c:connect(aws_sign_url(config.AWS_MQTT_URL))

return c