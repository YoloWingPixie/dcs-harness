-- test_coord.lua
local lu = require("luaunit")
require("test_utils")

-- Setup test environment
package.path = package.path .. ";../src/?.lua"

-- Create isolated test suite
TestCoord = CreateIsolatedTestSuite("TestCoord", {})

function TestCoord:setUp()
    -- Load required modules
    require("mock_dcs")
    require("_header")

    -- Ensure _HarnessInternal has required fields before loading logger
    if not _HarnessInternal.loggers then
        _HarnessInternal.loggers = {}
    end
    if not _HarnessInternal.defaultNamespace then
        _HarnessInternal.defaultNamespace = "Harness"
    end

    require("logger")

    -- Ensure internal logger is created
    if not _HarnessInternal.log then
        _HarnessInternal.log = HarnessLogger("Harness")
    end

    require("coord")

    -- Save original mock functions
    self.original_LOtoLL = coord.LOtoLL
    self.original_LLtoLO = coord.LLtoLO
    self.original_LOtoMGRS = coord.LOtoMGRS
    self.original_MGRStoLO = coord.MGRStoLO
end

function TestCoord:tearDown()
    -- Restore original mock functions
    coord.LOtoLL = self.original_LOtoLL
    coord.LLtoLO = self.original_LLtoLO
    coord.LOtoMGRS = self.original_LOtoMGRS
    coord.MGRStoLO = self.original_MGRStoLO
end

-- LOtoLL tests
function TestCoord:testLOtoLL_ValidVec3()
    local vec3 = { x = 1000, y = 100, z = 2000 }
    local result = LOtoLL(vec3)
    lu.assertNotNil(result)
    lu.assertEquals(result.latitude, 43.5)
    lu.assertEquals(result.longitude, 41.2)
end

function TestCoord:testLOtoLL_NilInput()
    local result = LOtoLL(nil)
    lu.assertNil(result)
end

function TestCoord:testLOtoLL_EmptyTable()
    local result = LOtoLL({})
    lu.assertNil(result)
end

function TestCoord:testLOtoLL_MissingX()
    local vec3 = { y = 100, z = 2000 }
    local result = LOtoLL(vec3)
    lu.assertNil(result)
end

function TestCoord:testLOtoLL_MissingY()
    local vec3 = { x = 1000, z = 2000 }
    local result = LOtoLL(vec3)
    lu.assertNil(result)
end

function TestCoord:testLOtoLL_MissingZ()
    local vec3 = { x = 1000, y = 100 }
    local result = LOtoLL(vec3)
    lu.assertNil(result)
end

function TestCoord:testLOtoLL_InvalidType()
    local result = LOtoLL("not a table")
    lu.assertNil(result)
end

function TestCoord:testLOtoLL_APIError()
    coord.LOtoLL = function(vec3)
        error("DCS API error")
    end
    local vec3 = { x = 1000, y = 100, z = 2000 }
    local result = LOtoLL(vec3)
    lu.assertNil(result)
end

function TestCoord:testLOtoLL_ZeroCoordinates()
    local vec3 = { x = 0, y = 0, z = 0 }
    local result = LOtoLL(vec3)
    lu.assertNotNil(result)
end

function TestCoord:testLOtoLL_NegativeCoordinates()
    local vec3 = { x = -5000, y = -100, z = -3000 }
    local result = LOtoLL(vec3)
    lu.assertNotNil(result)
end

-- LLtoLO tests
function TestCoord:testLLtoLO_ValidCoordinates()
    local result = LLtoLO(43.5, 41.2, 1000)
    lu.assertNotNil(result)
    lu.assertEquals(result.x, 1000)
    lu.assertEquals(result.y, 1000)
    lu.assertEquals(result.z, 2000)
end

