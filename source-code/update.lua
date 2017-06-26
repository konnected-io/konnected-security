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

if file.exists("manifest") then
  print("Heap: ", node.heap(), "Updater: Processing manifest")
  dofile("manifest")
  tmr.create():alarm(200, tmr.ALARM_AUTO, function(t)
    t:stop()
    if manifest[1] then
      local fw = file.open(manifest[1].filenm .. ".tmp", "w")
      local conn = net.createConnection(net.TCP, 1)
      conn:connect(443, manifest[1].host)
      conn:on("receive", function(sck, c)  fw.write(c) end)
      conn:on("disconnection", function(sck)
        fw.close()
        sck:close()
        collectgarbage()
        
        local fr = file.open(manifest[1].filenm .. ".tmp", "r")
        local redirect = false
        local locat = nil
        
        
        while true do
          local line = fr.readline()
          if line == nil then
            break
          end
          if string.find(line, "Status: 302 Found") then
            redirect = true
          end
          if redirect then
            if string.match(line, "Location: (.*)") then  
              local fpos = fr:seek("cur")
              fr:seek("set", (fpos - #line))
              local fposline = fr:read(1024)
              local fposend = (string.find(fposline,"\r\n") - 1)
              local host, port, path = findAttr(string.match(string.sub(fposline,1,fposend), "Location: (.*)"))
              
              table.insert(manifest, { host = host, port = port, path = path, filenm = manifest[1].filenm })
              print("Heap: ", node.heap(), "Updater: File redirection", manifest[1].filenm, "\r\nhttps:\/\/".. host .. path)
              break
            end
          end
        end
        fr.close()
        collectgarbage()
        
        if redirect == false then
          print("Heap: ", node.heap(), "Updater: Downloaded", manifest[1].filenm)
          local fr1 = file.open(manifest[1].filenm .. ".tmp", "r")
          
          local fi = 0
          local fc = 0
          
          print("Heap: ", node.heap(), "Updater: Processing file", manifest[1].filenm)
          fr1.seek("set", 1)
          while true do
            local fline = fr1:read(1024)
            local _, fj = string.find(fline, "\r\n\r\n")
            if fj then
              fc = fr1:seek("cur") + 1 + fj
              break
            end
            fi = fi + 512
            local fs = fr1:seek("set", fi)
            if fs == nil then 
              break
            end
          end
          fr1:close()
          collectgarbage()
          
          print("Heap: ", node.heap(), "Updater: Finalizing file", manifest[1].filenm)
          local fr2 = file.open(manifest[1].filenm .. ".tmp", "r")
          local fw1 = file.open(manifest[1].filenm .. ".tmp" .. ".tmp", "w")
          if fc > 0 then
            fr2:seek("set", fc)
            print("Heap: ", node.heap(), "Updater: file position", fc)
            while true do
              local fline = fr2:read(512)
              print(fline)
              fw1:write(fline)
              fi = fi + 512
              local fs = fr2:seek("set", fi)
              if fs == nil then 
                break
              end
            end
          end
          fr2:close()
          fw1:close()
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
      fw.writeline("update = false")
      fw.close()
      if file.exists("manifest") then 
        file.remove("manifest")
      end
      print("Heap: ", node.heap(), "Updater: Done")
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
      
      fw = file.open("manifest", "w")
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
      
    end
    if file.exists("manifest.tmp") then
      file.remove("manifest.tmp")
    end
    print("Heap: ", node.heap(), "Updater: Retrieved manifest list.. restarting in 3 seconds")
    tmr.create():alarm(3000, tmr.ALARM_SINGLE, function(t) node.restart() end)    
  end)
  conn:on("connection", function(sck)
    sck:send("GET /repos/copy-ninja/AlarmPanel/releases/latest HTTP/1.1\r\nHost: api.github.com\r\nConnection: keep-alive\r\n"..
             "Accept: */*\r\nUser-Agent: ESP8266\r\nAuthorization: Basic Y29weS1uaW5qYTptY2g1MTgz\r\n\r\n")
  end)
end


