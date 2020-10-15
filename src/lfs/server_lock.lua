local module = ...

local lock_str = "lockmeup"

local st_locked = {state="locked"}
local st_unlocked = {state="unlocked"}

local function process(request)
  -- Load persisted config if it exists
  local device_config = file.exists("device_config.lc") and require("device_config") or {}

  if request.method == "GET" then
    print("Heap:", node.heap(), "Settings Lock status requested")
    if device_config.lock_sig and device_config.lock_sig ~= "" then
      return sjson.encode(st_locked)
    end
    return sjson.encode(st_unlocked)
  end

  if request.contentType == "application/json" then
    if request.method == "PUT" then
      print("Heap:", node.heap(), "Settings Lock update requested")

      if not request.body.pwd then
        return sjson.encode({msg="missing `pwd` field"}), nil, 400
      end

      local signature = encoder.toHex(crypto.hmac("SHA1", lock_str, request.body.pwd))

      -- if locked then try to unlock, else lock
      local setVar = require("variables_set")
      if device_config.lock_sig and device_config.lock_sig ~= ""
       then
        if signature == device_config.lock_sig then
          setVar("device_config", require("variables_build")({
            lock_sig = ""
          }))
          print("Heap:", node.heap(), "Unlocked settings")
          return sjson.encode(st_unlocked)
        end

        print("Heap:", node.heap(), "wrong unlock password")
        return sjson.encode({msg="incorrect value for pwd"}), nil, 403
      else
        setVar("device_config", require("variables_build")({
          lock_sig = signature
        }))
        print("Heap:", node.heap(), "Settings locked w/" .. signature)
        return sjson.encode(st_locked)
      end
    end
  end

  return sjson.encode({msg="unsupported request"}), nil, 400
end

return function(request)
  package.loaded[module] = nil
  module = nil
  return process(request)
end