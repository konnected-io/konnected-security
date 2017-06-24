device = {
  name = "AlarmPanel",
  hwVersion = "0.1",
  swVersion = "0.1",
  discovery = {
    deviceID = "uuid:8f655392-a778-4fee-97b9-4825918" .. string.format("%x", node.chipid()),
    deviceType = "urn:schemas-konnected-io:device:AlarmPanel:1"
  }
}

function variables_set(name, value)
  local fnc = string.match(name, ".*%.")
  if fnc then
    local fnl = string.len(fnc) - 1
    if fnl > 0 then
      variables_set(string.sub(fnc, 1, fnl), "\"{}\"")
    end
  end
  local fn = "var_" .. name
  local f = file.open(fn, "w")
  f.writeline(name .. " = " .. value)
  f.close()
  print('Wrote ' .. fn)
  variables_load()
  collectgarbage()
end

function variables_load()
  local fl = file.list()
  local tk = {}
  for fn in pairs(fl) do
    local fm = string.match(fn, "var_.*")
    if fm then table.insert(tk, fm) end
  end
  table.sort(tk)
  for _, fn in pairs(tk) do
    dofile(fn)
  end
end

variables_load()
