local module = ...

local httpdRequestHandler = {
  method = nil,
  query = { }, 
  path = nil,
  contentType = nil,
  body = nil
}
local function httpdRequest(data)
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
  httpdRequestHandler.contentType = string.match(data, "[Cc]ontent%-[Tt]ype: ([%w/-]+)")
  local bodyPos = string.find(data, "\r\n\r\n", 1, true)

  if bodyPos then
    httpdRequestHandler.body = string.sub(data, bodyPos + 4, #data)

    if httpdRequestHandler.contentType == "application/json" then
      httpdRequestHandler.body = sjson.decode(httpdRequestHandler.body)
    end
  end

  return httpdRequestHandler
end

return function(data)
  package.loaded[module] = nil
  module = nil
  return httpdRequest(data)
end
