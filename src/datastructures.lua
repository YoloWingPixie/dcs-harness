--[[
==================================================================================================
    DATA STRUCTURES MODULE
    Common data structures optimized for DCS World scripting

    Structures Provided:
    - Queue
    - Stack
    - Cache
    - Heap/PriorityQueue
    - Set
    - Memoize
==================================================================================================
]]

-- Queue Implementation (FIFO - First In First Out)
--- Create a new Queue
---@return table queue New queue instance
---@usage local q = Queue()
function Queue()
    local queue = {
        _items = {},
        _first = 1,
        _last = 0,
    }

    --- Add item to back of queue
    ---@param item any Item to enqueue
    ---@usage queue:enqueue("item")
    function queue:enqueue(item)
        self._last = self._last + 1
        self._items[self._last] = item
    end

    --- Remove and return item from front of queue
    ---@return any? item Dequeued item or nil if empty
    ---@usage local item = queue:dequeue()
    function queue:dequeue()
        if self:isEmpty() then
            return nil
        end

        local item = self._items[self._first]
        self._items[self._first] = nil
        self._first = self._first + 1

        -- Reset indices when queue is empty to prevent index growth
        if self._first > self._last then
            self._first = 1
            self._last = 0
        end

        return item
    end

    --- Peek at front item without removing
    ---@return any? item Front item or nil if empty
    ---@usage local front = queue:peek()
    function queue:peek()
        if self:isEmpty() then
            return nil
        end
        return self._items[self._first]
    end

    --- Check if queue is empty
    ---@return boolean empty True if queue is empty
    ---@usage if queue:isEmpty() then ... end
    function queue:isEmpty()
        return self._first > self._last
    end

    --- Get number of items in queue
    ---@return number size Number of items
    ---@usage local size = queue:size()
    function queue:size()
        if self:isEmpty() then
            return 0
        end
        return self._last - self._first + 1
    end

    --- Clear all items from queue
    ---@usage queue:clear()
    function queue:clear()
        self._items = {}
        self._first = 1
        self._last = 0
    end

    return queue
end

--- Create a constant-size time-weighted statistics accumulator
---@return table stats Time-weighted statistics object
function TimeWeightedStats()
    local stats = {}

    function stats:reset()
        self._count = 0
        self._duration = 0
        self._sum = 0
        self._sumSquared = 0
        self._minimum = nil
        self._maximum = nil
        self._peakAbsolute = nil
        self._peakSigned = nil
        self._peakLabel = nil
        return nil
    end

    ---@param value number Sample value
    ---@param durationS number Sample duration in seconds
    ---@param label any? Label stored with a new absolute peak
    ---@return boolean accepted True when the sample was accepted
    function stats:add(value, durationS, label)
        if
            type(value) ~= "number"
            or value ~= value
            or value <= -math.huge
            or value >= math.huge
            or type(durationS) ~= "number"
            or durationS ~= durationS
            or durationS <= 0
            or durationS >= math.huge
        then
            return false
        end
        self._count = self._count + 1
        self._duration = self._duration + durationS
        self._sum = self._sum + value * durationS
        self._sumSquared = self._sumSquared + value * value * durationS
        self._minimum = self._minimum == nil and value or math.min(self._minimum, value)
        self._maximum = self._maximum == nil and value or math.max(self._maximum, value)
        local absolute = math.abs(value)
        if self._peakAbsolute == nil or absolute > self._peakAbsolute then
            self._peakAbsolute = absolute
            self._peakSigned = value
            self._peakLabel = label
        end
        return true
    end

    function stats:count()
        return self._count
    end

    function stats:duration()
        return self._duration
    end

    function stats:mean()
        return self._count > 0 and self._sum / self._duration or nil
    end

    function stats:rms()
        return self._count > 0 and math.sqrt(self._sumSquared / self._duration) or nil
    end

    function stats:min()
        return self._minimum
    end

    function stats:max()
        return self._maximum
    end

    function stats:peak()
        return self._peakSigned, self._peakLabel
    end

    stats:reset()
    return stats
end

-- Stack Implementation (LIFO - Last In First Out)
--- Create a new Stack
---@return table stack New stack instance
---@usage local s = Stack()
function Stack()
    local stack = {
        _items = {},
        _top = 0,
    }

    --- Push item onto stack
    ---@param item any Item to push
    ---@usage stack:push("item")
    function stack:push(item)
        self._top = self._top + 1
        self._items[self._top] = item
    end

    --- Pop and return top item from stack
    ---@return any? item Popped item or nil if empty
    ---@usage local item = stack:pop()
    function stack:pop()
        if self:isEmpty() then
            return nil
        end

        local item = self._items[self._top]
        self._items[self._top] = nil
        self._top = self._top - 1
        return item
    end

    --- Peek at top item without removing
    ---@return any? item Top item or nil if empty
    ---@usage local top = stack:peek()
    function stack:peek()
        if self:isEmpty() then
            return nil
        end
        return self._items[self._top]
    end

    --- Check if stack is empty
    ---@return boolean empty True if stack is empty
    ---@usage if stack:isEmpty() then ... end
    function stack:isEmpty()
        return self._top == 0
    end

    --- Get number of items in stack
    ---@return number size Number of items
    ---@usage local size = stack:size()
    function stack:size()
        return self._top
    end

    --- Clear all items from stack
    ---@usage stack:clear()
    function stack:clear()
        self._items = {}
        self._top = 0
    end

    return stack
