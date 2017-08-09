local me = { 
  build = function (objects)
    local out = {}
    table.insert(out, "{ ")
    for i, object in pairs(objects) do
       table.insert(out, "\r\n{ pin = ")
       table.insert(out, object.pin)
       table.insert(out, " }")
      if i < #objects then
        table.insert(out, ",")
      end
    end
    table.insert(out, " }")
    return table.concat(out)
  end
}
return me