local lu = require("luaunit")

TestDrawingGeometry = {}

function TestDrawingGeometry:testRejectsInvalidInput()
    lu.assertNil(ProcessDrawingGeometry(nil))
    lu.assertNil(ProcessDrawingGeometry("drawing"))
end

function TestDrawingGeometry:testProcessesLinePointsAndColors()
    local geometry = ProcessDrawingGeometry({
        name = "Route",
        primitiveType = "Line",
        lineMode = "segments",
        closed = true,
        mapX = 100,
        mapY = 200,
        colorString = "red",
        fillColorString = "blue",
        points = {
            { x = 5, y = 10 },
            { x = -5, y = -10 },
        },
    })

    lu.assertEquals(geometry.lineMode, "segments")
    lu.assertTrue(geometry.closed)
    lu.assertEquals(geometry.points, {
        { x = 105, y = 0, z = 210 },
        { x = 95, y = 0, z = 190 },
    })
    lu.assertEquals(geometry.color, "red")
    lu.assertEquals(geometry.fillColor, "blue")
end

function TestDrawingGeometry:testProcessesPolygonDimensions()
    local circle = ProcessDrawingGeometry({
        primitiveType = "Polygon",
        polygonMode = "circle",
        mapX = 10,
        mapY = 20,
        radius = 30,
    })
    local rectangle = ProcessDrawingGeometry({
        primitiveType = "Polygon",
        polygonMode = "rect",
        mapX = 10,
        mapY = 20,
        width = 30,
        height = 40,
    })
    local oval = ProcessDrawingGeometry({
        primitiveType = "Polygon",
        polygonMode = "oval",
        mapX = 10,
        mapY = 20,
        r1 = 30,
        r2 = 40,
        angle = 45,
    })

    lu.assertEquals(circle.radius, 30)
    lu.assertEquals(circle.center, { x = 10, y = 0, z = 20 })
    lu.assertEquals(rectangle.width, 30)
    lu.assertEquals(rectangle.height, 40)
    lu.assertEquals(rectangle.angle, 0)
    lu.assertEquals(oval.r1, 30)
    lu.assertEquals(oval.r2, 40)
    lu.assertEquals(oval.angle, 45)
end

function TestDrawingGeometry:testProcessesPolygonPoints()
    local arrow = ProcessDrawingGeometry({
        primitiveType = "Polygon",
        polygonMode = "arrow",
        mapX = 10,
        mapY = 20,
        length = 30,
        points = { { x = 1, y = 2 } },
    })
    local free = ProcessDrawingGeometry({
        primitiveType = "Polygon",
        polygonMode = "free",
        mapX = 10,
        mapY = 20,
        points = { { x = 3, y = 4 } },
    })

    lu.assertEquals(arrow.length, 30)
    lu.assertEquals(arrow.angle, 0)
    lu.assertEquals(arrow.points, { { x = 11, y = 0, z = 22 } })
    lu.assertEquals(free.points, { { x = 13, y = 0, z = 24 } })
end

function TestDrawingGeometry:testProcessesIconDefaults()
    local geometry = ProcessDrawingGeometry({
        primitiveType = "Icon",
        mapX = 10,
        mapY = 20,
        file = "icon.png",
    })

    lu.assertEquals(geometry.file, "icon.png")
    lu.assertEquals(geometry.scale, 1)
    lu.assertEquals(geometry.angle, 0)
    lu.assertEquals(geometry.position, { x = 10, y = 0, z = 20 })
end

return TestDrawingGeometry