end

-- Advanced Cache Implementation (Redis-like KV Store)
--- Create a new advanced Cache with Redis-like features
---@param capacity number? Maximum number of items to cache (default: unlimited)
---@return table cache New cache instance
---@usage local cache = Cache()
function Cache(capacity)
    -- Validate capacity
    if capacity ~= nil and type(capacity) ~= "number" then
        _HarnessInternal.log.error("Cache capacity must be a number", "DataStructures.Cache")
        capacity = nil
    end
    if capacity and capacity < 1 then
        _HarnessInternal.log.error("Cache capacity must be positive", "DataStructures.Cache")
        capacity = nil
    end

    local cache = {
        _capacity = capacity or math.huge,
        _items = {},
        _order = {},
        _size = 0,
        _ttls = {}, -- TTL expiration times
        _types = {}, -- Track data types
    }

    -- Internal: Check and remove expired items
    local function checkExpired(key)
        local ttl = cache._ttls[key]
        if ttl and timer and timer.getTime and timer.getTime() > ttl then
            cache:del(key)
            return true
        end
        return false
    end

    -- Internal: Get current time (DCS compatible)
    local function getCurrentTime()
        if timer and timer.getTime then
            return timer.getTime()
        end
        return os.time()
    end

    --- Get value from cache
    ---@param key string Cache key
    ---@return any? value Cached value or nil
    ---@usage local value = cache:get("key")
    function cache:get(key)
        if checkExpired(key) then
            return nil
        end

        local item = self._items[key]
        if not item then
            return nil
        end

        -- Move to front (most recently used) if capacity is limited
        if self._capacity ~= math.huge then
            self:_moveToFront(key)
        end

        return item.value
    end

    --- Set key-value pair with optional TTL
    ---@param key string Cache key
    ---@param value any Value to cache
    ---@param ttl number? Time to live in seconds
    ---@return boolean success Always returns true
    ---@usage cache:set("key", "value", 60) -- expires in 60 seconds
    function cache:set(key, value, ttl)
        local isNew = self._items[key] == nil

        if isNew and self._size >= self._capacity then
            -- Remove least recently used
            self:_removeLRU()
        end

        self._items[key] = { value = value }
        self._types[key] = type(value)

        if ttl and ttl > 0 then
            self._ttls[key] = getCurrentTime() + ttl
        else
            self._ttls[key] = nil
        end

        if self._capacity ~= math.huge then
            if isNew then
                table.insert(self._order, 1, key)
                self._size = self._size + 1
            else
                self:_moveToFront(key)
            end
        elseif isNew then
            self._size = self._size + 1
        end

        return true
    end

    --- Set key only if it doesn't exist
    ---@param key string Cache key
    ---@param value any Value to cache
    ---@param ttl number? Time to live in seconds
    ---@return boolean success True if set, false if key exists
    ---@usage cache:setnx("key", "value")
    function cache:setnx(key, value, ttl)
        if self:exists(key) then
            return false
        end
        return self:set(key, value, ttl)
    end

    --- Set with expiration time
    ---@param key string Cache key
    ---@param seconds number TTL in seconds
    ---@param value any Value to cache
    ---@return boolean success Always returns true
    ---@usage cache:setex("key", 60, "value")
    function cache:setex(key, seconds, value)
        return self:set(key, value, seconds)
    end

    --- Delete key(s)
    ---@param ... string Keys to delete
    ---@return number count Number of keys deleted
    ---@usage cache:del("key1", "key2")
    function cache:del(...)
        local count = 0
        for i = 1, select("#", ...) do
            local key = select(i, ...)
            if self._items[key] then
                self._items[key] = nil
                self._types[key] = nil
                self._ttls[key] = nil
                if self._capacity ~= math.huge then
                    self:_removeFromOrder(key)
                end
                self._size = self._size - 1
                count = count + 1
            end
        end
        return count
    end

    --- Check if key exists
    ---@param key string Cache key
    ---@return boolean exists True if key exists and not expired
    ---@usage if cache:exists("key") then ... end
    function cache:exists(key)
        if checkExpired(key) then
            return false
        end
        return self._items[key] ~= nil
    end

    --- Set expiration time
    ---@param key string Cache key
    ---@param seconds number TTL in seconds
    ---@return boolean success True if expiration was set
    ---@usage cache:expire("key", 60)
    function cache:expire(key, seconds)
        if not self:exists(key) then
            return false
        end
        self._ttls[key] = getCurrentTime() + seconds
        return true
    end

    --- Get remaining TTL
    ---@param key string Cache key
    ---@return number ttl Seconds until expiration, -1 if no TTL, -2 if not exists
    ---@usage local ttl = cache:ttl("key")
    function cache:ttl(key)
        if not self._items[key] then
            return -2
        end

        local ttl = self._ttls[key]
        if not ttl then
            return -1
        end

        local remaining = ttl - getCurrentTime()
        if remaining <= 0 then
            self:del(key)
            return -2
        end

        return math.floor(remaining)
    end

    --- Remove expiration
    ---@param key string Cache key
    ---@return boolean success True if expiration was removed
    ---@usage cache:persist("key")
    function cache:persist(key)
        if not self:exists(key) then
            return false
        end
        self._ttls[key] = nil
        return true
    end

    --- Increment numeric value
    ---@param key string Cache key
    ---@param increment number? Amount to increment (default: 1)
    ---@return number? value New value or nil if not numeric
    ---@usage local newVal = cache:incr("counter")
    function cache:incr(key, increment)
        increment = increment or 1
        local value = self:get(key) or 0

        if type(value) ~= "number" then
            _HarnessInternal.log.error("INCR requires numeric value", "DataStructures.Cache")
            return nil
        end

        local newValue = value + increment
        self:set(key, newValue)
        return newValue
    end

    --- Decrement numeric value
    ---@param key string Cache key
    ---@param decrement number? Amount to decrement (default: 1)
    ---@return number? value New value or nil if not numeric
    ---@usage local newVal = cache:decr("counter")
    function cache:decr(key, decrement)
        return self:incr(key, -(decrement or 1))
    end

    --- Get all keys matching pattern
    ---@param pattern string? Lua pattern (default: ".*" for all)
    ---@return table keys Array of matching keys
    ---@usage local keys = cache:keys("user:*")
    function cache:keys(pattern)
        pattern = pattern or ".*"
        local keys = {}

        for key, _ in pairs(self._items) do
            if not checkExpired(key) and string.match(key, pattern) then
                table.insert(keys, key)
            end
        end

        return keys
    end

    --- Get data type of key
    ---@param key string Cache key
    ---@return string type Type of value ("string", "number", "table", etc) or "none"
    ---@usage local type = cache:type("key")
    function cache:type(key)
        if not self:exists(key) then
            return "none"
        end
        return self._types[key] or type(self._items[key].value)
    end

    --- Clear all items (flush database)
    ---@usage cache:flushdb()
    function cache:flushdb()
        self._items = {}
        self._order = {}
        self._size = 0
        self._ttls = {}
        self._types = {}
    end

    --- Get current cache size
    ---@return number size Number of cached items
    ---@usage local size = cache:dbsize()
    function cache:dbsize()
        -- Clean up expired items first
        for key, _ in pairs(self._ttls) do
            checkExpired(key)
        end
        return self._size
    end

    -- Internal: Move key to front of order list (for LRU)
    function cache:_moveToFront(key)
        self:_removeFromOrder(key)
        table.insert(self._order, 1, key)
    end

    -- Internal: Remove key from order list
    function cache:_removeFromOrder(key)
        for i, k in ipairs(self._order) do
            if k == key then
                table.remove(self._order, i)
                break
            end
        end
    end

    -- Internal: Remove least recently used item
    function cache:_removeLRU()
        local lru = table.remove(self._order)
        if lru then
            self:del(lru)
        end
    end

    return cache
