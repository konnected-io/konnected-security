local device = require("device")
local update = require("update_init")
local repo = "konnected-io/konnected-security"
print("Heap: ", node.heap(), "Updater: Checking version")

local download_new_manifest = function(tag_name)
  http.get(
    "https://github.com/" .. repo .. "/raw/" .. tag_name .. "/src/manifest.json",
    "Accept-Encoding: deflate\r\n",
    function(code, data)
      local new_manifest = cjson.decode(data)
      print("Heap: ", node.heap(), "downloaded updated manifest.json")
      local file_size = file.list()['manifest.json']
      local current_manifest = {}

      -- open the existing manifest.json on the device for comparing file SHAs
      if file.open("manifest.json") then
        current_manifest = cjson.decode(file.read(file_size))
        file.close()
      end

      -- open a new manifest temp file for writing
      local fw = file.open("manifest", "w")
      fw.writeline("manifest = { ")

      -- remove manifest.json and updated_at from manifest, these are special entries
      new_manifest["src/manifest.json"] = nil
      new_manifest["updated_at"] = nil

      for key, sha in pairs(new_manifest) do
        if sha ~= current_manifest[key] then
          print("Heap: ", node.heap(), "Needs update:", key)
          local fname = string.match(key, '/([%w%p]+)$')

          fw.writeline(table.concat({
            "{ host = \"github.com\", port = \"443\", path = \"/", repo, "/raw/",
            tag_name, "/", key, "\", filenm = \"", fname, "\", checksum = \"".. sha .."\" },"
          }))
        end
      end

      -- always download the new manifest.json after everything else
      fw.writeline(table.concat({
        "{ host = \"github.com\", port = \"443\", path = \"/", repo, "/raw/",
        tag_name, "/src/manifest.json\", filenm = \"manifest.json\" }"
      }))
      fw.writeline("}")
      fw.close()
      collectgarbage()
      print("Heap: ", node.heap(), "Updater:", "restarting in 3 seconds")
      tmr.create():alarm(3000, tmr.ALARM_SINGLE, function() node.restart() end)
    end
  )
end

local compare_github_release = function(tag_name)
  local restart = false
  if tag_name then
    local version = tag_name or device.swVersion
    version = string.match(version, "[%d%.]+")
    print("Heap: ", node.heap(), "Updater: Current version", device.swVersion)
    print("Heap: ", node.heap(), "Updater: New version", version)

    if (version > device.swVersion) then
      collectgarbage()
      print("Heap: ", node.heap(), "Updater:", "Version outdated, retrieving manifest list")
      tmr.create():alarm(1000, tmr.ALARM_SINGLE, function() download_new_manifest(tag_name) end)
    else
      print("Heap: ", node.heap(), "Updater:", "Software version up to date, cancelling update")
      local fupdate = file.open("var_update.lua", "w")
      fupdate:writeline("update = { run = false, force = false, setFactory = false }")
      fupdate:close()
      restart = true
    end
  else
    print("Error connecting to GitHub")
    restart = true
  end

  if restart then
    if file.exists("update_init.lua") then
      file.remove("update_init.lua")
    end
    if file.exists("update_init.lc") then
      file.remove("update_init.lc")
    end

    print("Heap: ", node.heap(), "Updater:", "restarting in 3 seconds")
    tmr.create():alarm(3000, tmr.ALARM_SINGLE, function() node.restart() end)
  end
end

local check_for_version_update = function()
  http.get(
    "https://api.github.com/repos/" .. repo .. "/releases/latest",
    "Accept-Encoding: deflate\r\n",
    function(code, data)
      local latest_release_tag
      if code == 200 then
        latest_release_tag = cjson.decode(data)["tag_name"]
      end
      compare_github_release(latest_release_tag)
    end
  )
end

if update.force then
  tag_name = update.commitish or 'master'
  print("Heap: ", node.heap(), "Forcing software update to branch/tag: ", tag_name)
  download_new_manifest(tag_name)
else
  check_for_version_update()
end
