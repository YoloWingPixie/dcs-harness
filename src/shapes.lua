--[[
    Shapes Module - Geospatial Shape Generation
    
    This module provides functions to generate various geometric shapes
    as arrays of Vec2/Vec3 points for use in DCS World scripting.
    All shapes are geospatially aware and use real-world measurements.
]]

--- Creates an equilateral triangle shape
--- @param center table|Vec2 Center point of the triangle {x, z} or Vec2
--- @param size number? Length of each side in meters (default: 1000)
--- @param rotation number? Rotation angle in degrees (default: 0)
--- @return table|nil points Array of Vec2 points defining the triangle or nil on error
--- @usage local triangle = CreateTriangle({x=0, z=0}, 5000, 45)
function CreateTriangle(center, size, rotation)
    if not center then
        _HarnessInternal.log.error("CreateTriangle requires center point", "Shapes.CreateTriangle")
        return nil
    end
    
    center = ToVec2(center)
    size = size or 1000 -- Default 1km sides
    rotation = rotation or 0
    
    -- Create equilateral triangle
    local height = size * math.sqrt(3) / 2
    local points = {
        Vec2(0, height * 2/3),           -- Top vertex
        Vec2(-size/2, -height * 1/3),    -- Bottom left
        Vec2(size/2, -height * 1/3)      -- Bottom right
    }
    
    -- Rotate and translate
    local result = {}
    for _, p in ipairs(points) do
        local rotated = p:rotate(rotation)
        table.insert(result, center + rotated)
    end
    
    return result
end

--- Creates a rectangle shape
--- @param center table|Vec2 Center point of the rectangle {x, z} or Vec2
--- @param width number? Width in meters (default: 2000)
--- @param height number? Height in meters (default: 1000)
--- @param rotation number? Rotation angle in degrees (default: 0)
--- @return table|nil points Array of Vec2 points defining the rectangle or nil on error
--- @usage local rect = CreateRectangle({x=0, z=0}, 5000, 3000, 90)
function CreateRectangle(center, width, height, rotation)
    if not center then
        _HarnessInternal.log.error("CreateRectangle requires center point", "Shapes.CreateRectangle")
        return nil
    end
    
    center = ToVec2(center)
    width = width or 2000    -- Default 2km width
    height = height or 1000  -- Default 1km height
    rotation = rotation or 0
    
    local halfW = width / 2
    local halfH = height / 2
    
    local points = {
        Vec2(-halfW, -halfH),  -- Bottom left
        Vec2(halfW, -halfH),   -- Bottom right
        Vec2(halfW, halfH),    -- Top right
        Vec2(-halfW, halfH)    -- Top left
    }
    
    -- Rotate and translate
    local result = {}
    for _, p in ipairs(points) do
        local rotated = p:rotate(rotation)
        table.insert(result, center + rotated)
    end
    
    return result
end

--- Creates a square shape
--- @param center table|Vec2 Center point of the square {x, z} or Vec2
--- @param size number? Length of each side in meters
--- @param rotation number? Rotation angle in degrees (default: 0)
--- @return table|nil points Array of Vec2 points defining the square or nil on error
--- @usage local square = CreateSquare({x=0, z=0}, 2000, 45)
function CreateSquare(center, size, rotation)
    return CreateRectangle(center, size, size, rotation)
end

--- Creates an oval/ellipse shape
--- @param center table|Vec2 Center point of the oval {x, z} or Vec2
--- @param radiusX number? Radius along X axis in meters (default: 1000)
--- @param radiusZ number? Radius along Z axis in meters (default: radiusX)
--- @param numPoints number? Number of points to generate (default: 36)
--- @return table|nil points Array of Vec2 points defining the oval or nil on error
--- @usage local oval = CreateOval({x=0, z=0}, 2000, 1000, 48)
function CreateOval(center, radiusX, radiusZ, numPoints)
    if not center then
        _HarnessInternal.log.error("CreateOval requires center point", "Shapes.CreateOval")
        return nil
    end
    
    center = ToVec2(center)
    radiusX = radiusX or 1000    -- Default 1km radius X
    radiusZ = radiusZ or radiusX  -- Default to circle if not specified
    numPoints = numPoints or 36   -- Default 36 points (10-degree increments)
    
    local points = {}
    local angleStep = 2 * math.pi / numPoints
    
    for i = 0, numPoints - 1 do
        local angle = i * angleStep
        local x = radiusX * math.cos(angle)
        local z = radiusZ * math.sin(angle)
        table.insert(points, center + Vec2(x, z))
    end
    
    return points
