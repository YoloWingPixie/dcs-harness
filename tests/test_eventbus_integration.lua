-- selene: allow(undefined_field, need-check-nil)
local lu = require("luaunit")

TestEventBusIntegration = {}

function TestEventBusIntegration:setUp()
    -- Override world.addEventHandler to capture the handler
    self._origAdd = world.addEventHandler
    self._origRemove = world.removeEventHandler
    self._captured = nil
    world.addEventHandler = function(handler)
        self._captured = handler
        return true
    end
    world.removeEventHandler = function(handler)
        if self._captured == handler then
            self._captured = nil
        end
        return true
    end

    -- Ensure a fresh global instance between tests to force re-registration
    if HarnessWorldEventBus and HarnessWorldEventBus.dispose then
        HarnessWorldEventBus:dispose()
    end
    HarnessWorldEventBus = nil
    HarnessWorldEventBusInstance = nil
    InitHarnessWorldEventBus()
end

function TestEventBusIntegration:tearDown()
    -- Restore world functions
    if self._origAdd then
        world.addEventHandler = self._origAdd
    end
    if self._origRemove then
        world.removeEventHandler = self._origRemove
    end
end

function TestEventBusIntegration:test_world_handler_delivery()
    local q = Queue()
    local eventId = world.event.S_EVENT_SHOT
    local bus = HarnessWorldEventBus or HarnessWorldEventBusInstance
    lu.assertNotNil(bus)
    local subscribe = bus and (bus.sub or bus.subscribe)
    if not subscribe then
        lu.fail("bus.subscribe is nil")
        return
    end
    local sub = subscribe(bus, eventId, q)
    lu.assertNotNil(sub)

    -- Simulate world raising event via handler pathway
    local evt = { id = eventId, time = 2.5, comment = "from world" }
    -- Call the captured handler directly to mimic DCS dispatch
    lu.assertNotNil(self._captured)
    self._captured:onEvent(evt)

    local dto = q:dequeue()
    lu.assertNotNil(dto)
    lu.assertEquals(dto.id, eventId)
    lu.assertEquals(dto.comment, "from world")
end
