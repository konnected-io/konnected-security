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
    gpio.write(4, gpio.LOW)
    t:start()
  else
    gpio.write(4, gpio.HIGH)
  end
end)

timeout = tmr.create()
timeout:register(15000, tmr.ALARM_SEMI, node.restart)