end

--- Creates a circle shape
--- @param center table|Vec2 Center point of the circle {x, z} or Vec2
--- @param radius number? Radius in meters
--- @param numPoints number? Number of points to generate (default: 36)
--- @return table|nil points Array of Vec2 points defining the circle or nil on error
--- @usage local circle = CreateCircle({x=0, z=0}, 5000, 72)
function CreateCircle(center, radius, numPoints)
    return CreateOval(center, radius, radius, numPoints)
end

--- Creates a fan/sector shape from an origin point
--- @param origin table|Vec2 Origin point of the fan {x, z} or Vec2
--- @param centerBearing number? Center bearing of the arc in degrees (default: 0)
--- @param arcDegrees number? Total arc width in degrees (default: 90)
--- @param distance number? Distance from origin in meters (default: 50 NM)
--- @param numPoints number? Number of arc points (default: based on arc size)
--- @return table|nil points Array of Vec2 points defining the fan or nil on error
--- @usage local fan = CreateFan({x=0, z=0}, 45, 60, 10000) -- 60° arc centered on bearing 45°
function CreateFan(origin, centerBearing, arcDegrees, distance, numPoints)
    if not origin then
        _HarnessInternal.log.error("CreateFan requires origin point", "Shapes.CreateFan")
        return nil
    end
    
    origin = ToVec2(origin)
    centerBearing = centerBearing or 0
    arcDegrees = arcDegrees or 90
    distance = distance or 50 * 1852  -- Default 50 nautical miles
    numPoints = numPoints or math.ceil(arcDegrees / 5) + 1  -- Default 5-degree increments
    
    local points = {origin}  -- Start with origin
    
    -- Calculate start bearing (half arc to the left of center)
    local halfArc = arcDegrees / 2
    local startBearing = centerBearing - halfArc
    local angleStep = arcDegrees / (numPoints - 1)
    
    for i = 0, numPoints - 1 do
        local bearing = startBearing + i * angleStep
        local point = origin:displace(bearing, distance)
        table.insert(points, point)
    end
    
    -- Close the fan by returning to origin
    table.insert(points, origin)
    
    return points
end

--- Creates a trapezoid shape
--- @param center table|Vec2 Center point of the trapezoid {x, z} or Vec2
--- @param topWidth number? Width of top edge in meters (default: 1000)
--- @param bottomWidth number? Width of bottom edge in meters (default: 2000)
--- @param height number? Height in meters (default: 1000)
--- @param rotation number? Rotation angle in degrees (default: 0)
--- @return table|nil points Array of Vec2 points defining the trapezoid or nil on error
--- @usage local trap = CreateTrapezoid({x=0, z=0}, 1000, 3000, 2000)
function CreateTrapezoid(center, topWidth, bottomWidth, height, rotation)
    if not center then
        _HarnessInternal.log.error("CreateTrapezoid requires center point", "Shapes.CreateTrapezoid")
        return nil
    end
    
    center = ToVec2(center)
    topWidth = topWidth or 1000      -- Default 1km top width
    bottomWidth = bottomWidth or 2000 -- Default 2km bottom width
    height = height or 1000           -- Default 1km height
    rotation = rotation or 0
    
    local halfTop = topWidth / 2
    local halfBottom = bottomWidth / 2
    local halfH = height / 2
    
    local points = {
        Vec2(-halfBottom, -halfH),  -- Bottom left
        Vec2(halfBottom, -halfH),   -- Bottom right
        Vec2(halfTop, halfH),       -- Top right
        Vec2(-halfTop, halfH)       -- Top left
    }
    
    -- Rotate and translate
    local result = {}
    for _, p in ipairs(points) do
        local rotated = p:rotate(rotation)
        table.insert(result, center + rotated)
    end
    
    return result
end

