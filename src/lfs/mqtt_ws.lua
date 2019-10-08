local mqtt_packet = require('mqtt_packet')

local function emit(self, event, ...)
	local cb = self.events[event]
	if cb then
		cb(self, ...)
	end
end

local function connect(self, url)
	self.ws:connect(url)
end

local function close(self)
	self.ws:close()
end

local function on(self, event, callback)
	self.events[event] = callback
end

local function subscribe(self, topic, qos)
	if type(topic) ~= 'table' then
		topic = {[topic] = qos or 0}
	end

	self.ws:send(mqtt_packet.subscribe({msg_id=self.msg_id, topics=topic}), 2)
	self.msg_id = self.msg_id + 1
end

local function publish(self, topic, message)
	self.ws:send(mqtt_packet.publish({topic=topic, payload=sjson.encode(message), qos=1, msg_id=self.msg_id}), 2)
	self.msg_id = self.msg_id + 1
end

local function Client(aws_settings)
	local ws = websocket.createClient()
  local headers = {["sec-websocket-protocol"] = "mqtt" }
  if aws_settings.token and aws_settings.authorizer_signature then
		headers["X-Amz-CustomAuthorizer-Name"] = aws_settings.authorizer_name
		headers["X-Amz-CustomAuthorizer-Signature"] = aws_settings.authorizer_signature
		headers["Token"] = aws_settings.token
	end
	ws:config({headers=headers})
	local client = {
		connect = connect,
		close = close,
		subscribe = subscribe,
		publish = publish,
		on = on,
		emit = emit,
		events = {},
		ws = ws,
		msg_id = 1,
	}

	ws:on('receive', function(_, msg, opcode, x)
--		print("received", msg:len(), "msg:", msg, "bytes:", mqtt_packet.toHex(msg))
		local parsed = mqtt_packet.parse(msg)
--		for k, v in pairs(parsed) do
--			print('>', k, v)
--		end

		if parsed.cmd == 4 then
			client:emit('puback', parsed.message_id)
		elseif parsed.cmd == 3 then
			client:emit('message', parsed.topic, parsed.payload)
		elseif parsed.cmd == 2 then
			client:emit('connect')
		end
	end)

	ws:on('close', function(_, status)
		print("Heap:", node.heap(), 'websocket closed, status:', status)
		client:emit('offline')
	end)

	ws:on('connection', function(_)
		print("Heap:", node.heap(), "websocket connected")
		ws:send(string.char(0x10, 0x0c, 0x00, 0x04, 0x4d, 0x51, 0x54, 0x54, 0x04, 0x02, 0x00, 0x00, 0x00, 0x00), 2)
	end)

	return client
end

return {
	Client = Client
}
