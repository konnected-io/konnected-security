-- This code is adapted from https://github.com/rxi/log.lua
local log = { _version = "0.1.0" }

log.usecolor = true
log.level = "debug"


local modes = {
  { name = "debug", color = "\27[36m", },
  { name = "info",  color = "\27[32m", },
  { name = "warn",  color = "\27[33m", },
  { name = "error", color = "\27[31m", },
}


local levels = {}
for i, v in ipairs(modes) do
  levels[v.name] = i
end

local _tostring = tostring

local tostring = function(...)
  local t = {}
  for i = 1, select('#', ...) do
    local x = select(i, ...)
    t[#t + 1] = _tostring(x)
  end
  return table.concat(t, " ")
end


for i, x in ipairs(modes) do
  local nameupper = x.name:upper()
  log[x.name] = function(...)

    -- Return early if we're below the log level
    if i < levels[log.level] then
      return
    end

    local msg = tostring(...)

    -- usec is not exact as rollover occurs but it works for reference purposes
    local sec = tmr.time()
    local usec = tmr.now() % 1000000

    -- Output to console
    print(string.format("%s[%-6s%s.%s, %s]%s: %s",
                        log.usecolor and x.color or "",
                        nameupper,
                        sec, usec,
                        node.heap(),
                        log.usecolor and "\27[0m" or "",
                        msg))

  end
end

return log