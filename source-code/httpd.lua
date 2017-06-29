local httpdResponse = require("httpd_res")

local httpServer_handler = {
  {
    url = '.*',
    cb = function(r, s)
      local _, _, m, p, q = string.find(r.source, '([A-Z]+) (.+)?(.+) HTTP')
      if m == nil then
        _, _, m, p = string.find(r.source, '([A-Z]+) (.+) HTTP')
      end

      local query = {}
      if q ~= nil then
        q = string.gsub(q, '%%(%x%x)', function(x) string.char(tonumber(x, 16)) end)
        for k, v in string.gmatch(q, '([^&]+)=([^&]*)&*') do
          query[k] = v
        end
      end
      r.method = m
      r.query = query
      r.path = p
      r.contentType = string.match(r.source, "Content%-Type: ([%w/-]+)")
      r.body = r.source:sub(r.source:find("\r\n\r\n", 1, true), #r.source)
      r.source = nil
      if r.contentType == "application/json" then
        r.body = cjson.decode(r.body)
      end
      return true
    end
  }, {
    url = '.*',
    cb = function(r, s)
      local filename = ''
      if r.path == '/' then
        filename = 'index.html'
      else
        filename = string.gsub(string.sub(r.path, 2), '/', '_')
      end

      s:file(filename)
    end
  }
}

function httpd_set(url, cb)
  table.insert(httpServer_handler, #httpServer_handler, { url = url, cb = cb })
end

local httpd_server = net.createServer(net.TCP, 10)
local httpd_port = math.floor(node.chipid()/1000) + 8000
print("Heap: ", node.heap(), "HTTP: ", "Starting server on port", httpd_port )
httpd_server:listen(httpd_port, function(c)
  c:on('receive', function(s, d)
    local r = { source = d, path = '' }
    local s = httpdResponse:new(s)
    for i = 1, #httpServer_handler do
      if string.find(r.path, '^' .. httpServer_handler[i].url .. '$') and not httpServer_handler[i].cb(r, s) then
        break
      end
    end
    collectgarbage()
  end)
end)


