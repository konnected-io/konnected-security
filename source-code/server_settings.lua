local restartTimer = tmr.create()
restartTimer:register(2000, tmr.ALARM_SINGLE, function() node.restart() end)
local me = {
	process = function (request, response) 
		if request.method == "GET" then
			if request.query then
			  request.query.update = request.query.update or "false"
			  request.query.force = request.query.force or "false"
			  request.query.setfactory = request.query.setfactory or "false"
			  request.query.restart = request.query.restart or "false"
			  request.query.restore = request.query.restore or "false"
			end
			if request.query.update == "true" then 
			  require("variables_set").set("update_init", "{ force = "..request.query.force..", setfactory = "..request.query.setfactory.." }")
			  restartTimer:start()
			end  
			if request.query.restart == "true" then
			  restartTimer:start()
			end
      if request.query.restore == "true" then
			  node.restore()
        restartTimer:start()
			end
			response.send("")
    end
    if request.contentType == "application/json" then
			if request.method == "PUT" then
			  local var = require("variables_set")
			  var.set("smartthings", table.concat({ "{ token = \"", request.body.token, "\",\r\n apiUrl = \"", request.body.apiUrl, "\" }" }))
			  var.set("sensors",   require("variables_build").build(request.body.sensors))
			  var.set("actuators", require("variables_build").build(request.body.actuators))

			  print('Settings updated! Restarting in 5 seconds...')
			  restartTimer:start()
			  
			  response.send("")
			end
    end
  end
}
return me