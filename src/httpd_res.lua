local function respondWithText(sck, body, ty, st)
  local ty = ty or "application/json"
  local st = st or 200
  local sendContent = table.concat({'HTTP/1.1 ', st, '\r\nContent-Type: ', ty, '\r\nContent-Length: ', string.len(body), '\r\n\r\n', body})
  local function doSend(s)
    if sendContent == '' then
      s:close()
      sendContent = nil
      print("Heap: ", node.heap(), "Done sending text")
    else
      s:send(string.sub(sendContent, 1, 512))
      sendContent = string.sub(sendContent, 513)
      print("Heap: ", node.heap(), "Sending text content")
    end
  end

  sck:on('sent', doSend)
  doSend(sck)
end

local function respondWithFile(sck, filename, ty, st)
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
  local function doSend(s)
    local f = file.open(filename, 'r')
    if f.seek('set', i) then
      local buf = file.read(512)
      i = i + 512
      s:send(buf)
      print("Heap: ", node.heap(), "Sending file content")
    else
      s:close()
      print("Heap: ", node.heap(), "Done sending file content")
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
return httpdResponse