function TestCoord:testLLtoLO_DefaultAltitude()
    local result = LLtoLO(43.5, 41.2)
    lu.assertNotNil(result)
    lu.assertEquals(result.x, 1000)
    lu.assertEquals(result.y, 0)
    lu.assertEquals(result.z, 2000)
end

function TestCoord:testLLtoLO_NilLatitude()
    local result = LLtoLO(nil, 41.2, 1000)
    lu.assertNil(result)
end

function TestCoord:testLLtoLO_NilLongitude()
    local result = LLtoLO(43.5, nil, 1000)
    lu.assertNil(result)
end

function TestCoord:testLLtoLO_InvalidLatitudeType()
    local result = LLtoLO("not a number", 41.2, 1000)
    lu.assertNil(result)
end

function TestCoord:testLLtoLO_InvalidLongitudeType()
    local result = LLtoLO(43.5, "not a number", 1000)
    lu.assertNil(result)
end

function TestCoord:testLLtoLO_ZeroAltitude()
    local result = LLtoLO(43.5, 41.2, 0)
    lu.assertNotNil(result)
    lu.assertEquals(result.y, 0)
end

function TestCoord:testLLtoLO_NegativeAltitude()
    local result = LLtoLO(43.5, 41.2, -500)
    lu.assertNotNil(result)
    lu.assertEquals(result.y, -500)
end

function TestCoord:testLLtoLO_ExtremeLatitude()
    local result = LLtoLO(90, 41.2, 1000)
    lu.assertNotNil(result)
end

function TestCoord:testLLtoLO_ExtremeLongitude()
    local result = LLtoLO(43.5, 180, 1000)
    lu.assertNotNil(result)
end

function TestCoord:testLLtoLO_APIError()
    coord.LLtoLO = function(lat, lon, alt)
        error("DCS API error")
    end
    local result = LLtoLO(43.5, 41.2, 1000)
    lu.assertNil(result)
end

-- LOtoMGRS tests
function TestCoord:testLOtoMGRS_ValidVec3()
    local vec3 = { x = 1000, y = 100, z = 2000 }
    local result = LOtoMGRS(vec3)
    lu.assertNotNil(result)
    lu.assertEquals(result.UTMZone, "37T")
    lu.assertEquals(result.MGRSDigraph, "CK")
    lu.assertEquals(result.Easting, 12345)
    lu.assertEquals(result.Northing, 67890)
end

function TestCoord:testLOtoMGRS_NilInput()
    local result = LOtoMGRS(nil)
    lu.assertNil(result)
end

function TestCoord:testLOtoMGRS_EmptyTable()
    local result = LOtoMGRS({})
    lu.assertNil(result)
end

function TestCoord:testLOtoMGRS_MissingCoordinates()
    local vec3 = { x = 1000 } -- Missing y and z
    local result = LOtoMGRS(vec3)
    lu.assertNil(result)
end

function TestCoord:testLOtoMGRS_InvalidType()
    local result = LOtoMGRS("not a table")
    lu.assertNil(result)
end

function TestCoord:testLOtoMGRS_APIError()
    coord.LOtoMGRS = function(vec3)
        error("DCS API error")
    end
    local vec3 = { x = 1000, y = 100, z = 2000 }
    local result = LOtoMGRS(vec3)
    lu.assertNil(result)
end

function TestCoord:testLOtoMGRS_ZeroCoordinates()
    local vec3 = { x = 0, y = 0, z = 0 }
    local result = LOtoMGRS(vec3)
    lu.assertNotNil(result)
end

function TestCoord:testLOtoMGRS_LargeCoordinates()
    local vec3 = { x = 999999, y = 10000, z = 999999 }
    local result = LOtoMGRS(vec3)
    lu.assertNotNil(result)
end

-- MGRStoLO tests
function TestCoord:testMGRStoLO_ValidString()
    local result = MGRStoLO("37T CK 12345 67890")
    lu.assertNotNil(result)
    lu.assertEquals(result.x, 1000)
    lu.assertEquals(result.y, 0)
    lu.assertEquals(result.z, 2000)
