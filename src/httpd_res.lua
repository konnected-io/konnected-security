local httpdResponse
local httpdResponseHandler
local sck = nil

local send = function (body, ty, st) 
  local ty = ty or "application/json"
  local st = st or 200
  local sendContent = table.concat({'HTTP/1.1 ', st, '\r\nContent-Type: ', ty, '\r\nContent-Length: ', string.len(body), '\r\n\r\n', body})
  local function doSend(s)
    if sendContent == '' then
      s:close()
    else
      s:send(string.sub(sendContent, 1, 512))
      sendContent = string.sub(sendContent, 513)
    end
  end

  sck:on('sent', doSend)
  doSend(sck)
end
local file = function (filename, ty, st)
  local ty = ty or "text/html"
  local st = st or 200
  if file.exists(filename .. '.gz') then
    filename = filename .. '.gz'
  elseif not file.exists(filename) then
    send("", ty, 404)
    return
  end
  
  local header = {'HTTP/1.1 ', st, '\r\nContent-Type: ', ty, '\r\n'}
  if string.sub(filename, -3) == '.gz' then
    table.insert(header, 'Content-Encoding: gzip\r\n')
  end
  table.insert(header, '\r\n')
  header = table.concat(header)
  local i = 0
  sck:on('sent', function(s) 
    local f = file.open(filename, 'r')
    if f.seek('set', i) then
      local buf = file.read(512)
      i = i + 512
      s:send(buf)
    else
      s:close()
    end
    f.close()
  end)
  sck:send(header)
end
httpdResponseHandler = {
  send = send,
  file = file
}
httpdResponse = {
  new = function (s) 
    sck = s 
    return httpdResponseHandler
  end
}
return httpdResponse