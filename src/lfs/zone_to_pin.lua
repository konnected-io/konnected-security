local zoneMap = {
  [1] = 1,
  [2] = 2,
  [3] = 5,
  [4] = 6,
  [5] = 7,
  [6] = 9,
  ["out"] = 8,
}

local function zoneToPin(zone)
  -- handle strings or numbers
  return zoneMap[zone] or zoneMap[tonumber(zone)]
end

return function(zone)
  -- we won't unload this since it's small and frequently called...
  return zoneToPin(zone)
end
