print("Heap: ", node.heap(), "Disabling WiFi for emissions testing...")
wifi.setmode(wifi.NULLMODE)

local bootApp = function()
  print("Heap: ", node.heap(), "Booting Konnected application")
--  require("server")
--  print("Heap: ", node.heap(), "Loaded: ", "server")
  require("application")
  print("Heap: ", node.heap(), "Loaded: ", "application")
end

bootApp()
gpio.write(4, gpio.HIGH)