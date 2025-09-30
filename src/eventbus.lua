--[[
    EventBus Module - minimal pub/sub for events

    - Subscribe by arbitrary topic key (number/string/any non-nil)
    - Optional predicate(event) -> boolean filters deliveries
    - Delivery enqueues the event table directly into the provided Queue
    - Supports multiple subscribers per event ID
    - Key selection is customizable; defaults to `event.id`
    - HarnessWorldEventBus integrates with `world.addEventHandler` lazily
]]

-- Single-handler approach: one handler instance per mission
local ACTIVE_HANDLER = nil

---@class EventBus
---@field _subscribers table<any, table> Map of topicKey -> array of subscriber records
---@field _nextSubId number
---@field _keySelector fun(event: table): any
---@return table EventBus
function EventBus(keySelector)
    local selector = nil
    if type(keySelector) == "function" then
        selector = keySelector
    else
        selector = function(event)
            return event and event.id
        end
    end

    local bus = { _subscribers = {}, _nextSubId = 1, _keySelector = selector }

    --- Subscribe to a topic key with optional predicate and a target queue
    ---@param topicKey any topic key to route on (must be non-nil)
    ---@param queue table Queue() instance receiving DTOs via :enqueue
    ---@param predicate fun(event: table): boolean Optional predicate to filter deliveries
    ---@return number? subscriptionId Returns an id to later unsubscribe, or nil on error
    function bus:subscribe(topicKey, queue, predicate)
        if topicKey == nil then return nil end
        if type(queue) ~= "table" or type(queue.enqueue) ~= "function" then return nil end
        if predicate ~= nil and type(predicate) ~= "function" then return nil end

        if not self._subscribers[topicKey] then
            self._subscribers[topicKey] = {}
        end

        local id = self._nextSubId
        self._nextSubId = self._nextSubId + 1

        table.insert(self._subscribers[topicKey], {
            id = id,
            queue = queue,
            predicate = predicate,
        })
        return id
    end

    --- Unsubscribe a previously created subscription id
    ---@param subscriptionId number
    ---@return boolean removed True if removed
    function bus:unsubscribe(subscriptionId)
        if type(subscriptionId) ~= "number" then return false end
        for eventId, list in pairs(self._subscribers) do
            for i = #list, 1, -1 do
                if list[i].id == subscriptionId then
                    table.remove(list, i)
                    if #list == 0 then
                        self._subscribers[eventId] = nil
                    end
                    return true
                end
            end
        end
        return false
    end

    --- Publish an event to subscribers of its derived topic key
    ---@param event table Event payload
    function bus:publish(event)
        if type(event) ~= "table" then return end
        local key = self._keySelector(event)
        if key == nil then return end
        local list = self._subscribers[key]
        if not list or #list == 0 then
            return
        end

        for i = 1, #list do
            local sub = list[i]
            local deliver = true
            if sub.predicate ~= nil then
                local ok, result = pcall(sub.predicate, event)
                deliver = ok and result == true
            end
            if deliver then
                pcall(sub.queue.enqueue, sub.queue, event)
            end
        end
    end

    return bus
end

---@class HarnessWorldEventBus : EventBus
---@field _handler table
---@return table HarnessWorldEventBus
function HarnessWorldEventBus()
    local bus = EventBus()
    bus._registered = false
    bus._totalSubs = 0

    bus._handler = { onEvent = function(self, event) bus:publish(event) end }

    local baseSubscribe = bus.subscribe
    function bus:subscribe(eventId, queue, predicate)
        local id = baseSubscribe(self, eventId, queue, predicate)
        if id then
            self._totalSubs = self._totalSubs + 1
            if (not self._registered) and world and type(world.addEventHandler) == "function" then
                world.addEventHandler(self._handler)
                self._registered = true
                ACTIVE_HANDLER = self._handler
            end
        end
        return id
    end

    local baseUnsubscribe = bus.unsubscribe
    function bus:unsubscribe(subscriptionId)
        local removed = baseUnsubscribe(self, subscriptionId)
        if removed then
            self._totalSubs = self._totalSubs - 1
            if self._totalSubs < 0 then self._totalSubs = 0 end
            if self._registered and self._totalSubs == 0 and world and type(world.removeEventHandler) == "function" then
                if ACTIVE_HANDLER == self._handler then
                    world.removeEventHandler(self._handler)
                    ACTIVE_HANDLER = nil
                end
                self._registered = false
            end
        end
        return removed
    end

    function bus:dispose()
        if self._registered and world and type(world.removeEventHandler) == "function" then
            if ACTIVE_HANDLER == self._handler then
                world.removeEventHandler(self._handler)
                ACTIVE_HANDLER = nil
            end
        end
        self._registered = false
        self._totalSubs = 0
    end

    return bus
end

-- Provide a globally accessible singleton for harness initialization if desired
HarnessWorldEventBusInstance = nil

--- Initialize global HarnessWorldEventBus if not already created
function InitHarnessWorldEventBus()
    if not HarnessWorldEventBusInstance then
        HarnessWorldEventBusInstance = HarnessWorldEventBus()
    end
    return HarnessWorldEventBusInstance
end

-- Lazy init only creates the instance; it will not register with world
InitHarnessWorldEventBus()