--- Creates a pill/capsule shape (rectangle with semicircular ends)
--- @param center table|Vec2 Center point of the pill {x, z} or Vec2
--- @param legBearing number? Direction of the long axis in degrees (default: 0)
--- @param legLength number? Length of the straight section in meters (default: 40 NM)
--- @param radius number? Radius of the semicircular ends in meters (default: 10 NM)
--- @param pointsPerCap number? Points per semicircle end (default: 19)
--- @return table|nil points Array of Vec2 points defining the pill or nil on error
--- @usage local pill = CreatePill({x=0, z=0}, 90, 20000, 5000)
function CreatePill(center, legBearing, legLength, radius, pointsPerCap)
    if not center then
        _HarnessInternal.log.error("CreatePill requires center point", "Shapes.CreatePill")
        return nil
    end
    
    center = ToVec2(center)
    legBearing = legBearing or 0
    legLength = legLength or 40 * 1852  -- Default 40 nautical miles
    radius = radius or 10 * 1852         -- Default 10 nautical miles
    pointsPerCap = pointsPerCap or 19    -- Points per semicircle
    
    local halfLegLength = legLength / 2
    
    -- Calculate the two centers for the semicircular caps
    local cap1Center = center:displace(legBearing, halfLegLength)
    local cap2Center = center:displace((legBearing + 180) % 360, halfLegLength)
    
    -- Calculate perpendicular bearing for the sides
    local perpBearing = (legBearing + 90) % 360
    
    local points = {}
    
    -- Generate first semicircle (right side going clockwise from perpBearing)
    local angleStep = 180 / (pointsPerCap - 1)
    for i = 0, pointsPerCap - 1 do
        local bearing = (perpBearing - i * angleStep + 720) % 360
        table.insert(points, cap1Center:displace(bearing, radius))
    end
    
    -- Generate second semicircle (left side going clockwise from opposite perpBearing)
    for i = 0, pointsPerCap - 1 do
        local bearing = ((perpBearing + 180) - i * angleStep + 720) % 360
        table.insert(points, cap2Center:displace(bearing, radius))
    end
    
    return points
end

--- Creates a star shape
--- @param center table|Vec2 Center point of the star {x, z} or Vec2
--- @param outerRadius number? Radius to outer points in meters (default: 1000)
--- @param innerRadius number? Radius to inner points in meters (default: 400)
--- @param numPoints number? Number of star points (default: 5)
--- @param rotation number? Rotation angle in degrees (default: 0)
--- @return table|nil points Array of Vec2 points defining the star or nil on error
--- @usage local star = CreateStar({x=0, z=0}, 5000, 2000, 5, 0)
function CreateStar(center, outerRadius, innerRadius, numPoints, rotation)
    if not center then
        _HarnessInternal.log.error("CreateStar requires center point", "Shapes.CreateStar")
        return nil
    end
    
    center = ToVec2(center)
    outerRadius = outerRadius or 1000   -- Default 1km outer radius
    innerRadius = innerRadius or 400    -- Default 400m inner radius
    numPoints = numPoints or 5         -- Default 5-pointed star
    rotation = rotation or 0
    
    local points = {}
    local angleStep = math.pi / numPoints  -- Half angle between points
    
    for i = 0, numPoints * 2 - 1 do
        local angle = i * angleStep - math.pi / 2 + DegToRad(rotation)
        local radius = (i % 2 == 0) and outerRadius or innerRadius
        local x = radius * math.cos(angle)
        local z = radius * math.sin(angle)
        table.insert(points, center + Vec2(x, z))
    end
    
    return points
end

--- Creates a regular polygon shape
--- @param center table|Vec2 Center point of the polygon {x, z} or Vec2
--- @param radius number Radius to vertices in meters
--- @param numSides number Number of sides (minimum 3)
--- @param rotation number? Rotation angle in degrees (default: 0)
--- @return table|nil points Array of Vec2 points defining the polygon or nil on error
--- @usage local pentagon = CreatePolygon({x=0, z=0}, 3000, 5, 0)
function CreatePolygon(center, radius, numSides, rotation)
    if not center or not radius or not numSides then
        _HarnessInternal.log.error("CreatePolygon requires center, radius, and number of sides", "Shapes.CreatePolygon")
        return nil
    end
    
    if numSides < 3 then
        _HarnessInternal.log.error("CreatePolygon requires at least 3 sides", "Shapes.CreatePolygon")
        return nil
    end
    
    center = ToVec2(center)
    rotation = rotation or 0
    
    local points = {}
    local angleStep = 2 * math.pi / numSides
    
    for i = 0, numSides - 1 do
        local angle = i * angleStep - math.pi / 2 + DegToRad(rotation)
        local x = radius * math.cos(angle)
        local z = radius * math.sin(angle)
        table.insert(points, center + Vec2(x, z))
    end
    
    return points
