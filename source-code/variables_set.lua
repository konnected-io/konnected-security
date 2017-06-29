local me = { 
  set = function (name, value)
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
}
return me