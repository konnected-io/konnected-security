nodemcu = {
  tmrs = {},
  run_tmr = function(interval, type, reset)
    for i,v in pairs(nodemcu.tmrs) do
      if v.interval == interval and v.type == type then
        print('Running tmr ' .. type .. ', interval:', interval )
        if type == tmr.ALARM_SINGLE and reset then
          table.remove(nodemcu.tmrs, i)
        end
        v.fn({stop = function() end, start = function() end, unregister = function() end})
      end
    end
  end,
  wifi = {
    eventmon = {},
    sta = {
      config = { ssid = 'test' },
      ip = nil
    }
  },
  upnp_responder = nil
}

_G.node = {
  heap = function() return 0 end,
  chipid = function() return 0 end,
  restart = function() end,
  info = function() return 1, 5, 4 end
}

_G.tmr = {
  ALARM_SINGLE = 'ALARM_SINGLE',
  ALARM_AUTO = 'ALARM_AUTO',
  ALARM_SEMI= 'ALARM_SEMI',
  create = function()
    return {
      alarm = function(_, interval, type, fn)
        table.insert(nodemcu.tmrs, {
          interval = interval,
          type = type,
          fn = fn
        })
      end,
      register = function(_, interval, type, fn)
        table.insert(nodemcu.tmrs, {
          interval = interval,
          type = type,
          fn = fn
        })
      end,
      unregister = function() end,
      start = function() end,
      stop = function() end
    }
  end
}

_G.file = {
  list = function() return {} end,
  exists = function() end
}

_G.gpio = {
  HIGH = 1,
  LOW = 0,
  mode = function() end,
  read = function() end,
  write = function() end,
  trig = function() end
}

_G.wifi = {
  eventmon = {
    STA_DISCONNECTED = 'STA_DISCONNECTED',
    register = function(key, fn)
      print(key)
      nodemcu.wifi.eventmon[key] = fn
    end,
    unregister = function(key)
      nodemcu.wifi.eventmon[key] = nil
    end,
    reason = {
      AUTH_EXPIRE = 2
    }
  },

  sta = {
    getip = function() return nodemcu.wifi.sta.ip end,
    getconfig = function() return nodemcu.wifi.sta.config end,
    getmac = function() return 'aa:bb:cc:dd:ee:ff' end
  }
}

_G.enduser_setup = {
  start = function() end,
  stop = function() end,
  manual = function() end
}

_G.net = {
  multicastJoin = function() end,
  createServer = function()
    return {
      listen = function() end,
      on = function() end
    }
  end,
  createUDPSocket = function()
    return {
      listen = function() end,
      on = function() end
    }
  end
}

_G.http = {
  get = function() end,
  put = function() end,
  post = function() end
}

_G.unpack = function(t, i)
  i = i or 1
  if t[i] ~= nil then
    return t[i], unpack(t, i + 1)
  end
end

-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    else
      print(formatting .. tostring(v))
    end
  end
end