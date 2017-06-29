gpio.mode(4, gpio.OUTPUT)

for fn in pairs(file.list()) do
  local fm = string.match(fn,"var_.*")
  if (fm) then 
    dofile(fm) 
    print("Heap: ", node.heap(), "Loaded: ", fn)
  end
end

blinktimer = tmr.create()
blinktimer:register(100, tmr.ALARM_SEMI, function(t)
  if gpio.read(4) == gpio.HIGH then
    t:start()
  end
  require("led_flip").flip()
end)
