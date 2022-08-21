local bit32 = bit32 or bit

local function lengthStr(length)
  local buf = ""
  local digit = 0
  repeat
    digit = bit32.band(length, 127)
    length = bit32.rshift(length, 7)
    if length > 0 then
      digit = digit + 128
    end
    buf = buf .. string.char(digit)
  until length == 0
  return buf
end

local function numberStr(n)
	return string.char(bit32.band(bit32.rshift(n, 8), 255), bit32.band(n, 255))
end

local function textStr(text)
	return numberStr(text:len()) .. text
end

local function subscribe(opts)
	local topics_buf = ""
	for topic, qos in pairs(opts.topics) do
		topics_buf = topics_buf .. textStr(topic) .. string.char(qos)
	end
	local length = 2 + topics_buf:len()
	return string.char(0x82) .. lengthStr(length) .. numberStr(opts.msg_id) .. topics_buf
end

local function publish(opts)
	local length = 2 + opts.topic:len() + opts.payload:len() + (opts.qos and 2 or 0)
	return string.char(0x30 + (opts.qos and 2 or 0)) .. lengthStr(length) .. textStr(opts.topic) .. (opts.qos and numberStr(opts.msg_id) or "") .. opts.payload
end

local function parse(buf)
	local packet = {}

	local cmd = bit32.rshift(buf:byte(1), 4)

	packet.cmd = cmd

	if cmd == 3 then
		local i = 2
		while buf:byte(i) >= 128 do
			i = i + 1
		end
		i = i + 1
		local topic_len = buf:byte(i) * 256 + buf:byte(i+1)
		i = i + 2
		packet.topic = buf:sub(i, i + topic_len - 1)
		packet.payload = buf:sub(i + topic_len)
	elseif cmd == 4 then
	  packet.message_id = bit32.lshift(buf:byte(3),8) + buf:byte(4)
	end
	return packet
end

return {
	subscribe = subscribe,
	publish = publish,
	parse = parse
}
