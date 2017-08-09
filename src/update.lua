print("Heap: ", node.heap(), "Updater: running..")
function findAttr(line) 
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

tmr.create():alarm(180, tmr.ALARM_AUTO, function(t) 
  if gpio.read(4) == gpio.HIGH then
    gpio.write(4, gpio.LOW)
  else
    gpio.write(4, gpio.HIGH)
  end
end)

if file.exists("manifest") then
  require("update_process")
else
  require("update_manifest")
end