end

-- Memoize Decorator (LRU Cache for Functions)
--- Create a memoized version of a function with LRU cache
---@param func function The function to memoize
---@param capacity number? Maximum number of cached results (default: 128)
---@param keyGenerator function? Custom key generator function(...) -> string (default: concatenate args)
---@return function memoized Memoized version of the function
---@usage local memoizedSin = Memoize(math.sin, 100)
function Memoize(func, capacity, keyGenerator)
    if type(func) ~= "function" then
        _HarnessInternal.log.error("Memoize requires a function", "DataStructures.Memoize")
        return func
    end

    capacity = capacity or 128

    -- Default key generator: convert args to string and concatenate
    keyGenerator = keyGenerator
        or function(...)
            local args = { ... }
            local key = ""
            for i = 1, select("#", ...) do
                if i > 1 then
                    key = key .. "|"
                end
                local arg = args[i]
                local argType = type(arg)
                if argType == "nil" then
                    key = key .. "nil"
                elseif argType == "boolean" then
                    key = key .. tostring(arg)
                elseif argType == "number" or argType == "string" then
                    key = key .. arg
                elseif argType == "table" then
                    -- Simple table serialization (not recursive)
                    key = key .. "table:" .. tostring(arg)
                else
                    key = key .. argType .. ":" .. tostring(arg)
                end
            end
            return key
        end

    local cache = {
        _capacity = capacity,
        _items = {},
        _order = {},
        _size = 0,
    }

    -- Internal: Move key to front of order list
    local function moveToFront(key)
        for i, k in ipairs(cache._order) do
            if k == key then
                table.remove(cache._order, i)
                break
            end
        end
        table.insert(cache._order, 1, key)
    end

    -- Internal: Remove least recently used item
    local function removeLRU()
        local lru = table.remove(cache._order)
        if lru then
            cache._items[lru] = nil
            cache._size = cache._size - 1
        end
    end

    -- Memoized function
    return function(...)
        local key = keyGenerator(...)

        -- Check cache
        local cached = cache._items[key]
        if cached then
            moveToFront(key)
            return unpack(cached.results, 1, cached.n)
        end

        -- Call original function and capture all returns
        local function captureReturns(...)
            return select("#", ...), { ... }
        end

        local n, results = captureReturns(func(...))

        -- Store in cache
        if cache._size >= cache._capacity then
            removeLRU()
        end

        cache._items[key] = { results = results, n = n }
        table.insert(cache._order, 1, key)
        cache._size = cache._size + 1

        return unpack(results, 1, n)
    end
