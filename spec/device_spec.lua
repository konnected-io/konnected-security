describe("device", function()
  local device

  setup(function()
    require("spec/nodemcu_stubs")
    device = require("device")
  end)

  it("has expected properties", function()
    assert.equal(device.swVersion, "2.0.4")
    assert.equal(device.hwVersion, "2.0.0")
    assert.equal(device.name, "Security")
  end)

end)