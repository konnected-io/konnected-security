describe("application", function()
  local app, cb

  local real_require = require
  local mock_require = function(name)
    if name == "actuators" then
      return {{pin=1,trigger=1} }
    elseif name == "settings" then
      return {apiUrl = "http://192.168.1.123:8123/api/konnected", token = "secrettoken"}
    else
      return real_require(name)
    end
  end


  setup(function()
    _G.sjson = require("cjson")
    _G.blinktimer = {
      start = function() end
    }
    require("spec/nodemcu_stubs")
    _G.require = mock_require
    app = require("application")
  end)


  describe("get initial state of actuators on boot", function()
    before_each(function()
      spy.on(http, 'get')
      spy.on(gpio, 'write')
      nodemcu.run_tmr(200, tmr.ALARM_AUTO) -- wait 500ms
    end)

    after_each(function()
      http.get:clear()
    end)

    it("doesn't return anything", function()
      assert.equal(application, nil)
    end)

    it("calls to get the initial state of actuator", function()
      assert.spy(http.get).was.called_with(
        "http://192.168.1.123:8123/api/konnected/device/aabbccddeeff?pin=1",
        "Authorization: Bearer secrettoken\r\nAccept: application/json\r\n",
        match._ -- callback
      )
    end)

    it("processes a successful response", function()
      cb = http.get.calls[1].vals[3] -- callback is the 3rd argument
      cb(200, "{\"pin\":1,\"state\":1}")
      assert.spy(gpio.write).was.called_with(1,1)
    end)

    it("processes a successful response in strings", function()
      cb(200, "{\"pin\":\"1\",\"state\":\"1\"}")
      assert.spy(gpio.write).was.called_with(1,1)
    end)

    it("processes a response missing state", function()
      cb(200, "{\"pin\":\"1\"}")
      assert.spy(gpio.write).was.called_with(1,0)
    end)

    it("processes a response with null state", function()
      cb(200, "{\"pin\":\"1\",\"state\":null}")
      assert.spy(gpio.write).was.called_with(1,0)
    end)

  end)

end)