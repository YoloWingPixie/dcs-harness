local lu = require("luaunit")

TestObject = {}

function TestObject:testIdentityAndCategoryUseOnlyTheRequestedProperty()
    for _, identity in ipairs({ 0, -3, 1.5, "weapon-42" }) do
        local object = setmetatable({
            id_ = identity,
            getCategory = function()
                return 7
            end,
        }, {
            __index = function(_, key)
                error("unexpected property " .. key)
            end,
        })
        lu.assertEquals(GetObjectID(object), identity)
        lu.assertEquals(GetObjectCategory(object), 7)
    end
end

function TestObject:testVectorReadersReturnDetachedFinitePlainTables()
    local point = Vec3(1, 200, 3)
    local velocity = Vec3(-4, 5, 6)
    local object = {}
    object.getPoint = function(receiver)
        lu.assertIs(receiver, object)
        return point
    end
    object.getVelocity = function(receiver)
        lu.assertIs(receiver, object)
        return velocity
    end
    local readPoint, readVelocity = GetObjectPoint(object), GetObjectVelocity(object)
    lu.assertEquals(readPoint, { x = 1, y = 200, z = 3 })
    lu.assertEquals(readVelocity, { x = -4, y = 5, z = 6 })
    lu.assertNil(getmetatable(readPoint))
    lu.assertNil(getmetatable(readVelocity))
    readPoint.y, readVelocity.x = 0, 0
    lu.assertEquals(point.y, 200)
    lu.assertEquals(velocity.x, -4)
end

function TestObject:testInvalidHandlesAndNativeFailures()
    local readers = { GetObjectID, GetObjectCategory, GetObjectPoint, GetObjectVelocity }
    local throwing = setmetatable({}, {
        __index = function()
            error("removed")
        end,
    })
    for _, reader in ipairs(readers) do
        lu.assertNil(reader(nil))
        for _, object in ipairs({ true, 42, "unit name", {}, throwing }) do
            lu.assertNil(reader(object))
        end
    end
    local function fail()
        error("native failure")
    end
    local object = { getCategory = fail, getPoint = fail, getVelocity = fail }
    lu.assertNil(GetObjectCategory(object))
    lu.assertNil(GetObjectPoint(object))
    lu.assertNil(GetObjectVelocity(object))
end

function TestObject:testInvalidPropertiesAndVectors()
    for _, value in ipairs({ "", false, {}, 0 / 0, math.huge, -math.huge }) do
        lu.assertNil(GetObjectID({ id_ = value }))
    end
    lu.assertNil(GetObjectCategory({
        getCategory = function()
            return "1"
        end,
    }))
    for _, coordinate in ipairs({ "x", "y", "z" }) do
        for _, value in ipairs({ "1", false, 0 / 0, math.huge, -math.huge }) do
            local vector = { x = 1, y = 2, z = 3 }
            vector[coordinate] = value
            local object = {
                getPoint = function()
                    return vector
                end,
                getVelocity = function()
                    return vector
                end,
            }
            lu.assertNil(GetObjectPoint(object))
            lu.assertNil(GetObjectVelocity(object))
        end
    end
    lu.assertNil(GetObjectPoint({
        getPoint = function()
            return { x = 1, y = 2 }
        end,
    }))
end

TestSensorRanges = {}

function TestSensorRanges:testIndependentRangesAndIsolation()
    local sensor = {
        detectionDistanceAir = { upperHemisphere = { headOn = 100 } },
        detectionDistanceMaximal = 200,
    }
    local ranges = ReadSensorAirDetectionRanges(sensor)
    lu.assertEquals(ranges, { upperHeadOn = 100, maximal = 200 })
    ranges.upperHeadOn = 1
    lu.assertEquals(sensor.detectionDistanceAir.upperHemisphere.headOn, 100)
    sensor.detectionDistanceAir.upperHemisphere.headOn = -1
    lu.assertEquals(ReadSensorAirDetectionRanges(sensor), { maximal = 200 })
    sensor.detectionDistanceMaximal = nil
    sensor.detectionDistanceAir.upperHemisphere.headOn = 100
    lu.assertEquals(ReadSensorAirDetectionRanges(sensor), { upperHeadOn = 100 })
end

function TestSensorRanges:testMalformedAndNonpositiveRanges()
    lu.assertNil(ReadSensorAirDetectionRanges(nil))
    for _, value in ipairs({ false, "10", {}, 0, -1, 0 / 0, math.huge, -math.huge }) do
        lu.assertNil(ReadSensorAirDetectionRanges(value))
        lu.assertNil(ReadSensorAirDetectionRanges({
            detectionDistanceMaximal = value,
            detectionDistanceAir = { upperHemisphere = { headOn = value } },
        }))
        lu.assertEquals(
            ReadSensorAirDetectionRanges({
                detectionDistanceAir = value,
                detectionDistanceMaximal = 10,
            }),
            { maximal = 10 }
        )
        lu.assertEquals(
            ReadSensorAirDetectionRanges({
                detectionDistanceAir = { upperHemisphere = value },
                detectionDistanceMaximal = 10,
            }),
            { maximal = 10 }
        )
    end
end
