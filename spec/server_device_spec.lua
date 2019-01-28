describe("server_device", function()
  local server, response

  setup(function()
    _G.sjson = require("cjson")
    _G.blinktimer = mock({ start = function() end })
    require("spec/nodemcu_stubs")
  end)

  describe("updating a device pin state", function()
    before_each(function()
      spy.on(_G.gpio, 'write')
    end)

    after_each(function()
      nodemcu.tmrs = {}
    end)

    describe("a normal switch", function()
      before_each(function()
        response = require("server_device")({
          contentType = "application/json",
          method = "PUT",
          body = {
            pin = 1,
            state = 1
          }
        })
      end)

      it("updates the state of the pin", function()
        assert.spy(_G.gpio.write).was.called_with(1, 1)
      end)

      it("responds with the new pin state", function()
        assert.are.equal(response, sjson.encode({ pin = 1, state = 1 }))
      end)

    end)

    describe("a momentary switch", function()
      before_each(function()
        response = require("server_device")({
          contentType = "application/json",
          method = "PUT",
          body = {
            pin = 1,
            state = 1,
            momentary = 500
          }
        })
      end)

      it("updates the state of the pin on and then off", function()
        assert.are.equal(#_G.gpio.write.calls, 1)
        assert.spy(_G.gpio.write).was.called_with(1, 1)
        nodemcu.run_tmr(500, tmr.ALARM_SINGLE) -- wait 500ms
        assert.are.equal(#_G.gpio.write.calls, 2)
        assert.spy(_G.gpio.write).was.called_with(1, 0)
      end)

      it("responds with the new pin state", function()
        assert.are.equal(response, sjson.encode({ pin = 1, state = 1 }))
      end)
    end)

    describe("a repeating switch", function()
      before_each(function()
        response = require("server_device")({
          contentType = "application/json",
          method = "PUT",
          body = {
            pin = 1,
            state = 1,
            momentary = 500,
            times = 2,
            pause = 200
          }
        })
      end)

      it("updates the state of the pin on and then off", function()
        assert.are.equal(#_G.gpio.write.calls, 1)
        assert.spy(_G.gpio.write).was.called_with(1, 1)
        nodemcu.run_tmr(500, tmr.ALARM_SINGLE, true) -- wait 500ms
        assert.are.equal(#_G.gpio.write.calls, 2)
        assert.spy(_G.gpio.write).was.called_with(1, 0)
        nodemcu.run_tmr(200, tmr.ALARM_SINGLE, true) -- wait 200ms
        assert.are.equal(#_G.gpio.write.calls, 3)
        assert.spy(_G.gpio.write).was.called_with(1, 1)
        nodemcu.run_tmr(500, tmr.ALARM_SINGLE, true) -- wait 500ms
        assert.are.equal(#_G.gpio.write.calls, 4)
        assert.spy(_G.gpio.write).was.called_with(1, 0)
      end)

      it("responds with the new pin state", function()
        assert.are.equal(response, sjson.encode({ pin = 1, state = 1 }))
      end)
    end)

    describe("multiple switches", function()
      before_each(function()
        response = require("server_device")({
          contentType = "application/json",
          method = "PUT",
          body = {{
            pin = 1,
            state = 1
          },{
            pin = 2,
            state = 1
          }}
        })
      end)

      it("updates the state of the pin", function()
        assert.spy(_G.gpio.write).was.called_with(1, 1)
        assert.spy(_G.gpio.write).was.called_with(2, 1)
      end)

      it("responds with the new pin state", function()
        assert.are.equal(response, sjson.encode({{ pin = 1, state = 1 },{ pin = 2, state = 1}}))
      end)
    end)

  end)
end)
