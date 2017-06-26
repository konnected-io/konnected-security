print("Heap: ", node.heap(), "Update running")
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
  dofile("manifest")
  tmr.create():alarm(1000, tmr.ALARM_AUTO, function(t)
    t:stop()
    if manifest[1] then
      local fw = file.open(manifest[1].filenm .. ".tmp", "w")
      local conn = net.createConnection(net.TCP, 1)
      conn:connect(443, manifest[1].host)
      conn:on("receive", function(sck, c) 
        local redirect = false
        if string.match(c, "Status: 302 Found") then
          redirect = true
          local locat = string.match(c, "Location: (.*)")
          local host, port, path = findAttr(string.sub(locat, 1, (string.find(locat,"\r\n") - 1)))
          table.insert(manifest, #manifest, { host = host, port = port, path = path, filenm = manifest[1].filenm })
        else
          fw.write(c)
        end
      end)
      conn:on("disconnection", function(sck)
        print("Heap: ", node.heap(), "Downloaded", manifest[1].filenm)
        fw.close()
        table.remove(manifest, 1)
        t:start()
      end)
      conn:on("connection", function(sck)
        sck:send("GET " .. manifest[1].path .. " HTTP/1.1\r\nHost: ".. manifest[1].host .."\r\nConnection: keep-alive\r\n"..
                 "Accept: */*\r\nUser-Agent: ESP8266\r\n\r\n")
      end)
    else
      t:unregister()
      local fw = file.open("var_update", "w")
      fw.writeline("update = false")
      fw.close()
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
      print("Heap: ", node.heap(), "Version outdated, retrieving manifest list...")
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
    print("Heap: ", node.heap(), "Retrieved manifest list.. restarting in 3 seconds")
    tmr.create():alarm(3000, tmr.ALARM_SINGLE, function(t) node.restart() end)    
  end)
  conn:on("connection", function(sck)
    sck:send("GET /repos/copy-ninja/AlarmPanel/releases/latest HTTP/1.1\r\nHost: api.github.com\r\nConnection: keep-alive\r\n"..
             "Accept: */*\r\nUser-Agent: ESP8266\r\nAuthorization: Basic Y29weS1uaW5qYTptY2g1MTgz\r\n\r\n")
  end)
end


