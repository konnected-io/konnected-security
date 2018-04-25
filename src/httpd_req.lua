local module = ...

local httpdRequestHandler = {
  method = nil,
  query = { }, 
  path = nil,
  contentType = nil,
  body = nil
}
local function httpdRequest(data)

  -- Some clients send POST data in multiple chunks.
  -- Collect data packets until the size of HTTP body meets the Content-Length stated in header
  -- this snippet borrowed from https://github.com/marcoskirsch/nodemcu-httpserver/blob/master/httpserver.lua
  local fullPayload, bBodyMissing
  if data:find("Content%-Length:") or bBodyMissing then
    if fullPayload then fullPayload = fullPayload .. data else fullPayload = data end
    if (tonumber(string.match(fullPayload, "%d+", fullPayload:find("Content%-Length:")+16)) > #fullPayload:sub(fullPayload:find("\r\n\r\n", 1, true)+4, #fullPayload)) then
      bBodyMissing = true
      return
    else
      data = fullPayload
      fullPayload, bBodyMissing = nil
    end
  end
  collectgarbage()

  print("Heap: ", node.heap(), "Processed full request payload")

  local _, _, method, path, query = string.find(data, '([A-Z]+) (.+)?(.+) HTTP')
  if method == nil then
    _, _, method, path = string.find(data, '([A-Z]+) (.+) HTTP')
  end

  if query ~= nil then
    query = string.gsub(query, '%%(%x%x)', function(x) string.char(tonumber(x, 16)) end)
    for k, v in string.gmatch(query, '([^&]+)=([^&]*)&*') do
      httpdRequestHandler.query[k] = v
    end
  end

  httpdRequestHandler.method = method
  httpdRequestHandler.path = path
  httpdRequestHandler.contentType = string.match(data, "Content%-Type: ([%w/-]+)")
  httpdRequestHandler.body = string.sub(data, string.find(data, "\r\n\r\n", 1, true), #data)

  if httpdRequestHandler.contentType == "application/json" then
    httpdRequestHandler.body = sjson.decode(httpdRequestHandler.body)
  end

  return httpdRequestHandler
end

return function(data)
  package.loaded[module] = nil
  module = nil
  return httpdRequest(data)
end