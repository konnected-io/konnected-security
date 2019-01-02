describe("variables_build", function()
  local variables_build

  local function trim(s)
    return s:gsub('%c','')
  end

  setup(function()
    _G.sjson = require("cjson")
  end)

  it("returns a string that makes a lua list of lists", function()
    local thing = {{pin=1},{pin=2}}
    local str = require('variables_build')(thing)
    assert.same(thing, load("return " .. str)())
  end)

  it("returns a sting that makes a lua list", function()
    local thing = {foo="bar", baz=5}
    local str = require('variables_build')(thing)
    assert.same(thing, load("return " ..str)())
  end)

  it("allows for any values", function()
    local expected = {{pin=1,trigger=1},{pin=2,trigger=0}}
    local str = require('variables_build')(expected)
    local result = load("return " .. str)()
    assert.same(expected, result)
  end)

  it("allows for boolean and nil values", function()
    local thing = {happy=true, tired=false, hungry=nil}
    local str = require('variables_build')(thing)
    assert.same(thing, load("return " ..str)())
  end)

  it("checks for nil", function()
    local thing
    local str = tostring(require('variables_build')(thing))
    assert.same(thing, load("return " ..str)())
  end)
end)

