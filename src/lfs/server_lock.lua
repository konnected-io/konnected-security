local module = ...

local log = require("log")
local lock_str = "lockmeup"

local st_locked = {state="locked"}
local st_unlocked = {state="unlocked"}

local function process(request)
  -- Load persisted config if it exists
  local device_config = file.exists("device_config.lc") and require("device_config") or {}

  if request.method == "GET" then
    if device_config.lock_sig and device_config.lock_sig ~= "" then
      return sjson.encode(st_locked)
    end
    return sjson.encode(st_unlocked)
  end

  if request.contentType == "application/json" then
    if request.method == "PUT" then

      if not request.body.pwd then
        return sjson.encode({msg="missing `pwd`"}), nil, 400
      end

      local hmac = crypto.new_hmac("SHA1", request.body.pwd)
      hmac:update(lock_str)
      local signature = encoder.toHex(hmac:finalize())

      -- if locked then try to unlock, else lock
      local setVar = require("variables_set")
      if device_config.lock_sig and device_config.lock_sig ~= ""
       then
        if signature == device_config.lock_sig then
          setVar("device_config", require("variables_build")({
            lock_sig = ""
          }))
          log.warn("Unlocked")
          return sjson.encode(st_unlocked)
        end

        log.warn("wrong pwd")
        return sjson.encode({msg="wrong pwd"}), nil, 403
      else
        setVar("device_config", require("variables_build")({
          lock_sig = signature
        }))
        log.info("Locked w/" .. signature)
        return sjson.encode(st_locked)
      end
    end
  end

  return sjson.encode({msg="bad request"}), nil, 400
end

return function(request)
  package.loaded[module] = nil
  module = nil
  return process(request)
end