end

--- Creates a hexagon shape
--- @param center table|Vec2 Center point of the hexagon {x, z} or Vec2
--- @param radius number Radius to vertices in meters
--- @param rotation number? Rotation angle in degrees (default: 0)
--- @return table|nil points Array of Vec2 points defining the hexagon or nil on error
--- @usage local hex = CreateHexagon({x=0, z=0}, 2000, 30)
function CreateHexagon(center, radius, rotation)
    return CreatePolygon(center, radius, 6, rotation)
end

--- Creates an octagon shape
--- @param center table|Vec2 Center point of the octagon {x, z} or Vec2
--- @param radius number Radius to vertices in meters
--- @param rotation number? Rotation angle in degrees (default: 0)
--- @return table|nil points Array of Vec2 points defining the octagon or nil on error
--- @usage local oct = CreateOctagon({x=0, z=0}, 2000, 0)
function CreateOctagon(center, radius, rotation)
    return CreatePolygon(center, radius, 8, rotation)
end

--- Creates an arc shape
--- @param center table|Vec2 Center point of the arc {x, z} or Vec2
--- @param radius number Radius in meters
--- @param startBearing number? Starting bearing in degrees (default: 0)
--- @param endBearing number? Ending bearing in degrees (default: 90)
--- @param numPoints number? Number of points (default: based on arc size)
--- @return table|nil points Array of Vec2 points defining the arc or nil on error
--- @usage local arc = CreateArc({x=0, z=0}, 5000, 0, 180, 37)
function CreateArc(center, radius, startBearing, endBearing, numPoints)
    if not center or not radius then
        _HarnessInternal.log.error("CreateArc requires center and radius", "Shapes.CreateArc")
        return nil
    end
    
    center = ToVec2(center)
    startBearing = startBearing or 0
    endBearing = endBearing or 90
    numPoints = numPoints or math.ceil(math.abs(endBearing - startBearing) / 5) + 1
    
    local points = {}
    
    -- Normalize bearings
    startBearing = startBearing % 360
    endBearing = endBearing % 360
    
    -- Calculate arc span
    local arcSpan = endBearing - startBearing
    if arcSpan < 0 then
        arcSpan = arcSpan + 360
    end
    
    local angleStep = arcSpan / (numPoints - 1)
    
    for i = 0, numPoints - 1 do
        local bearing = (startBearing + i * angleStep) % 360
        table.insert(points, center:displace(bearing, radius))
    end
    
    return points
end

--- Creates a spiral shape
--- @param center table|Vec2 Center point of the spiral {x, z} or Vec2
--- @param startRadius number? Starting radius in meters (default: 100)
--- @param endRadius number? Ending radius in meters (default: 1000)
--- @param numTurns number? Number of complete turns (default: 3)
--- @param pointsPerTurn number? Points per turn (default: 36)
--- @return table|nil points Array of Vec2 points defining the spiral or nil on error
--- @usage local spiral = CreateSpiral({x=0, z=0}, 100, 5000, 5, 72)
function CreateSpiral(center, startRadius, endRadius, numTurns, pointsPerTurn)
    if not center then
        _HarnessInternal.log.error("CreateSpiral requires center point", "Shapes.CreateSpiral")
        return nil
    end
    
    center = ToVec2(center)
    startRadius = startRadius or 100
    endRadius = endRadius or 1000
    numTurns = numTurns or 3
    pointsPerTurn = pointsPerTurn or 36
    
    local points = {}
    local totalPoints = numTurns * pointsPerTurn
    local radiusStep = (endRadius - startRadius) / totalPoints
    local angleStep = 2 * math.pi / pointsPerTurn
    
    for i = 0, totalPoints - 1 do
        local radius = startRadius + i * radiusStep
        local angle = i * angleStep
        local x = radius * math.cos(angle)
        local z = radius * math.sin(angle)
        table.insert(points, center + Vec2(x, z))
    end
    
    return points
end

