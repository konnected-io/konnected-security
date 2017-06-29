local httpdRequestHandler = {
  method = nil,
  query = { }, 
  path = nil,
  contentType = nil,
  body = nil
}
local httpdRequest = {
  new = function (data) 
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
      httpdRequestHandler.body = cjson.decode(httpdRequestHandler.body)
    end
    
    return httpdRequestHandler
  end
}
return httpdRequest