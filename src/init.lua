print("Heap: ", node.heap(), "Initializing Konnected (" .. string.gsub(wifi.sta.getmac(), ":", "") .. ")")

-- load the application in LFS if needed
if node.flashindex("_init") == nil then
  node.LFS.reload("lfs.img")
end

pcall(node.flashindex("_init"))
require("start")
print("Heap: ", node.heap(), "Application Version: ", require("device").swVersion)

-- hack to ensure pin D8 stays low after boot so it can be used with a high-level trigger relay
gpio.mode(8, gpio.OUTPUT)
gpio.write(8, gpio.LOW)

dofile("wifi.lua")