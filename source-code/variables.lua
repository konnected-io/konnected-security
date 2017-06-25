
function variables_set(name, value)
  local fnc = string.match(name, ".*%.")
  local fn = "var_" .. name .. '.lua'
  local f = file.open(fn, "w")
  f.writeline(name .. " = " .. value)
  f.close()
  node.compile(fn)
  file.remove(fn)
  print("Heap: ", node.heap(), "Wrote: ", fn)
  variables_load()
  collectgarbage()
end

local fl = file.list()
for fn in pairs(fl) do
  local fm = string.match(fn,"var_.*")
  if (fm) then 
    dofile(fm) 
    print("Heap: ", node.heap(), "Loaded: ", fn)
  end	
end