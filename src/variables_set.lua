local module = ...
local function set(name, value)
  local fn = name .. '.lua'
  local f = file.open(fn, "w")
  f.writeline("local " .. name .. " = " .. value)
  f.writeline("return " .. name)
  f.close()
  node.compile(fn)
  file.remove(fn)
  print("Heap: ", node.heap(), "Wrote: ", fn)
  collectgarbage()
end

return function(name, value)
  if package.loaded[module] then
    package.loaded[module] = nil
  end
  module = nil
  set(name, value)
end