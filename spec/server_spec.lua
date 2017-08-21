describe("server", function()
  local conn, response
  local do_upnp_broadcast = function()
    nodemcu.upnp_responder(conn, [[M-SEARCH * HTTP/1.1
      MX: 4
      MAN: "ssdp:discover"
      HOST:239.255.255.250:1900
      ST: urn:schemas-konnected-io:device:Security:1
    ]])
  end

  setup(function()
    require("spec/nodemcu_stubs")
    _G.net.createServer = function()
      return {
        listen = function() end,
        on = function(_, event, fn)
          if event == "receive" then
            nodemcu.upnp_responder = fn
          end
        end
      }
    end
  end)

  before_each(function()
    conn = mock({send = function(_, resp) response = resp end})
    nodemcu.wifi.sta.ip = '192.168.1.100'
    require("server")
  end)

  after_each(function()
    response = nil
  end)

  describe("a ssdp discovery broadcast", function()
    it("responds to a Konnected device with its IP address and port", function()
      do_upnp_broadcast()
      assert.stub(conn.send).was.called()
      assert.equal(response:match("LOCATION: ([%w%p]*)"), "http://192.168.1.100:8000/Device.xml")
    end)

    it("responds correctly when the IP address changes", function()
      do_upnp_broadcast()
      assert.equal(response:match("LOCATION: ([%w%p]*)"), "http://192.168.1.100:8000/Device.xml")
      nodemcu.wifi.sta.ip = '192.168.1.200'
      do_upnp_broadcast()
      assert.equal(response:match("LOCATION: ([%w%p]*)"), "http://192.168.1.200:8000/Device.xml")
    end)

    it("doesn't respond to other devices", function()
      nodemcu.upnp_responder(conn, [[M-SEARCH * HTTP/1.1
        MX: 4
        MAN: "ssdp:discover"
        HOST:239.255.255.250:1900
        ST: urn:schemas-upnp-org:device:MediaServer:1
      ]])

      assert.stub(conn.send).was_not.called()
    end)
  end)
end)