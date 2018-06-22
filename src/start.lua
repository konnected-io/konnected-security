for fn in pairs(file.list()) do
  local fm = string.match(fn,".*%.lua-$")
  if (fm) and fm ~= "init.lua" then 
    node.compile(fm)
    file.remove(fm)
    print("Heap: ", node.heap(), "Compiled: ", fn)
  end
end
fn = nil

gpio.mode(4, gpio.OUTPUT)

if require("settings").blink ~= false then
  blinktimer = tmr.create()
  blinktimer:register(100, tmr.ALARM_SEMI, function(t)
    if gpio.read(4) == gpio.HIGH then
      t:start()
    end
    require("led_flip").flip()
  end)
else
  blinktimer = { start = function() end}
end
