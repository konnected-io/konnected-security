function variables_set(name, value)
  local fnc = string.match(name, ".*%.")
  local fn = "var_" .. name .. '.lua'
  local f = file.open(fn, "w")
  f.writeline(name .. " = " .. value)
  f.close()
  node.compile(fn)
  file.remove(fn)
  print("Heap: ", node.heap(), "Wrote: ", fn)
  collectgarbage()
end

for fn in pairs(file.list()) do
  local fm = string.match(fn,"var_.*")
  if (fm) then 
    dofile(fm) 
    print("Heap: ", node.heap(), "Loaded: ", fn)
  end	
end