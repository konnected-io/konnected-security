local module = ...

local function respondWithText(sck, body, ty, st, headers)
  local ty = ty or "application/json"
  local st = st or 200
  local headers = headers or ''
  local contentLength = string.len(body)

  if contentLength > 0 then
    headers = table.concat({ headers, 'Content-Type: ', ty, '\r\nContent-Length: ', contentLength, '\r\n' })
  end

  local sendContent = table.concat({
    'HTTP/1.1 ', st, '\r\nAccess-Control-Allow-Origin: *\r\n', headers, '\r\n', body
  })
  local function doSend(s)
    if sendContent == '' then
      pcall(s.close, s)
      sendContent = nil
    else
      pcall(s.send, s, string.sub(sendContent, 1, 512))
      sendContent = string.sub(sendContent, 513)
    end
  end

  sck:on('sent', doSend)
  doSend(sck)
end

local function respondWithFile(sck, filename, ty, st, headers)
  local ty = ty or "text/html"
  local st = st or 200
  if file.exists(filename .. '.gz') then
    filename = filename .. '.gz'
  elseif not file.exists(filename) then
    send("", ty, 404)
    return
  end

  local header = {'HTTP/1.1 ', st, '\r\nContent-Type: ', ty, '\r\n', 'Access-Control-Allow-Origin: *\r\n'}
  if string.sub(filename, -3) == '.gz' then
    table.insert(header, 'Content-Encoding: gzip\r\n')
  end
  table.insert(header, '\r\n')
  header = table.concat(header)
  local i = 0
  local function doSend(s)
    local f = file.open(filename, 'r')
    if f.seek('set', i) then
      local buf = file.read(512)
      i = i + 512
      pcall(s.send, s, buf)
    else
      pcall(s.close, s)
    end
    f.close()
  end
  sck:on('sent', doSend)
  sck:send(header)
end

local httpdResponse = {
  text = respondWithText,
  file = respondWithFile
}

return function()
  package.loaded[module] = nil
  module = nil
  return httpdResponse
end