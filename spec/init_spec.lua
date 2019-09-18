describe("init", function()
  local mock_timer

  before_each(function()
    mock(_G.enduser_setup)
    mock_timer = mock({
      register = function() end,
      alarm = function() end,
      unregister = function() end,
      start = function() end
    })
  end)

  describe("when wifi is not configured yet", function()
    before_each(function()
      require("spec/nodemcu_stubs")
      nodemcu.wifi.sta.config = ""
      mock(_G.enduser_setup)

      dofile("../init.lua")
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
      stub(_G.tmr, 'create').returns(mock_timer)
      dofile("../init.lua")

      spy.on(_G.gpio, 'write')
      spy.on(wifi.eventmon, 'unregister')
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

      it("stops enduser_setup", function()
        assert.spy(_G.enduser_setup.stop).was.called()
      end)

      it("turns off the led", function()
        assert.spy(_G.gpio.write).was.called_with(4, _G.gpio.HIGH)
      end)

      it("unregisters the failsafeTimer and wifiFailTimer", function()
        assert.stub(mock_timer.unregister).was.called()
        assert.are.equal(#mock_timer.unregister.calls, 2) -- wifiFailTimer and failSafeTimer
      end)

      it("unregisters the wifi disconnect eventmon", function()
        assert.spy(wifi.eventmon.unregister).was.called_with(wifi.eventmon.STA_DISCONNECTED)
      end)
    end)

  end)

  describe("when receiving a disconnect signal", function()
    before_each(function()
      require("spec/nodemcu_stubs")
      stub(_G.tmr, 'create').returns(mock_timer)
      dofile("../init.lua")
      spy.on(wifi.eventmon, 'unregister')

      nodemcu.wifi.eventmon['STA_DISCONNECTED']({SSID = "test", BSSID = "test", reason = "201"})
    end)

    it("starts the wifiFailTimer", function()
      assert.stub(mock_timer.start).was.called()
    end)

    describe("after failing the wifiFailTimer", function()
      before_each(function()
        nodemcu.run_tmr(30000, tmr.ALARM_SINGLE)
      end)

      it("starts wifi setup", function()
        assert.spy(_G.enduser_setup.manual).was.called_with(false)
        assert.spy(_G.enduser_setup.start).was.called()
      end)

      it("starts the failsafeTimer", function()
        assert.stub(mock_timer.start).was.called()
      end)

      it("unregisters the wifi disconnect eventmon", function()
        assert.spy(wifi.eventmon.unregister).was.called_with(wifi.eventmon.STA_DISCONNECTED)
      end)

      it("unregisters the wifiFailTimer", function()
        assert.stub(mock_timer.unregister).was.called()
        assert.are.equal(#mock_timer.unregister.calls, 1)
      end)

      describe("after failing the failsafeTimer", function()
        before_each(function()
          spy.on(node, 'restart')
          nodemcu.run_tmr(300000, tmr.ALARM_SINGLE)
        end)

        it("restarts", function()
          assert.spy(node.restart).was.called()
        end)
      end)

      describe("after connecting", function()
        before_each(function()
          nodemcu.wifi.sta.ip = '192.168.1.100'
          nodemcu.run_tmr(900, tmr.ALARM_AUTO)
        end)

        it("it stops the wifiFailTimer and failSafeTimer", function()
          assert.stub(mock_timer.unregister).was.called()
          assert.are.equal(#mock_timer.unregister.calls, 2) -- wifiFailTimer and failSafeTimer
        end)

        it("unregisters the wifi disconnect eventmon", function()
          assert.spy(wifi.eventmon.unregister).was.called_with(wifi.eventmon.STA_DISCONNECTED)
        end)
      end)
    end)

    describe("after connecting", function()
      before_each(function()
        nodemcu.wifi.sta.ip = '192.168.1.100'
        nodemcu.run_tmr(900, tmr.ALARM_AUTO)
      end)

      it("it stops the wifiFailTimer and failSafeTimer", function()
        assert.stub(mock_timer.unregister).was.called()
        assert.are.equal(#mock_timer.unregister.calls, 2) -- wifiFailTimer and failSafeTimer
      end)

      it("unregisters the wifi disconnect eventmon", function()
        assert.spy(wifi.eventmon.unregister).was.called_with(wifi.eventmon.STA_DISCONNECTED)
      end)
    end)
  end)
end)