end

-- Min/Max Heap Implementation
--- Create a new Heap (binary heap)
---@param isMinHeap boolean? True for min heap, false for max heap (default: true)
---@param compareFunc function? Custom comparison function(a, b) returns true if a should be higher
---@return table heap New heap instance
---@usage local minHeap = Heap() or local maxHeap = Heap(false)
function Heap(isMinHeap, compareFunc)
    -- Validate parameters
    if isMinHeap ~= nil and type(isMinHeap) ~= "boolean" then
        _HarnessInternal.log.error("Heap isMinHeap must be boolean", "DataStructures.Heap")
        isMinHeap = true
    end
    if compareFunc ~= nil and type(compareFunc) ~= "function" then
        _HarnessInternal.log.error("Heap compareFunc must be a function", "DataStructures.Heap")
        compareFunc = nil
    end

    isMinHeap = isMinHeap ~= false -- Default to min heap

    local heap = {
        _items = {},
        _size = 0,
        _compare = compareFunc or function(a, b)
            if isMinHeap then
                return a < b
            else
                return a > b
            end
        end,
    }

    --- Insert item into heap
    ---@param item any Item to insert
    ---@usage heap:insert(5)
    function heap:insert(item)
        self._size = self._size + 1
        self._items[self._size] = item
        self:_bubbleUp(self._size)
    end

    --- Remove and return top item (min or max)
    ---@return any? item Top item or nil if empty
    ---@usage local top = heap:extract()
    function heap:extract()
        if self:isEmpty() then
            return nil
        end

        local top = self._items[1]
        self._items[1] = self._items[self._size]
        self._items[self._size] = nil
        self._size = self._size - 1

        if self._size > 0 then
            self:_bubbleDown(1)
        end

        return top
    end

    --- Peek at top item without removing
    ---@return any? item Top item or nil if empty
    ---@usage local top = heap:peek()
    function heap:peek()
        return self._items[1]
    end

    --- Check if heap is empty
    ---@return boolean empty True if heap is empty
    ---@usage if heap:isEmpty() then ... end
    function heap:isEmpty()
        return self._size == 0
    end

    --- Get number of items in heap
    ---@return number size Number of items
    ---@usage local size = heap:size()
    function heap:size()
        return self._size
    end

    --- Clear all items from heap
    ---@usage heap:clear()
    function heap:clear()
        self._items = {}
        self._size = 0
    end

    -- Internal: Bubble up to maintain heap property
    function heap:_bubbleUp(index)
        while index > 1 do
            local parent = math.floor(index / 2)
            if self._compare(self._items[index], self._items[parent]) then
                self._items[index], self._items[parent] = self._items[parent], self._items[index]
                index = parent
            else
                break
            end
        end
    end

    -- Internal: Bubble down to maintain heap property
    function heap:_bubbleDown(index)
        while true do
            local smallest = index
            local left = 2 * index
            local right = 2 * index + 1

            if left <= self._size and self._compare(self._items[left], self._items[smallest]) then
                smallest = left
            end

            if right <= self._size and self._compare(self._items[right], self._items[smallest]) then
                smallest = right
            end

            if smallest ~= index then
                self._items[index], self._items[smallest] =
                    self._items[smallest], self._items[index]
                index = smallest
            else
                break
            end
        end
    end

    return heap
end

-- Set Implementation (unique values)
--- Create a new Set
---@return table set New set instance
---@usage local set = Set()
function Set()
    local set = {
        _items = {},
        _size = 0,
    }

    --- Add item to set
    ---@param item any Item to add
    ---@return boolean added True if item was added (not already present)
    ---@usage set:add("item")
    function set:add(item)
        if self._items[item] ~= nil then
            return false
        end
        self._items[item] = true
        self._size = self._size + 1
        return true
    end

    --- Remove item from set
    ---@param item any Item to remove
    ---@return boolean removed True if item was removed
    ---@usage set:remove("item")
    function set:remove(item)
        if self._items[item] == nil then
            return false
        end
        self._items[item] = nil
        self._size = self._size - 1
        return true
    end

    --- Check if set contains item
    ---@param item any Item to check
    ---@return boolean contains True if set contains item
    ---@usage if set:contains("item") then ... end
    function set:contains(item)
        return self._items[item] ~= nil
    end

    --- Get number of items in set
    ---@return number size Number of items
    ---@usage local size = set:size()
    function set:size()
        return self._size
    end

    --- Check if set is empty
    ---@return boolean empty True if set is empty
    ---@usage if set:isEmpty() then ... end
    function set:isEmpty()
        return self._size == 0
    end

    --- Clear all items from set
    ---@usage set:clear()
    function set:clear()
        self._items = {}
        self._size = 0
    end

    --- Get array of all items
    ---@return table items Array of set items
    ---@usage local items = set:toArray()
    function set:toArray()
        local array = {}
        for item, _ in pairs(self._items) do
            table.insert(array, item)
        end
        return array
    end

    --- Create union with another set
    ---@param other table Another set
    ---@return table union New set containing items from both sets
    ---@usage local union = set1:union(set2)
    function set:union(other)
        local result = Set()
        for item, _ in pairs(self._items) do
            result:add(item)
        end
        for item, _ in pairs(other._items) do
            result:add(item)
        end
        return result
    end

    --- Create intersection with another set
    ---@param other table Another set
    ---@return table intersection New set containing common items
    ---@usage local common = set1:intersection(set2)
    function set:intersection(other)
        local result = Set()
        for item, _ in pairs(self._items) do
            if other:contains(item) then
                result:add(item)
            end
        end
        return result
    end

    --- Create difference with another set
    ---@param other table Another set
    ---@return table difference New set containing items in this but not other
    ---@usage local diff = set1:difference(set2)
    function set:difference(other)
        local result = Set()
        for item, _ in pairs(self._items) do
            if not other:contains(item) then
                result:add(item)
            end
        end
        return result
    end

    return set
