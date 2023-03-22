local module = ...

local function httpReceiver(sck, payload)

  -- Some clients send POST data in multiple chunks.
  -- Collect data packets until the size of HTTP body meets the Content-Length stated in header
  -- this snippet borrowed from https://github.com/marcoskirsch/nodemcu-httpserver/blob/master/httpserver.lua
  if payload:find("[Cc]ontent%-[Ll]ength:") or bBodyMissing then
    if fullPayload then fullPayload = fullPayload .. payload else fullPayload = payload end
    if (tonumber(string.match(fullPayload, "%d+", fullPayload:find("[Cc]ontent%-[Ll]ength:")+16)) > #fullPayload:sub(fullPayload:find("\r\n\r\n", 1, true)+4, #fullPayload)) then
      bBodyMissing = true
      return
    else
      payload = fullPayload
      fullPayload, bBodyMissing = nil
    end
  end
  collectgarbage()

  request = require("httpd_req")(payload)
  response = require("httpd_res")()

  if request.method == 'OPTIONS' then
    print("Heap: ", node.heap(), "HTTP: ", "Options")
    response.text(sck, "", nil, nil, table.concat({
      "Access-Control-Allow-Methods: POST, GET, PUT, OPTIONS\r\n",
      "Access-Control-Allow-Headers: Content-Type\r\n"
    }))

  elseif request.path == "/" then
    print("Heap: ", node.heap(), "HTTP: ", "Index")
    response.file(sck, "http_index.html")

  elseif request.path == "/favicon.ico" then
    response.file(sck, "http_favicon.ico", "image/x-icon")

  elseif request.path == "/Device.xml" then
    response.text(sck, require("ssdp")(), "text/xml")
    print("Heap: ", node.heap(), "HTTP: ", "Discovery")

  elseif request.path == "/settings" then
    print("Heap: ", node.heap(), "HTTP: ", "Settings")
    if mqttC ~= nil  and request.method ~= "GET" then
      mqttC:on("offline", function(client)
        response.text(sck, require("server_settings")(request))
      end)
      mqttC:close()
      return
    else
      response.text(sck, require("server_settings")(request))
    end

  elseif request.path == "/device" or request.path == "/zone" then
    print("Heap: ", node.heap(), "HTTP: ", "Device")
    response.text(sck, require("server_device")(request))

  elseif request.path == "/status" then
    print("Heap: ", node.heap(), "HTTP: ", "Status")
    response.text(sck, sjson.encode(require("server_status")()))

  elseif request.path == "/lock" then
    print("Heap: ", node.heap(), "HTTP: ", "Lock")
    response.text(sck, require("server_lock")(request))

  elseif request.path == "/ota" then
    print("Heap: ", node.heap(), "HTTP: ", "OTA Update")
    if mqttC ~= nil  and request.method ~= "GET" then
        local uri = request.body.uri
        local host, path, filename = string.match(uri, "%w+://([^/]+)(/[%w%p]+/)(.*)")
        local f = file.open("ota_update.lua", "w")
        f.writeline("return function() return " .. "'"..host.."'," .. "'"..path.."'," .. "'"..filename.."'" .. " end")
        f.close()
        response.text(sck, '{ "status":"ok", "host":"'.. host ..'", "path":"'.. path ..'", "filename":"'.. filename ..'" }')
        tmr.create():alarm(1000, tmr.ALARM_SINGLE, function() print("Restarting for update") node.restart() end)
    else
      response.text(sck, require("ota")(request))
    end
  end

  sck, request, response = nil
  collectgarbage()
end

return function(sck, payload)
  package.loaded[module] = nil
  module = nil
  httpReceiver(sck, payload)
end