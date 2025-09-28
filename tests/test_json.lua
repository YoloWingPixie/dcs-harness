local lu = require("luaunit")

TestJson = {}

function TestJson:testEncodePrimitives()
    lu.assertEquals(EncodeJson(nil), "null")
    lu.assertEquals(EncodeJson(true), "true")
    lu.assertEquals(EncodeJson(false), "false")
    lu.assertEquals(EncodeJson(123), "123")
    lu.assertEquals(EncodeJson("hi"), '"hi"')
    lu.assertEquals(EncodeJson('a"b\\c'), '"a\\"b\\\\c"')
end

function TestJson:testEncodeArray()
    local json = EncodeJson({ 1, 2, "a" })
    -- Accept either exact or minimal spacing variants; fallback emits no spaces
    lu.assertEquals(json, "[1,2,\"a\"]")
end

function TestJson:testEncodeObject()
    local json = EncodeJson({ a = 1, b = "x" })
    -- Object key order is unspecified; accept either ordering
    local ok = (json == '{"a":1,"b":"x"}') or (json == '{"b":"x","a":1}')
    lu.assertTrue(ok)
end

function TestJson:testDecodePrimitives()
    lu.assertEquals(DecodeJson("null"), nil)
    lu.assertEquals(DecodeJson("true"), true)
    lu.assertEquals(DecodeJson("false"), false)
    lu.assertEquals(DecodeJson("123"), 123)
    lu.assertEquals(DecodeJson('"hello"'), "hello")
    lu.assertEquals(DecodeJson('"a\\"b\\\\c"'), 'a"b\\c')
end

function TestJson:testDecodeArray()
    local arr = DecodeJson('[1,2,3]')
    lu.assertEquals(arr, { 1, 2, 3 })
end

function TestJson:testDecodeObjectFlat()
    local obj = DecodeJson('{"a":1,"b":"x"}')
    lu.assertEquals(obj.a, 1)
    lu.assertEquals(obj.b, "x")
end

return TestJson


