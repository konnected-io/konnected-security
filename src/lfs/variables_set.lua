local module = ...

local log = require("log")

local function set(name, value)
  if not value then return end
  local fn = name .. '.lua'
  local f = file.open(fn, "w")
  f.writeline("local " .. name .. " = " .. value)
  f.writeline("return " .. name)
  f.close()
  node.compile(fn)
  file.remove(fn)
  log.info("Wrote: ", fn)
  package.loaded[name] = nil
  collectgarbage()
end

return function(name, value)
  if package.loaded[module] then
    package.loaded[module] = nil
  end
  module = nil
  set(name, value)
end