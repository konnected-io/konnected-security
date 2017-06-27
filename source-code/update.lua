print("Heap: ", node.heap(), "Updater: running..")
local function findAttr(line) 
  local l1 = string.match(line, "http.*:\/\/(.*)")
  local l2 = string.sub(l1, 1, (string.find(l1,"\/") - 1))
  local path = string.sub(l1, string.find(l1,"\/"), #l1)
  local filenm = string.match(path, "\/.*\/(.*)")
  local host, port = string.match(l2, "(.*):(.*)")
  host = l2 or host
  if string.match(line, "https:") then
    port = "443" or port
  elseif string.match(line, "http:") then
    port = "80" or port
  end
  return host,port,path,filenm
end

local function getHeaderValue(line, headerPattern)
  local l1 = string.match(line, headerPattern .. ": (.*)")
  if l1 then 
    local l2 = string.sub(l1, 1, ( string.find(l1, "\r\n") - 1 ))
    return l2
  else
    return nil
  end
end

tmr.create():alarm(180, tmr.ALARM_AUTO, function(t) 
  if gpio.read(4) == gpio.HIGH then
    gpio.write(4, gpio.LOW)
  else
    gpio.write(4, gpio.HIGH)
  end
end)

if file.exists("manifest") then
  print("Heap: ", node.heap(), "Updater: Processing manifest")
  dofile("manifest")
  tmr.create():alarm(200, tmr.ALARM_AUTO, function(t)
    t:stop()
    if manifest[1] then
      local fw = file.open(manifest[1].filenm .. ".tmp", "w")
      local conn = net.createConnection(net.TCP, 1)
      conn:connect(443, manifest[1].host)
      conn:on("receive", function(sck, c)  fw:write(c) end)
      conn:on("disconnection", function(sck)
        fw:close()
        sck:close()
        collectgarbage()
        
        local redirect = false
        local fr = file.open(manifest[1].filenm .. ".tmp", "r+")
        local fr_line = ""
        while true do
          fr_line = fr:readline()
          if fr_line == nil then
            break
          end
          if string.find(fr_line, "Status: 302 Found") then
            redirect = true
          end
          if redirect then
            if string.match(fr_line, "Location: (.*)") then  
              fr:seek("set", (fr:seek("cur") - #fr_line))
              fr_line = fr:read(1024)
              local host, port, path = findAttr(getHeaderValue(fr_line, "Location"))
              table.insert(manifest, { host = host, port = port, path = path, filenm = manifest[1].filenm })
              print("Heap: ", node.heap(), "Updater: File redirection", manifest[1].filenm, "\r\nhttps:\/\/".. host .. path)
              break
            end
          end
        end
        fr:close()
        fr_line = nil
        collectgarbage()
        
        if redirect == false then
          print("Heap: ", node.heap(), "Updater: Downloaded", manifest[1].filenm)
          
          local fr_body_pos = 0
          local fr_line = ""
          local fr_len = 0
          fr = file.open(manifest[1].filenm .. ".tmp", "r+")
          print("Heap: ", node.heap(), "Updater: Processing file", manifest[1].filenm)
          while true do
            local fr_line = fr:readline()
            if fr_line == nil then
              break
            end
            
            fr_len = getHeaderValue(fr_line, "Content%-Length") 
            if fr_len then
              fr_body_pos = fr:seek("end") - string.format( "%d", fr_len )
              break
            end
          end
          fr_len = nil
          fr_line = nil
          collectgarbage()
          
          local fr_line = ""
          local fw = file.open(manifest[1].filenm, "w")
          if fr_body_pos > 0 then
            print("Heap: ", node.heap(), "Updater: Finalizing file", manifest[1].filenm)
            while fr:seek("set", fr_body_pos) do
              fr_body_pos = fr_body_pos + 512
              fr_line = fr:read(512)
              fw:write(fr_line)
            end
          end
          fr_line = nil
          fr_body_pos = nil
          fr:close()
          fw:close()
          collectgarbage()
        end
        table.remove(manifest, 1)
        t:start()
      end)
      conn:on("connection", function(sck)
        sck:send("GET " .. manifest[1].path .. " HTTP/1.1\r\nHost: ".. manifest[1].host .."\r\nConnection: keep-alive\r\n"..
                 "Accept: */*\r\nUser-Agent: ESP8266\r\n\r\n")
      end)
    else
      t:unregister()
      local fw = file.open("var_update.lua", "w")
      fw:writeline("update = false")
      fw:close()
      if file.exists("manifest") then 
        file.remove("manifest")
      end
      if file.exists("device") then
        file.rename("device", "var_device.lua")
      end
      print("Heap: ", node.heap(), "Updater: Done restarting in 3 seconds")
      tmr.create():alarm(3000, tmr.ALARM_SINGLE, function(t) node.restart() end)
    end
  end)
else
  local dlist = { }
  local body = ""
  local line = ""
  local fw = file.open("manifest.tmp", "w")
  local conn = net.createConnection(net.TCP, 1)
  conn:connect(443, "api.github.com")
  conn:on("receive", function(sck, c) 
    line = string.gsub(c, "\"%," , "\"%,\r\n")
    line = string.gsub(line, "}%," , "}%,\r\n")
    line = string.gsub(line, "]%," , "]%,\r\n")
    fw.write(line)
  end)
  conn:on("disconnection", function(sck)
    fw.close()
    collectgarbage()
    local fr = file.open("manifest.tmp", "r")
    while true do 
      line = fr.readline() 
      local tag = string.find(line,"\"tag_name\"", 1, true)
      if (tag) then
        body = "{ " .. string.gsub(line, "\"%," , "\"") .. " }"
        body = cjson.decode(body)
        fr.close()
        break 
      end
      if (line == nil) then 
        fr.close()
        break 
      end
    end
    
    if (body.tag_name > device.swVersion) then
      print("Heap: ", node.heap(), "Updater: Version outdated, retrieving manifest list...")
      local fr = file.open("manifest.tmp", "r")
      while true do 
        line = fr.readline() 
        if (line == nil) then 
          fr.close()
          break 
        end
        local tag = string.find(line,"\"browser_download_url\"", 1, true)
        if (tag) then
          line = string.gsub(line, "\"}%," , "")
          line = string.gsub(line, "\"}]%," , "")
          line = string.gsub(line, "\"browser_download_url\".*\"" , "")
          table.insert(dlist, line)
        end
      end
      
      local fw = file.open("manifest", "w")
      fw.writeline("manifest = { ")
      for i, dl in pairs(dlist) do
        local host, port, path, filenm = findAttr(string.match(dl, "(.*)\r\n"))
        fw.write(table.concat({"{ host = \"",host,"\", port = \"",port,"\", path = \"", path, "\", filenm = \"",filenm,"\" }"}))
        if i < #dlist then
          fw.writeline(",")
        end
      end
      fw.writeline("}")
      fw.close()
      collectgarbage()
      
      local fw = file.open("device", "w")
      fw:writeline("device = { name = \"".. device.name .."\",\r\nhwVersion = \"" .. device.hwVersion .. "\",\r\nswVersion = \"" .. body.tag_name .. "\" }")
      fw:close()
      collectgarbage()
    end
    
    if file.exists("manifest.tmp") then
      file.remove("manifest.tmp")
    end
    
    print("Heap: ", node.heap(), "Updater: Retrieved manifest list.. restarting in 3 seconds")
    tmr.create():alarm(3000, tmr.ALARM_SINGLE, function(t) node.restart() end)    
  end)
  conn:on("connection", function(sck)
    sck:send("GET /repos/konnected-io/"..device.name.."/releases/latest HTTP/1.1\r\nHost: api.github.com\r\nConnection: keep-alive\r\n"..
             "Accept: */*\r\nUser-Agent: konnected.io "..device.name.."\r\n\r\n")
  end)
end


