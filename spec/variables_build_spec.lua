describe("variables_build", function()
  local variables_build

  local function trim(s)
    return s:gsub('%c','')
  end

  setup(function()
    variables_build = require('variables_build')
  end)

  it("returns a string that makes a lua list", function()
    local str = variables_build.build({{pin=1},{pin=2}})
    assert.same("{ { pin = 1, },{ pin = 2, },}", trim(str) )
  end)

  it("allows for any values", function()
    local expected = {{pin=1,trigger=1},{pin=2,trigger=0}}
    local str = variables_build.build(expected)
    local result = loadstring("return " .. str)()
    assert.same(expected, result)
  end)
end)

