local files = { 'application', 'httpd', 'server', 'ssdp', 'variables' }
for i, fn in pairs(files) do
  local lua_file = fn .. ".lua"
  print(lua_file)
  if file.exists(lua_file) then
    node.compile(lua_file)
    print("compiled " .. fn .. ".lc")
    file.remove(lua_file)
  end
end
