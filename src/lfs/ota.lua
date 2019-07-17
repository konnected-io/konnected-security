local module = ...

local function process(request)
  if request.method == "POST" and request.contentType == "application/json" then
    local uri = request.body.uri
    local proto, host, path, filename = string.match(uri, "(%w+)://([^/]+)(/[%w%p]+/)(.*)")
    LFS.http_ota(host, path, filename)
    return ""
  else
    return "bad request"
  end
end


return function(request)
  package.loaded[module] = nil
  module = nil
  return process(request)
end