end

-- Priority Queue Implementation (using heap)
--- Create a new Priority Queue
---@param compareFunc function? Comparison function(a, b) returns true if a has higher priority
---@return table pqueue New priority queue instance
---@usage local pq = PriorityQueue(function(a, b) return a.priority < b.priority end)
function PriorityQueue(compareFunc)
    -- Validate compareFunc
    if compareFunc ~= nil and type(compareFunc) ~= "function" then
        _HarnessInternal.log.error(
            "PriorityQueue compareFunc must be a function",
            "DataStructures.PriorityQueue"
        )
        compareFunc = nil
    end

    local heapCompareFunc = nil
    if not compareFunc then
        -- Default comparison for items with priority field
        heapCompareFunc = function(a, b)
            return a.priority < b.priority
        end
    end

    local pqueue = {
        _heap = Heap(true, heapCompareFunc or compareFunc),
    }

    --- Add item with priority
    ---@param item any Item to add
    ---@param priority number? Priority (used if no compareFunc provided)
    ---@usage pqueue:enqueue(task, 5)
    function pqueue:enqueue(item, priority)
        if not compareFunc and priority then
            self._heap:insert({ item = item, priority = priority })
        else
            self._heap:insert(item)
        end
    end

    --- Remove and return highest priority item
    ---@return any? item Highest priority item or nil if empty
    ---@usage local task = pqueue:dequeue()
    function pqueue:dequeue()
        local result = self._heap:extract()
        if result and result.item then
            return result.item
        end
        return result
    end

    --- Peek at highest priority item
    ---@return any? item Highest priority item or nil if empty
    ---@usage local next = pqueue:peek()
    function pqueue:peek()
        local result = self._heap:peek()
        if result and result.item then
            return result.item
        end
        return result
    end

    --- Check if queue is empty
    ---@return boolean empty True if queue is empty
    ---@usage if pqueue:isEmpty() then ... end
    function pqueue:isEmpty()
        return self._heap:isEmpty()
    end

    --- Get number of items
    ---@return number size Number of items
    ---@usage local size = pqueue:size()
    function pqueue:size()
        return self._heap:size()
    end

    --- Clear all items
    ---@usage pqueue:clear()
    function pqueue:clear()
        self._heap:clear()
    end

    return pqueue
end

