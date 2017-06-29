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

return httpdResponse