end

function TestCoord:testMGRStoLO_NilInput()
    local result = MGRStoLO(nil)
    lu.assertNil(result)
end

function TestCoord:testMGRStoLO_EmptyString()
    local result = MGRStoLO("")
    lu.assertNil(result) -- Empty string should fail validation
end

function TestCoord:testMGRStoLO_InvalidType()
    local result = MGRStoLO(12345) -- Number instead of string
    lu.assertNil(result)
end

function TestCoord:testMGRStoLO_InvalidFormat()
    coord.MGRStoLO = function(mgrsString)
        error("Invalid MGRS format")
    end
    local result = MGRStoLO("INVALID MGRS")
    lu.assertNil(result)
end

function TestCoord:testMGRStoLO_APIError()
    coord.MGRStoLO = function(mgrsString)
        error("DCS API error")
    end
    local result = MGRStoLO("37T CK 12345 67890")
    lu.assertNil(result)
end

function TestCoord:testMGRStoLO_VariousFormats()
    -- Test different MGRS string formats
    local formats = {
        "37T CK 12345 67890",
        "37TCK1234567890",
        "37T CK 1234567890",
    }

    for _, mgrs in ipairs(formats) do
        local result = MGRStoLO(mgrs)
        lu.assertNotNil(result)
    end
end

-- Integration tests
function TestCoord:testRoundTrip_LOtoLL_LLtoLO()
    -- Start with a position
    local originalPos = { x = 5000, y = 1500, z = 8000 }

    -- Convert to lat/lon
    local latlon = LOtoLL(originalPos)
    lu.assertNotNil(latlon)

    -- Convert back to local coordinates
    local newPos = LLtoLO(latlon.latitude, latlon.longitude, originalPos.y)
    lu.assertNotNil(newPos)

    -- Should be close to original (mock returns fixed values)
    lu.assertEquals(newPos.x, 1000)
    lu.assertEquals(newPos.y, originalPos.y)
    lu.assertEquals(newPos.z, 2000)
end

function TestCoord:testRoundTrip_LOtoMGRS_MGRStoLO()
    -- Start with a position
    local originalPos = { x = 5000, y = 1500, z = 8000 }

    -- Convert to MGRS
    local mgrs = LOtoMGRS(originalPos)
    lu.assertNotNil(mgrs)

    -- Build MGRS string
    local mgrsString =
        string.format("%s %s %d %d", mgrs.UTMZone, mgrs.MGRSDigraph, mgrs.Easting, mgrs.Northing)

    -- Convert back to local coordinates
    local newPos = MGRStoLO(mgrsString)
    lu.assertNotNil(newPos)

    -- Should return mock values
    lu.assertEquals(newPos.x, 1000)
    lu.assertEquals(newPos.y, 0)
    lu.assertEquals(newPos.z, 2000)
end

-- Edge cases
function TestCoord:testCoordinates_VerySmallValues()
    local vec3 = { x = 0.001, y = 0.001, z = 0.001 }
    local result = LOtoLL(vec3)
    lu.assertNotNil(result)
end

function TestCoord:testCoordinates_MixedSigns()
    local vec3 = { x = -1000, y = 500, z = -2000 }
    local result = LOtoLL(vec3)
    lu.assertNotNil(result)
end

function TestCoord:testLatLon_PoleCoordinates()
    -- North pole
    local result1 = LLtoLO(90, 0, 0)
    lu.assertNotNil(result1)

    -- South pole
    local result2 = LLtoLO(-90, 0, 0)
    lu.assertNotNil(result2)
end

function TestCoord:testLatLon_DatelineCoordinates()
    -- International date line
    local result1 = LLtoLO(0, 180, 0)
    lu.assertNotNil(result1)

    local result2 = LLtoLO(0, -180, 0)
    lu.assertNotNil(result2)
end

return TestCoord