-- RingBuffer Implementation (fixed-capacity circular buffer)
--- Create a new RingBuffer
---@param capacity number Buffer capacity (> 0)
---@param overwrite boolean? Overwrite oldest when full (default: true)
---@return table ring New ring buffer instance
---@usage local rb = RingBuffer(3)
function RingBuffer(capacity, overwrite)
    if type(capacity) ~= "number" or capacity < 1 then
        _HarnessInternal.log.error(
            "RingBuffer capacity must be positive number",
            "DataStructures.RingBuffer"
        )
        capacity = 1
    end

    local ring = {
        _items = {},
        _capacity = math.floor(capacity),
        _size = 0,
        _head = 1, -- index of logical front
        _tail = 0, -- index of last inserted
        _overwrite = overwrite ~= false, -- default true
    }

    local function nextIndex(index)
        if index >= ring._capacity then
            return 1
        end
        return index + 1
    end

    --- Add item to buffer tail
    ---@param item any Item to push
    ---@return boolean success True if inserted (or overwritten)
    ---@return any? evicted Evicted item if overwrite occurred
    ---@usage local ok, evicted = ring:push(value)
    function ring:push(item)
        if self._size < self._capacity then
            self._tail = nextIndex(self._tail)
            self._items[self._tail] = item
            self._size = self._size + 1
            return true, nil
        end

        if self._overwrite then
            local evicted = self._items[self._head]
            self._head = nextIndex(self._head)
            self._tail = nextIndex(self._tail)
            self._items[self._tail] = item
            return true, evicted
        end

        return false, nil
    end

    --- Remove and return item from buffer head
    ---@return any? item Popped item or nil if empty
    ---@usage local item = ring:pop()
    function ring:pop()
        if self:isEmpty() then
            return nil
        end

        local item = self._items[self._head]
        self._items[self._head] = nil
        self._head = nextIndex(self._head)
        self._size = self._size - 1

        if self._size == 0 then
            -- reset indices for cleanliness
            self._head = 1
            self._tail = 0
        end

        return item
    end

    --- Move the head item to the tail
    ---@return any? item Rotated item or nil if empty
    function ring:rotate()
        local item = self:pop()
        if item ~= nil then
            self:push(item)
        end
        return item
    end

    --- Peek at head item without removing
    ---@return any? item Head item or nil if empty
    ---@usage local front = ring:peek()
    function ring:peek()
        if self:isEmpty() then
            return nil
        end
        return self._items[self._head]
    end

    --- Get logical item by 1-based index (1 = head)
    ---@param index number 1-based index into buffer contents
    ---@return any? item Item at index or nil
    function ring:get(index)
        if type(index) ~= "number" or index < 1 or index > self._size then
            return nil
        end
        local pos = self._head
        for _ = 2, index do
            pos = nextIndex(pos)
        end
        return self._items[pos]
    end

    local function prevIndex(index)
        if index <= 1 then
            return ring._capacity
        end
        return index - 1
    end

    --- Iterate from newest to oldest, calling fn for each item
    ---@param fn function Callback receiving (item, index). Return false to stop early.
    ---@usage ring:reverseIter(function(item, i) if item.age > 5 then return false end end)
    function ring:reverseIter(fn)
        if self._size == 0 or type(fn) ~= "function" then
            return
        end
        local pos = self._tail
        for i = 1, self._size do
            local result = fn(self._items[pos], i)
            if result == false then
                return
            end
            pos = prevIndex(pos)
        end
    end

    --- Convert contents to array (head to tail order)
    ---@return table items Array of items
    function ring:toArray()
        local arr = {}
        local pos = self._head
        for i = 1, self._size do
            arr[i] = self._items[pos]
            pos = nextIndex(pos)
        end
        return arr
    end

    --- Check if buffer is empty
    ---@return boolean empty True if empty
    function ring:isEmpty()
        return self._size == 0
    end

    --- Check if buffer is full
    ---@return boolean full True if full
    function ring:isFull()
        return self._size == self._capacity
    end

    --- Current number of items
    ---@return number size Number of items
    function ring:size()
        return self._size
    end

    --- Buffer capacity
    ---@return number capacity Capacity
    function ring:capacity()
        return self._capacity
    end

    --- Clear all items
    function ring:clear()
        self._items = {}
        self._size = 0
        self._head = 1
        self._tail = 0
    end

    return ring
end

--- Create a fixed-capacity queue that retains one item per key
---@param capacity number Queue capacity
---@param keyFunction fun(item: any): any Stable key for an item
---@return table queue New deduplicating queue
function DeduplicatingQueue(capacity, keyFunction)
    local queue = {
        _ring = RingBuffer(capacity, false),
        _keys = {},
    }

    --- Add an item unless its key exists or the queue is full
    ---@param item any Item to push
    ---@return boolean accepted True if the item was retained
    ---@return any? duplicate Existing item with the same key
    function queue:push(item)
        local key = keyFunction(item)
        if key == nil or (type(key) == "number" and key ~= key) then
            error("DeduplicatingQueue key must not be nil or NaN")
        end
        local duplicate = self._keys[key]
        if duplicate then
            return false, duplicate.item
        end
        local entry = { item = item, key = key }
        if not self._ring:push(entry) then
            return false, nil
        end
        self._keys[key] = entry
        return true, nil
    end

    --- Remove and return the head item
    ---@return any? item Popped item or nil if empty
    function queue:pop()
        local entry = self._ring:pop()
        if not entry then
            return nil
        end
        self._keys[entry.key] = nil
        return entry.item
    end

    --- Read the head item
    ---@return any? item Head item or nil if empty
    function queue:peek()
        local entry = self._ring:peek()
        return entry and entry.item or nil
    end

    --- Read an item by queue position
    ---@param index number One-based queue position
    ---@return any? item Item at the position or nil
    function queue:get(index)
        local entry = self._ring:get(index)
        return entry and entry.item or nil
    end

    --- Return items in queue order
    ---@return table items Items from head to tail
    function queue:toArray()
        local entries = self._ring:toArray()
        local items = {}
        for index = 1, #entries do
            items[index] = entries[index].item
        end
        return items
    end

    function queue:size()
        return self._ring:size()
    end

    function queue:capacity()
        return self._ring:capacity()
    end

    function queue:isEmpty()
        return self._ring:isEmpty()
    end

    function queue:isFull()
        return self._ring:isFull()
    end

    function queue:clear()
        self._ring:clear()
        self._keys = {}
    end

    return queue
end

