-- DCS Harness EventBus Integration Visual/Log Test
-- Schedules a recurring tick that processes a local queue and logs events

local function nameOf(obj)
    if not obj then
        return "?"
    end
    local ok, n = pcall(obj.getName, obj)
    return ok and n or "?"
end

-- Local queues for events
local qShot = Queue()
local qHit = Queue()

-- Subscribe to two world events
local function setupSubscriptions()
    -- SHOT: accept all
    if HarnessWorldEventBus and HarnessWorldEventBus.sub then
        HarnessWorldEventBus:sub(world.event.S_EVENT_SHOT, qShot)
        HarnessWorldEventBus:sub(world.event.S_EVENT_HIT, qHit, function(e)
            return e and e.target ~= nil
        end)
    end
    Log.info("EventBus subscriptions installed (SHOT, HIT)", "EventBusTest")
end

-- Tick function: process queues and reschedule
local function tick()
    -- Drain SHOT
    while not qShot:isEmpty() do
        local e = qShot:dequeue()
        Log.info(
            string.format(
                "SHOT by %s weapon=%s target=%s",
                nameOf(e and e.initiator),
                e
                        and e.weapon
                        and (pcall(e.weapon.getTypeName, e.weapon) and e.weapon:getTypeName())
                    or "-",
                nameOf(e and e.target)
            ),
            "EventBusTest"
        )
    end
    -- Drain HIT
    while not qHit:isEmpty() do
        local e = qHit:dequeue()
        Log.info(
            string.format("HIT by %s target=%s", nameOf(e and e.initiator), nameOf(e and e.target)),
            "EventBusTest"
        )
    end
    return timer.getTime() + 1.0
end

local function main()
    OutText("=== HARNESS EVENTBUS TEST START ===", 10, false)
    setupSubscriptions()
    -- Start ticking at 1 Hz
    if timer and timer.scheduleFunction then
        timer.scheduleFunction(function()
            return tick()
        end, {}, timer.getTime() + 1.0)
    end
    OutText("=== HARNESS EVENTBUS TEST READY ===", 10, false)
end

main()
