local module = ...


local function build_list(objects)
  local out = {}
  for key, value in pairs(objects) do
    if type(value) == 'table' then
      table.insert(out, "{")
      table.insert(out, build_list(value))
      table.insert(out, "},")
    else
      table.insert(out, key)
      table.insert(out, "=")
      if type(value) == 'string' then
        table.insert(out, "\"")
        table.insert(out, value)
        table.insert(out, "\"")
      elseif type(value) == 'boolean' then
        table.insert(out, tostring(value))
      else
        table.insert(out, value)
      end
      table.insert(out, ",")
    end
  end
  return table.concat(out)
end

local function build(objects)
  if not objects then return nil end
  local out = {}
  table.insert(out, "{")
  table.insert(out, build_list(objects))
  table.insert(out, "}")
  return table.concat(out)
end


return function(objects)
  package.loaded[module] = nil
  module = nil
  return build(objects)
end