--- Create a fixed-capacity priority queue with key-based removal
---@param capacity number Queue capacity
---@param compareFunction fun(left: any, right: any): boolean Priority comparison
---@param keyFunction fun(item: any): any Stable key for an item
---@return table queue New indexed priority queue
function IndexedPriorityQueue(capacity, compareFunction, keyFunction)
    if type(capacity) ~= "number" or capacity < 1 then
        error("IndexedPriorityQueue capacity must be positive")
    end
    capacity = math.floor(capacity)

    local queue = {
        _capacity = capacity,
        _items = {},
        _indexes = {},
        _size = 0,
    }

    local function precedes(left, right)
        return compareFunction(left.item, right.item)
    end

    local function swap(left, right)
        queue._items[left], queue._items[right] = queue._items[right], queue._items[left]
        queue._indexes[queue._items[left].key] = left
        queue._indexes[queue._items[right].key] = right
    end

    local function siftUp(index)
        while index > 1 do
            local parent = math.floor(index / 2)
            if not precedes(queue._items[index], queue._items[parent]) then
                break
            end
            swap(index, parent)
            index = parent
        end
        return index
    end

    local function siftDown(index)
        while true do
            local left = index * 2
            if left > queue._size then
                return
            end
            local right = left + 1
            local nextIndex = right <= queue._size
                    and precedes(queue._items[right], queue._items[left])
                    and right
                or left
            if not precedes(queue._items[nextIndex], queue._items[index]) then
                return
            end
            swap(index, nextIndex)
            index = nextIndex
        end
    end

    local function removeAt(index)
        if not index or index < 1 or index > queue._size then
            return nil
        end
        local removed = queue._items[index]
        local last = queue._items[queue._size]
        queue._items[queue._size] = nil
        queue._indexes[removed.key] = nil
        queue._size = queue._size - 1
        if index <= queue._size then
            queue._items[index] = last
            queue._indexes[last.key] = index
            siftDown(siftUp(index))
        end
        return removed.item
    end

    --- Add an item unless its key exists or the queue is full
    ---@param item any Item to push
    ---@return boolean accepted True if the item was retained
    ---@return any? duplicate Existing item with the same key
    function queue:push(item)
        local key = keyFunction(item)
        if key == nil or (type(key) == "number" and key ~= key) then
            error("IndexedPriorityQueue key must not be nil or NaN")
        end
        local index = self._indexes[key]
        if index then
            return false, self._items[index].item
        end
        if self._size >= self._capacity then
            return false, nil
        end
        self._size = self._size + 1
        self._items[self._size] = { item = item, key = key }
        self._indexes[key] = self._size
        siftUp(self._size)
        return true, nil
    end

    --- Remove and return the highest-priority item
    ---@return any? item Removed item or nil if empty
    function queue:pop()
        return removeAt(1)
    end

    --- Read the highest-priority item
    ---@return any? item Highest-priority item or nil if empty
    function queue:peek()
        return self._items[1] and self._items[1].item or nil
    end

    --- Read an item by heap position
    ---@param index number One-based heap position
    ---@return any? item Item at the position or nil
    function queue:get(index)
        return self._items[index] and self._items[index].item or nil
    end

    --- Remove an item by key
    ---@param key any Item key
    ---@return any? item Removed item or nil if absent
    function queue:remove(key)
        return removeAt(self._indexes[key])
    end

    --- Return items in priority order
    ---@return table items Ordered items
    function queue:toArray()
        local entries = {}
        for index = 1, self._size do
            entries[index] = self._items[index]
        end
        table.sort(entries, precedes)
        local items = {}
        for index = 1, #entries do
            items[index] = entries[index].item
        end
        return items
    end

    function queue:size()
        return self._size
    end

    function queue:capacity()
        return self._capacity
    end

    function queue:isEmpty()
        return self._size == 0
    end

    function queue:isFull()
        return self._size >= self._capacity
    end

    function queue:clear()
        self._items = {}
        self._indexes = {}
        self._size = 0
    end

    return queue
end

