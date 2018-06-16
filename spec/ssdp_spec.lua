describe("ssdp", function()
  local upnp_response

  describe("the UPnP response XML", function()
    before_each(function()
      require("spec/nodemcu_stubs")
      nodemcu.wifi.sta.ip = '192.168.1.100'
      upnp_response = require("ssdp")()
    end)

    it("contains the IP address and port", function()
      assert.is.truthy(upnp_response:find("<URLBase>http://" .. nodemcu.wifi.sta.ip .. ":8000</URLBase>"))
    end)

    it("contains the updated IP address after it changes", function()
      assert.is.truthy(upnp_response:find("<URLBase>http://" .. nodemcu.wifi.sta.ip .. ":8000</URLBase>"))
      nodemcu.wifi.sta.ip = '192.168.1.200'
      upnp_response = require("ssdp")()
      assert.is.truthy(upnp_response:find("<URLBase>http://" .. nodemcu.wifi.sta.ip .. ":8000</URLBase>"))
    end)
  end)

end)