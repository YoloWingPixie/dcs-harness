local lu = require("luaunit")

TestEventBus = {}

function TestEventBus:test_subscribe_and_publish_no_predicate()
    local bus = EventBus()
    local q = Queue()

    local subId = bus:subscribe(world.event.S_EVENT_SHOT, q)
    lu.assertNotNil(subId)

    local event = { id = world.event.S_EVENT_SHOT, time = 1.23, initiator = Unit.getByName("u1") }
    bus:publish(event)

    local received = q:dequeue()
    lu.assertNotNil(received)
    lu.assertEquals(received.id, event.id)
    lu.assertEquals(received.time, event.time)
end

function TestEventBus:test_predicate_filters()
    local bus = EventBus()
    local q = Queue()

    local subId = bus:subscribe(
        world.event.S_EVENT_HIT,
        q,
        function(e)
            return e.comment == "deliver"
        end
    )
    lu.assertNotNil(subId)

    bus:publish({ id = world.event.S_EVENT_HIT, comment = "drop" })
    lu.assertTrue(q:isEmpty())

    bus:publish({ id = world.event.S_EVENT_HIT, comment = "deliver" })
    lu.assertFalse(q:isEmpty())
    local received = q:dequeue()
    lu.assertEquals(received.comment, "deliver")
end

function TestEventBus:test_multiple_subscribers_same_event()
    local bus = EventBus()
    local q1 = Queue()
    local q2 = Queue()

    bus:subscribe(world.event.S_EVENT_TAKEOFF, q1)
    bus:subscribe(world.event.S_EVENT_TAKEOFF, q2, function(e)
        return e.flag == true
    end)

    bus:publish({ id = world.event.S_EVENT_TAKEOFF, flag = false })
    lu.assertFalse(q1:isEmpty())
    lu.assertTrue(q2:isEmpty())
    q1:clear()

    bus:publish({ id = world.event.S_EVENT_TAKEOFF, flag = true })
    lu.assertFalse(q1:isEmpty())
    lu.assertFalse(q2:isEmpty())
end

function TestEventBus:test_unsubscribe()
    local bus = EventBus()
    local q = Queue()
    local id = bus:subscribe(world.event.S_EVENT_LAND, q)
    lu.assertTrue(bus:unsubscribe(id))
    bus:publish({ id = world.event.S_EVENT_LAND })
    lu.assertTrue(q:isEmpty())
end


