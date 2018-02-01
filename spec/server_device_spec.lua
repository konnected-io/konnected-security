describe("server_device", function()
  local server, response

  setup(function()
    _G.sjson = require("sjson")
    _G.blinktimer = mock({ start = function() end })
    server = require("server_device")
    require("spec/nodemcu_stubs")
  end)

  describe("updating a device pin state", function()
    before_each(function()
      spy.on(_G.gpio, 'write')
      response = mock({ send = function(str) end })
    end)

    describe("a normal switch", function()
      before_each(function()
        server.process({
          contentType = "application/json",
          method = "PUT",
          body = {
            pin = 1,
            state = 1
          }
        }, response)
      end)

      it("updates the state of the pin", function()
        assert.spy(_G.gpio.write).was.called_with(1, 1)
      end)

      it("responds with the new pin state", function()
        assert.stub(response.send).was.called_with(sjson.encode({ pin = 1, state = 1 }))
      end)

    end)

    describe("a momentary switch", function()
      before_each(function()
        server.process({
          contentType = "application/json",
          method = "PUT",
          body = {
            pin = 1,
            state = 1,
            momentary = 500
          }
        }, response)
      end)

      it("updates the state of the pin on and then off", function()
        assert.are.equal(#_G.gpio.write.calls, 1)
        assert.spy(_G.gpio.write).was.called_with(1, 1)
        nodemcu.run_tmr(500, tmr.ALARM_SINGLE) -- wait 500ms
        assert.are.equal(#_G.gpio.write.calls, 2)
        assert.spy(_G.gpio.write).was.called_with(1, 0)
      end)

      it("responds with the new pin state", function()
        assert.stub(response.send).was.called_with(sjson.encode({ pin = 1, state = 0 }))
      end)
    end)
  end)
end)
