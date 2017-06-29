local me = { 
  set = function (name, value)
    local fn = "var_" .. name .. '.lua'
    local f = file.open(fn, "w")
    f.writeline(name .. " = " .. value)
    f.close()
    node.compile(fn)
    file.remove(fn)
    print("Heap: ", node.heap(), "Wrote: ", fn)
    collectgarbage() 
  end
}
return me