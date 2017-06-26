for fn in pairs(file.list()) do
  local fm = string.match(fn,"(.*%.tmp)")
  if (fm) then 
    file.remove(fm)
  end
end
for fn in pairs(file.list()) do
  local fm = string.match(fn,"(.*%.lua)")
  if (fm) and fm ~= "init.lua" then 
    if string.sub(fn, -4) ~= ".tmp" then
      node.compile(fm)
      file.remove(fm)
    print("Heap: ", node.heap(), " Compiled & removed ", fn)
    end
  end
end