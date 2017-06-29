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
    if (line == nil) then 
      break 
    end
    local tag = string.find(line,"\"tag_name\"", 1, true)
    if (tag) then
      body = "{ " .. string.gsub(line, "\"%," , "\"") .. " }"
      body = cjson.decode(body)
      break 
    end     
  end
  fr.close()
  
  local version = body.tag_name or device.swVersion
  if (version > device.swVersion) or update.force then
    print("Heap: ", node.heap(), "Updater: Version outdated, retrieving manifest list...")
    local fr = file.open("manifest.tmp", "r")
    while true do 
      line = fr.readline() 
      if (line == nil) then 
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
    fr.close()
    
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
    print("Heap: ", node.heap(), "Updater: Manifest Retrieved")
    
    local fw = file.open("device", "w")
        
    fw:writeline("local device = { name = \"".. device.name .."\",\r\nhwVersion = \"" .. device.hwVersion .. "\",\r\nswVersion = \"" .. version .. "\" }")
    fw:writeline("return device")
    fw:close()
    collectgarbage()
  else
    print("Heap: ", node.heap(), "Updater: Software version up to date, cancelling update")
    local fupdate = file.open("var_update.lua", "w")
    fupdate:writeline("update = { run = false, force = false, setFactory = false }")
    fupdate:close()
  end
  
  if file.exists("var_update.lua") then 
    file.remove("var_update.lua")
  end
  if file.exists("var_update.lc") then 
    file.remove("var_update.lc")
  end
  if file.exists("manifest.tmp") then
    file.remove("manifest.tmp")
  end
  
  print("Heap: ", node.heap(), "Updater: restarting in 3 seconds")
  tmr.create():alarm(3000, tmr.ALARM_SINGLE, function(t) node.restart() end)    
end)
conn:on("connection", function(sck)
  sck:send("GET /repos/konnected-io/"..device.name.."/releases/latest HTTP/1.1\r\nHost: api.github.com\r\nConnection: keep-alive\r\n"..
           "Accept: */*\r\nUser-Agent: ESP8266\r\n\r\n")
end)