--- Creates a ring/donut shape
--- @param center table|Vec2 Center point of the ring {x, z} or Vec2
--- @param outerRadius number Outer radius in meters
--- @param innerRadius number Inner radius in meters (must be less than outer)
--- @param numPoints number? Number of points per circle (default: 36)
--- @return table|nil points Array of Vec2 points defining the ring or nil on error
--- @usage local ring = CreateRing({x=0, z=0}, 5000, 3000, 72)
function CreateRing(center, outerRadius, innerRadius, numPoints)
    if not center then
        _HarnessInternal.log.error("CreateRing requires center point", "Shapes.CreateRing")
        return nil
    end
    
    if not outerRadius or not innerRadius or innerRadius >= outerRadius then
        _HarnessInternal.log.error("CreateRing requires valid inner and outer radii", "Shapes.CreateRing")
        return nil
    end
    
    -- Create as two circles that will form a ring when rendered
    -- Note: This creates a hollow ring outline, not a filled donut
    local outer = CreateCircle(center, outerRadius, numPoints)
    local inner = CreateCircle(center, innerRadius, numPoints)
    
    -- Reverse inner circle for proper winding
    local reversedInner = {}
    for i = #inner, 1, -1 do
        table.insert(reversedInner, inner[i])
    end
    
    -- Combine: outer circle + connection + reversed inner circle + connection back
    local ring = {}
    
    -- Add outer circle
    for _, p in ipairs(outer) do
        table.insert(ring, p)
    end
    
    -- Connect to inner circle
    table.insert(ring, reversedInner[1])
    
    -- Add reversed inner circle
    for _, p in ipairs(reversedInner) do
        table.insert(ring, p)
    end
    
    -- Close the ring
    table.insert(ring, outer[1])
    
    return ring
end

--- Creates a cross/plus shape
--- @param center table|Vec2 Center point of the cross {x, z} or Vec2
--- @param size number? Length of the cross arms in meters (default: 1000)
--- @param thickness number? Thickness of the arms in meters (default: 200)
--- @param rotation number? Rotation angle in degrees (default: 0)
--- @return table|nil points Array of Vec2 points defining the cross or nil on error
--- @usage local cross = CreateCross({x=0, z=0}, 2000, 400, 45)
function CreateCross(center, size, thickness, rotation)
    if not center then
        _HarnessInternal.log.error("CreateCross requires center point", "Shapes.CreateCross")
        return nil
    end
    
    center = ToVec2(center)
    size = size or 1000          -- Default 1km size
    thickness = thickness or 200  -- Default 200m thickness
    rotation = rotation or 0
    
    local halfSize = size / 2
    local halfThick = thickness / 2
    
    -- Define cross shape points (12 points for the outline)
    local points = {
        Vec2(-halfThick, -halfSize),    -- Bottom of vertical bar
        Vec2(halfThick, -halfSize),
        Vec2(halfThick, -halfThick),
        Vec2(halfSize, -halfThick),     -- Right of horizontal bar
        Vec2(halfSize, halfThick),
        Vec2(halfThick, halfThick),
        Vec2(halfThick, halfSize),      -- Top of vertical bar
        Vec2(-halfThick, halfSize),
        Vec2(-halfThick, halfThick),
        Vec2(-halfSize, halfThick),     -- Left of horizontal bar
        Vec2(-halfSize, -halfThick),
        Vec2(-halfThick, -halfThick)
    }
    
    -- Rotate and translate
    local result = {}
    for _, p in ipairs(points) do
        local rotated = p:rotate(rotation)
        table.insert(result, center + rotated)
    end
    
    return result
end

--- Converts shape points to Vec3 with specified altitude
--- @param shape table Array of Vec2 points
--- @param altitude number? Altitude in meters (default: 0)
--- @return table|nil points Array of Vec3 points or nil on error
--- @usage local shape3D = ShapeToVec3(triangle, 1000)
function ShapeToVec3(shape, altitude)
    if not shape or type(shape) ~= "table" then
        _HarnessInternal.log.error("ShapeToVec3 requires valid shape", "Shapes.ShapeToVec3")
        return nil
    end
    
    altitude = altitude or 0
    
    local result = {}
    for _, p in ipairs(shape) do
        if IsVec2(p) then
            table.insert(result, p:toVec3(altitude))
        elseif IsVec3(p) then
            table.insert(result, p)
        else
            table.insert(result, Vec3(p.x, altitude, p.z))
        end
    end
    
    return result
end