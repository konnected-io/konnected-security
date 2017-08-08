describe("init", function()

  describe("when wifi is not configured yet", function()
    before_each(function()
      require("spec/nodemcu_stubs")
      nodemcu.wifi.sta.config = ""
      mock(_G.enduser_setup)

      require("init")
    end)

    after_each(function()
      nodemcu.wifi.sta.config = { ssid = 'test' }
    end)

    it("starts enduser_setup", function()
      assert.spy(_G.enduser_setup.manual).was.called_with(false)
      assert.spy(_G.enduser_setup.start).was.called()
    end)
  end)

  describe("tmr: poll for IP address", function()
    before_each(function()
      require("spec/nodemcu_stubs")
      require("init")

      spy.on(_G.gpio, 'write')
      mock(_G.enduser_setup)
    end)

    describe("when there's no IP address", function()
      before_each(function()
        nodemcu.run_tmr(900, tmr.ALARM_AUTO)
      end)

      it("does not stop enduser_setup", function()
        assert.spy(_G.enduser_setup.stop).was_not.called()
      end)
    end)

    describe("when there's an IP address", function()
      before_each(function()
        nodemcu.wifi.sta.ip = '192.168.1.100'
        nodemcu.run_tmr(900, tmr.ALARM_AUTO)
      end)

      it("stops enduser_setup and turns off the led", function()
        assert.spy(_G.enduser_setup.stop).was.called()
        assert.spy(_G.gpio.write).was.called_with(4, _G.gpio.HIGH)
      end)
    end)

  end)
end)