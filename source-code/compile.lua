for fn in pairs(file.list()) do
  local fm = string.match(fn,".*%.lua")
  if (fm) and fm ~= "init.lua" then 
    node.compile(fm)
    file.remove(fm)
    print("Heap: ", node.heap(), " Compiled & removed ", fm)
  end	
end