local httpdResponse = {
  _sk = nil,
  _ty = nil,
  _st = nil
}

function httpdResponse:new(s)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o._sk = s
  return o
end

function httpdResponse:contentType(t)
  self._ty = t
end

function httpdResponse:status(s)
  self._st = s
end

function httpdResponse:send(body)
  self._st = self._st or 200
  self._ty = self._ty or "application/json"

  local b = 'HTTP/1.1 ' .. self._st .. '\r\n' ..
    'Content-Type: ' .. self._ty .. '\r\n' ..
    'Content-Length:' .. string.len(body) .. '\r\n' ..
    '\r\n' .. body
  local function doSend(s)
    if b == '' then
      self:close()
    else
      s:send(string.sub(b, 1, 512))
      b = string.sub(b, 513)
    end
  end

  self._sk:on('sent', doSend)
  doSend(self._sk)
end

function httpdResponse:file(filename)
  if file.exists(filename .. '.gz') then
    filename = filename .. '.gz'
  elseif not file.exists(filename) then
    self:status(404)
    self:send("")
    return
  end

  self._st = self._st or 200
  self._ty = self._ty or 'text/html'
  local header = 'HTTP/1.1 ' .. self._st .. '\r\n' ..
    'Content-Type: ' .. self._ty .. '\r\n'
  if string.sub(filename, -3) == '.gz' then
    header = header .. 'Content-Encoding: gzip\r\n'
  end
  header = header .. '\r\n'
  local i = 0
  local function doSend(s)
    local f = file.open(filename, 'r')
    if f.seek('set', i) then
      local buf = file.read(512)
      i = i + 512
      s:send(buf)
    else
      self:close()
    end
    f.close()
  end

  self._sk:on('sent', doSend)
  self._sk:send(header)
end

function httpdResponse:close()
  self._sk:on('sent', function() end)
  self._sk:on('receive', function() end)
  self._sk:close()
end

local httpServer_handler = {
  {
    url = '.*',
    cb = function(r, s)
      local _, _, m, p, q = string.find(r.source, '([A-Z]+) (.+)?(.+) HTTP')
      if m == nil then
        _, _, m, p = string.find(r.source, '([A-Z]+) (.+) HTTP')
      end
      local function urlDecode(url)
        return string.gsub(url, '%%(%x%x)', function(x)
          return string.char(tonumber(x, 16))
        end)
      end

      local query = {}
      if q ~= nil then
        q = urlDecode(q)
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


