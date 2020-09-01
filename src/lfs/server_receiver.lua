local module = ...

local log = require("log")

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

  local request = require("httpd_req")(payload)
  local response = require("httpd_res")()

  if request.method == 'OPTIONS' then
    log.info("HTTP: ", "Options")
    response.text(sck, "", nil, nil, table.concat({
      "Access-Control-Allow-Methods: POST, GET, PUT, OPTIONS\r\n",
      "Access-Control-Allow-Headers: Content-Type\r\n"
    }))
    return
  end

  if request.path == "/" then
    log.info("HTTP: ", "Index")
    response.file(sck, "http_index.html")

  elseif request.path == "/favicon.ico" then
    response.file(sck, "http_favicon.ico", "image/x-icon")

  elseif request.path == "/Device.xml" then
    response.text(sck, require("ssdp")(), "text/xml")
    log.info("HTTP: ", "Discovery")

  elseif request.path == "/settings" then
    log.info("HTTP: ", "Settings")
    response.text(sck, require("server_settings")(request))

  elseif request.path == "/device" then
    log.info("HTTP: ", "Device")
    response.text(sck, require("server_device")(request))

  elseif request.path == "/status" then
    log.info("HTTP: ", "Status")
    response.text(sck, sjson.encode(require("server_status")()))

  elseif request.path == "/lock" then
    log.info("HTTP: ", "Lock")
    response.text(sck, require("server_lock")(request))

  elseif request.path == "/ota" then
    log.info("HTTP: ", "OTA Update")
    response.text(sck, require("ota")(request))
  end

  sck, request, response = nil
  collectgarbage()
end

return function(sck, payload)
  package.loaded[module] = nil
  module = nil
  httpReceiver(sck, payload)
end