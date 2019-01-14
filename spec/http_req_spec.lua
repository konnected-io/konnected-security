describe("http_req", function()
  local handler, raw, req

  setup(function()
    _G.sjson = require("cjson")
  end)

  describe("GET request", function()
    before_each(function()
      raw = "GET /device?foo=one&bar=two HTTP/1.1\r\nHost: example.com\r\nUser-Agent: curl/7.54.0\r\nAccept: */*\r\n\r\nhi"
      req = require("httpd_req")(raw)
    end)

    it("parses the request method", function()
      assert.are.equal(req.method,'GET')
    end)

    it("parses the path", function()
      assert.are.equal(req.path,'/device')
    end)

    it("parses query params", function()
      assert.are.equal(req.query['foo'],'one')
      assert.are.equal(req.query['bar'],'two')
    end)

    it("parses a string body", function()
      assert.are.equal(req.body,'hi')
    end)
  end)

  describe("POST request JSON body", function()
    before_each(function()
      raw = "POST /device HTTP/1.1\r\nHost: example.com\r\nUser-Agent: curl/7.54.0\r\nContent-Type: application/json\r\nAccept: */*\r\n\r\n{\"foo\":1,\"bar\":2}"
      req = require("httpd_req")(raw)
    end)

    it("parses the request method", function()
      assert.are.equal(req.method,'POST')
    end)

    it("parses the content type", function()
      assert.are.equal(req.contentType, 'application/json')
    end)

    it("parses a JSON body", function()
      assert.are.equal(req.body.foo, 1)
      assert.are.equal(req.body.bar, 2)
    end)

  end)

  describe("GET request no body", function()
    before_each(function()
      raw = "GET /device?foo=one&bar=two HTTP/1.1\r\nHost: example.com\r\nUser-Agent: curl/7.54.0\r\nAccept: */*"
      req = require("httpd_req")(raw)
    end)

    it("parses a nil body", function()
      assert.is_nil(req.body)
    end)
  end)


end)