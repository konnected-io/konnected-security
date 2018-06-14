describe("variables_build", function()
  local variables_build

  local function trim(s)
    return s:gsub('%c','')
  end

  it("returns a string that makes a lua list", function()
    local str = require('variables_build')({{pin=1},{pin=2}})
    assert.same("{ { pin = 1, },{ pin = 2, },}", trim(str) )
  end)

  it("allows for any values", function()
    local expected = {{pin=1,trigger=1},{pin=2,trigger=0}}
    local str = require('variables_build')(expected)
    local result = load("return " .. str)()
    assert.same(expected, result)
  end)
end)