--- Create a fixed-capacity keyed collection with secondary indexes
---@param specification table Collection capacity, primary key, and index definitions
---@return table collection New indexed collection
function IndexedCollection(specification)
    local capacity = specification.capacity
    if type(capacity) ~= "number" or capacity < 1 or capacity ~= math.floor(capacity) then
        error("IndexedCollection capacity must be a positive integer")
    end

    local function accessor(value)
        if type(value) == "function" then
            return value
        end
        if type(value) ~= "string" or value == "" then
            error("IndexedCollection keys must be field names or functions")
        end
        return function(record)
            return record[value]
        end
    end

    local collection = {
        _capacity = capacity,
        _key = accessor(specification.key),
        _byKey = {},
        _order = {},
        _indexValues = {},
        _indexes = {},
        _indexesByName = {},
    }

    for position = 1, #(specification.indexes or {}) do
        local definition = specification.indexes[position]
        if type(definition.name) ~= "string" or definition.name == "" then
            error("IndexedCollection indexes require a name")
        end
        if collection._indexesByName[definition.name] then
            error("Duplicate IndexedCollection index: " .. definition.name)
        end
        local index = {
            name = definition.name,
            key = accessor(definition.key),
            unique = definition.unique == true,
            values = {},
        }
        collection._indexes[position] = index
        collection._indexesByName[index.name] = index
    end

    local function clear(array)
        for index = #array, 1, -1 do
            array[index] = nil
        end
    end

    local function usableKey(value)
        return value ~= nil and (type(value) ~= "number" or value == value)
    end

    local function indexValues(record, primaryKey)
        local values = {}
        for position = 1, #collection._indexes do
            local index = collection._indexes[position]
            local value = index.key(record)
            if value ~= nil and not usableKey(value) then
                error("IndexedCollection index keys must not be NaN")
            end
            if value ~= nil and index.unique then
                local indexedKey = index.values[value]
                if indexedKey ~= nil and indexedKey ~= primaryKey then
                    return nil, collection._byKey[indexedKey], index.name
                end
            end
            values[position] = value
        end
        return values
    end

    local function removeIndexes(primaryKey, values)
        for position = 1, #collection._indexes do
            local index = collection._indexes[position]
            local value = values[position]
            if value ~= nil and index.unique then
                index.values[value] = nil
            elseif value ~= nil then
                local bucket = index.values[value]
                bucket[primaryKey] = nil
                if next(bucket) == nil then
                    index.values[value] = nil
                end
            end
        end
    end

    local function addIndexes(primaryKey, record, values)
        for position = 1, #collection._indexes do
            local index = collection._indexes[position]
            local value = values[position]
            if value ~= nil and index.unique then
                index.values[value] = primaryKey
            elseif value ~= nil then
                local bucket = index.values[value]
                if not bucket then
                    bucket = {}
                    index.values[value] = bucket
                end
                bucket[primaryKey] = record
            end
        end
    end

    local function recordValues(record)
        if type(record) ~= "table" then
            error("IndexedCollection records must be tables")
        end
        local primaryKey = collection._key(record)
        if not usableKey(primaryKey) then
            error("IndexedCollection records require a key")
        end
        local values, conflict, index = indexValues(record, primaryKey)
        return primaryKey, values, conflict, index
    end

    --- Add a record
    ---@param record table Record to add
    ---@return boolean accepted True if the record was added
    ---@return table? conflict Existing record or nil when capacity is full
    ---@return string? index Conflicting unique index name
    function collection:add(record)
        local primaryKey, values, conflict, index = recordValues(record)
        if conflict then
            return false, conflict, index
        end
        local existing = self._byKey[primaryKey]
        if existing then
            return false, existing
        end
        if #self._order >= self._capacity then
            return false
        end
        self._byKey[primaryKey] = record
        self._order[#self._order + 1] = primaryKey
        self._indexValues[primaryKey] = values
        addIndexes(primaryKey, record, values)
        return true
    end

    --- Replace a record with the same primary key
    ---@param record table Replacement record
    ---@return boolean replaced True if the record was replaced
    ---@return table? previous Previous or conflicting record
    ---@return string? index Conflicting unique index name
    function collection:replace(record)
        local primaryKey, values, conflict, index = recordValues(record)
        if conflict then
            return false, conflict, index
        end
        local previous = self._byKey[primaryKey]
        if not previous then
            return false
        end
        removeIndexes(primaryKey, self._indexValues[primaryKey])
        self._byKey[primaryKey] = record
        self._indexValues[primaryKey] = values
        addIndexes(primaryKey, record, values)
        return true, previous
    end

    --- Remove a record by primary key
    ---@param primaryKey any Record key
    ---@return table? record Removed record or nil
    function collection:remove(primaryKey)
        local record = self._byKey[primaryKey]
        if not record then
            return nil
        end
        removeIndexes(primaryKey, self._indexValues[primaryKey])
        self._byKey[primaryKey] = nil
        self._indexValues[primaryKey] = nil
        for position = 1, #self._order do
            if self._order[position] == primaryKey then
                table.remove(self._order, position)
                break
            end
        end
        return record
    end

    --- Read a record by primary key
    ---@param primaryKey any Record key
    ---@return table? record Current record or nil
    function collection:get(primaryKey)
        return self._byKey[primaryKey]
    end

    --- Return records selected by a set of primary keys
    ---@param primaryKeys table? Set of record keys
    ---@param resultLimit number? Maximum returned records
    ---@param output table? Reusable output array
    ---@return table records Matching records
    function collection:getByKeys(primaryKeys, resultLimit, output)
        local records = output or {}
        clear(records)
        local limit = resultLimit and math.max(0, math.floor(resultLimit)) or #self._order
        if type(primaryKeys) ~= "table" or limit == 0 then
            return records
        end
        for primaryKey in pairs(primaryKeys) do
            local record = self._byKey[primaryKey]
            if record then
                records[#records + 1] = record
                if #records >= limit then
                    break
                end
            end
        end
        return records
    end

    --- Read a record through a unique index
    ---@param indexName string Index name
    ---@param value any Indexed value
    ---@return table? record Matching record or nil
    function collection:getUnique(indexName, value)
        local index = self._indexesByName[indexName]
        if not index or not index.unique then
            error("Unknown unique IndexedCollection index: " .. tostring(indexName))
        end
        return self._byKey[index.values[value]]
    end

    --- Return records through a non-unique index
    ---@param indexName string Index name
    ---@param value any Indexed value
    ---@param output table? Reusable output array
    ---@return table records Matching records in insertion order
    function collection:getAll(indexName, value, output)
        local index = self._indexesByName[indexName]
        if not index or index.unique then
            error("Unknown non-unique IndexedCollection index: " .. tostring(indexName))
        end
        local records = output or {}
        clear(records)
        local bucket = index.values[value]
        if bucket then
            for position = 1, #self._order do
                local record = bucket[self._order[position]]
                if record then
                    records[#records + 1] = record
                end
            end
        end
        return records
    end

    --- Return all records in insertion order
    ---@param output table? Reusable output array
    ---@return table records Current records
    function collection:values(output)
        local records = output or {}
        clear(records)
        for position = 1, #self._order do
            records[position] = self._byKey[self._order[position]]
        end
        return records
    end

    function collection:count()
        return #self._order
    end

    function collection:capacity()
        return self._capacity
    end

    return collection
end
