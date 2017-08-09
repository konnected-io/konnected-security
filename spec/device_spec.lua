describe("device", function()
  local device

  setup(function()
    device = require("device")
  end)

  it("has expected properties", function()
    assert.equal(device.swVersion, "2.0.2")
    assert.equal(device.hwVersion, "2.0.0")
    assert.equal(device.name, "Security")
  end)

end)