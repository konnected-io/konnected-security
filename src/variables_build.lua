local me = { 
  build = function (objects)
    local out = {}
    table.insert(out, "{ ")
    for i, object in pairs(objects) do
      table.insert(out, "\r\n{ ")
      for key, value in pairs(object) do
       table.insert(out, key .. " = " .. value .. ", ")
      end
      table.insert(out, "},")
    end
    table.insert(out, "}")
    return table.concat(out)
  end
}
return me