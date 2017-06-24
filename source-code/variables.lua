--this might be worth moving to server.lua and localizing it there, since it's not used anywhere else
function variables_set(name,value) 
	local fnc = string.match(name,".*%.")
	local fn = "var_"..name
	local f = file.open(fn, "w")
	f.writeline(name.." = "..value)
	f.close()
	dofile(fn)
	print("Heap: ", node.heap(), "Wrote: ", fn)
	collectgarbage()
end

local fl = file.list()
for fn in pairs(fl) do
	local fm = string.match(fn,"var_.*")
	if (fm) then 
		dofile(fm) 
		print("Heap: ", node.heap(), "Loaded: ", fn)
	end	
end

