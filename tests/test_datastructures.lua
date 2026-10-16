local lu = require("luaunit")

TestDataStructures = {}

function TestDataStructures:setUp()
    -- Save original timer if we need to mock it
    self.originalTimer = _G.timer
end

function TestDataStructures:tearDown()
    -- Restore original timer
    _G.timer = self.originalTimer
end

-- Queue Tests
function TestDataStructures:testQueue()
    local q = Queue()

    -- Test empty queue
    lu.assertTrue(q:isEmpty())
    lu.assertEquals(q:size(), 0)
    lu.assertNil(q:dequeue())
    lu.assertNil(q:peek())

    -- Test enqueue
    q:enqueue(1)
    q:enqueue(2)
    q:enqueue(3)

    lu.assertFalse(q:isEmpty())
    lu.assertEquals(q:size(), 3)
    lu.assertEquals(q:peek(), 1)

    -- Test dequeue (FIFO)
    lu.assertEquals(q:dequeue(), 1)
    lu.assertEquals(q:dequeue(), 2)
    lu.assertEquals(q:size(), 1)
    lu.assertEquals(q:dequeue(), 3)

    lu.assertTrue(q:isEmpty())

    -- Test clear
    q:enqueue("a")
    q:enqueue("b")
    q:clear()
    lu.assertTrue(q:isEmpty())
end

function TestDataStructures:testTimeWeightedStats()
    local stats = TimeWeightedStats()
    lu.assertTrue(stats:add(-2, 1, "left"))
    lu.assertTrue(stats:add(4, 3, "right"))
    lu.assertEquals(stats:count(), 2)
    lu.assertEquals(stats:duration(), 4)
    lu.assertEquals(stats:mean(), 2.5)
    lu.assertAlmostEquals(stats:rms(), math.sqrt(13), 1e-9)
    lu.assertEquals(stats:min(), -2)
    lu.assertEquals(stats:max(), 4)
    local peak, label = stats:peak()
    lu.assertEquals(peak, 4)
    lu.assertEquals(label, "right")
    lu.assertFalse(stats:add(0 / 0, 1))
    lu.assertFalse(stats:add(1, 0))
    lu.assertEquals(stats:count(), 2)
    stats:reset()
    lu.assertEquals(stats:count(), 0)
    lu.assertEquals(stats:duration(), 0)
    lu.assertNil(stats:mean())
    lu.assertNil(stats:rms())
    lu.assertNil(stats:min())
    lu.assertNil(stats:max())
    lu.assertNil(stats:peak())
end

function TestDataStructures:testTimeWeightedStatsPreservesSignedPeakAndLabel()
    local stats = TimeWeightedStats()
    lu.assertTrue(stats:add(3, 1, "right"))
    lu.assertTrue(stats:add(-5, 1, "left"))
    local peak, label = stats:peak()
    lu.assertEquals(peak, -5)
    lu.assertEquals(label, "left")
end

-- Stack Tests
function TestDataStructures:testStack()
    local s = Stack()

    -- Test empty stack
    lu.assertTrue(s:isEmpty())
    lu.assertEquals(s:size(), 0)
    lu.assertNil(s:pop())
    lu.assertNil(s:peek())

    -- Test push
    s:push(1)
    s:push(2)
    s:push(3)

    lu.assertFalse(s:isEmpty())
    lu.assertEquals(s:size(), 3)
    lu.assertEquals(s:peek(), 3)

    -- Test pop (LIFO)
    lu.assertEquals(s:pop(), 3)
    lu.assertEquals(s:pop(), 2)
    lu.assertEquals(s:size(), 1)
    lu.assertEquals(s:pop(), 1)

    lu.assertTrue(s:isEmpty())

    -- Test clear
    s:push("a")
    s:push("b")
    s:clear()
    lu.assertTrue(s:isEmpty())
end

-- Basic Cache Tests
function TestDataStructures:testCacheBasic()
    local cache = Cache(3)

    -- Test empty cache
    lu.assertNil(cache:get("key1"))
    lu.assertEquals(cache:dbsize(), 0)

    -- Test set and get
    lu.assertTrue(cache:set("key1", "value1"))
    lu.assertTrue(cache:set("key2", "value2"))
    lu.assertTrue(cache:set("key3", "value3"))

    lu.assertEquals(cache:get("key1"), "value1")
    lu.assertEquals(cache:get("key2"), "value2")
    lu.assertEquals(cache:get("key3"), "value3")
    lu.assertEquals(cache:dbsize(), 3)

    -- Test LRU eviction
    cache:set("key4", "value4") -- Should evict key1
    lu.assertNil(cache:get("key1"))
    lu.assertEquals(cache:get("key4"), "value4")
    lu.assertEquals(cache:dbsize(), 3)

    -- Test updating moves to front
    cache:get("key2") -- Move key2 to front
    cache:set("key5", "value5") -- Should evict key3
    lu.assertNil(cache:get("key3"))
    lu.assertEquals(cache:get("key2"), "value2")

    -- Test del
    lu.assertEquals(cache:del("key2"), 1)
    lu.assertEquals(cache:del("key2"), 0)
    lu.assertEquals(cache:dbsize(), 2)

    -- Test flushdb
    cache:flushdb()
    lu.assertEquals(cache:dbsize(), 0)
end

-- Advanced Cache Tests (Redis-like features)
function TestDataStructures:testCacheAdvanced()
    local cache = Cache() -- Unlimited capacity

    -- Test setnx
    lu.assertTrue(cache:setnx("key1", "value1"))
    lu.assertFalse(cache:setnx("key1", "value2"))
    lu.assertEquals(cache:get("key1"), "value1")

    -- Test exists
    lu.assertTrue(cache:exists("key1"))
    lu.assertFalse(cache:exists("key2"))

    -- Test del multiple keys
    cache:set("key2", "value2")
    cache:set("key3", "value3")
    lu.assertEquals(cache:del("key1", "key2", "key3", "key4"), 3)

    -- Test incr/decr
    cache:set("counter", 10)
    lu.assertEquals(cache:incr("counter"), 11)
    lu.assertEquals(cache:incr("counter", 5), 16)
    lu.assertEquals(cache:decr("counter"), 15)
    lu.assertEquals(cache:decr("counter", 3), 12)

    -- Test incr on new key
    lu.assertEquals(cache:incr("newcounter"), 1)

    -- Test incr on non-numeric
    cache:set("string", "hello")
    lu.assertNil(cache:incr("string"))

    -- Test keys pattern matching
    cache:set("user:1", "alice")
    cache:set("user:2", "bob")
    cache:set("admin:1", "charlie")

    local userKeys = cache:keys("user:.*")
    lu.assertEquals(#userKeys, 2)

    -- Test type
    cache:set("str", "hello")
    cache:set("num", 42)
    cache:set("tbl", { a = 1 })

    lu.assertEquals(cache:type("str"), "string")
    lu.assertEquals(cache:type("num"), "number")
    lu.assertEquals(cache:type("tbl"), "table")
    lu.assertEquals(cache:type("nonexist"), "none")

    -- Test flushdb
    cache:flushdb()
    lu.assertEquals(cache:dbsize(), 0)
end

-- Cache TTL Tests (need to mock timer)
function TestDataStructures:testCacheTTL()
    -- Mock timer for testing
    local currentTime = 1000
    _G.timer = {
        getTime = function()
            return currentTime
        end,
    }

    local cache = Cache()

    -- Test set with TTL
    cache:set("key1", "value1", 10)
    lu.assertEquals(cache:get("key1"), "value1")

    -- Test TTL
    lu.assertEquals(cache:ttl("key1"), 10)

    -- Advance time
    currentTime = 1005
    lu.assertEquals(cache:ttl("key1"), 5)

    -- Test expire
    cache:set("key2", "value2")
    lu.assertEquals(cache:ttl("key2"), -1) -- No TTL
    lu.assertTrue(cache:expire("key2", 20))
    lu.assertEquals(cache:ttl("key2"), 20)

    -- Test persist
    lu.assertTrue(cache:persist("key2"))
    lu.assertEquals(cache:ttl("key2"), -1)

    -- Test expiration
    currentTime = 1011
    lu.assertNil(cache:get("key1")) -- Should be expired
    lu.assertFalse(cache:exists("key1"))

    -- Test setex
    cache:setex("key3", 15, "value3")
    lu.assertEquals(cache:ttl("key3"), 15)
end

-- Heap Tests
function TestDataStructures:testMinHeap()
    local heap = Heap(true) -- Min heap

    -- Test empty heap
    lu.assertTrue(heap:isEmpty())
    lu.assertEquals(heap:size(), 0)
    lu.assertNil(heap:extract())
    lu.assertNil(heap:peek())

    -- Test insert
    heap:insert(5)
    heap:insert(3)
    heap:insert(7)
    heap:insert(1)
    heap:insert(9)
    heap:insert(2)

    lu.assertFalse(heap:isEmpty())
    lu.assertEquals(heap:size(), 6)
    lu.assertEquals(heap:peek(), 1)

    -- Test extract (should return in ascending order)
    lu.assertEquals(heap:extract(), 1)
    lu.assertEquals(heap:extract(), 2)
    lu.assertEquals(heap:extract(), 3)
    lu.assertEquals(heap:extract(), 5)
    lu.assertEquals(heap:extract(), 7)
    lu.assertEquals(heap:extract(), 9)

    lu.assertTrue(heap:isEmpty())
end

function TestDataStructures:testMaxHeap()
    local heap = Heap(false) -- Max heap

    heap:insert(5)
    heap:insert(3)
    heap:insert(7)
    heap:insert(1)
    heap:insert(9)
    heap:insert(2)

    lu.assertEquals(heap:peek(), 9)

    -- Test extract (should return in descending order)
    lu.assertEquals(heap:extract(), 9)
    lu.assertEquals(heap:extract(), 7)
    lu.assertEquals(heap:extract(), 5)
    lu.assertEquals(heap:extract(), 3)
    lu.assertEquals(heap:extract(), 2)
    lu.assertEquals(heap:extract(), 1)
end

function TestDataStructures:testHeapWithCustomCompare()
    -- Min heap for objects with priority
    local heap = Heap(true, function(a, b)
        return a.priority < b.priority
    end)

    heap:insert({ name = "task1", priority = 3 })
    heap:insert({ name = "task2", priority = 1 })
    heap:insert({ name = "task3", priority = 2 })

    local task = heap:extract()
    lu.assertEquals(task.name, "task2")
    lu.assertEquals(task.priority, 1)
end

-- Set Tests
function TestDataStructures:testSet()
    local set = Set()

    -- Test empty set
    lu.assertTrue(set:isEmpty())
    lu.assertEquals(set:size(), 0)
    lu.assertFalse(set:contains("item"))

    -- Test add
    lu.assertTrue(set:add("item1"))
    lu.assertTrue(set:add("item2"))
    lu.assertFalse(set:add("item1")) -- Duplicate

    lu.assertEquals(set:size(), 2)
    lu.assertTrue(set:contains("item1"))
    lu.assertTrue(set:contains("item2"))
    lu.assertFalse(set:contains("item3"))

    -- Test remove
    lu.assertTrue(set:remove("item1"))
    lu.assertFalse(set:remove("item1")) -- Already removed
    lu.assertEquals(set:size(), 1)

    -- Test toArray
    set:add("a")
    set:add("b")
    local array = set:toArray()
    lu.assertEquals(#array, 3)

    -- Test clear
    set:clear()
    lu.assertTrue(set:isEmpty())
end

function TestDataStructures:testSetOperations()
    local set1 = Set()
    set1:add(1)
    set1:add(2)
    set1:add(3)

    local set2 = Set()
    set2:add(2)
    set2:add(3)
    set2:add(4)

    -- Test union
    local union = set1:union(set2)
    lu.assertEquals(union:size(), 4)
    lu.assertTrue(union:contains(1))
    lu.assertTrue(union:contains(2))
    lu.assertTrue(union:contains(3))
    lu.assertTrue(union:contains(4))

    -- Test intersection
    local intersection = set1:intersection(set2)
    lu.assertEquals(intersection:size(), 2)
    lu.assertTrue(intersection:contains(2))
    lu.assertTrue(intersection:contains(3))

    -- Test difference
    local diff = set1:difference(set2)
    lu.assertEquals(diff:size(), 1)
    lu.assertTrue(diff:contains(1))
end

-- Priority Queue Tests
function TestDataStructures:testPriorityQueue()
    -- Default priority queue (using priority field)
    local pq = PriorityQueue()

    pq:enqueue("high", 1)
    pq:enqueue("low", 10)
    pq:enqueue("medium", 5)

    lu.assertEquals(pq:dequeue(), "high")
    lu.assertEquals(pq:dequeue(), "medium")
    lu.assertEquals(pq:dequeue(), "low")

    -- Custom comparison
    local pq2 = PriorityQueue(function(a, b)
        return a.score > b.score -- Higher score = higher priority
    end)

    pq2:enqueue({ name = "player1", score = 100 })
    pq2:enqueue({ name = "player2", score = 150 })
    pq2:enqueue({ name = "player3", score = 75 })

    local p = pq2:dequeue()
    lu.assertEquals(p.name, "player2")
    lu.assertEquals(p.score, 150)
end

-- RingBuffer Tests
function TestDataStructures:testRingBufferBasic()
    local rb = RingBuffer(3)

    -- Empty state
    lu.assertTrue(rb:isEmpty())
    lu.assertFalse(rb:isFull())
    lu.assertEquals(rb:size(), 0)
    lu.assertEquals(rb:capacity(), 3)
    lu.assertNil(rb:peek())
    lu.assertNil(rb:pop())

    -- Push within capacity
    local ok, ev = rb:push(1)
    lu.assertTrue(ok)
    lu.assertNil(ev)
    rb:push(2)
    rb:push(3)

    lu.assertFalse(rb:isEmpty())
    lu.assertTrue(rb:isFull())
    lu.assertEquals(rb:size(), 3)
    lu.assertEquals(rb:peek(), 1)
    lu.assertEquals(rb:get(1), 1)
    lu.assertEquals(rb:get(2), 2)
    lu.assertEquals(rb:get(3), 3)

    -- Overwrite when full
    ok, ev = rb:push(4)
    lu.assertTrue(ok)
    lu.assertEquals(ev, 1)
    lu.assertEquals(rb:toArray(), { 2, 3, 4 })

    -- Pop in order
    lu.assertEquals(rb:pop(), 2)
    lu.assertEquals(rb:pop(), 3)
    lu.assertEquals(rb:pop(), 4)
    lu.assertTrue(rb:isEmpty())

    -- Reset behavior
    rb:push("a")
    rb:push("b")
    lu.assertEquals(rb:toArray(), { "a", "b" })
    rb:clear()
    lu.assertTrue(rb:isEmpty())
end

function TestDataStructures:testRingBufferNoOverwrite()
    local rb = RingBuffer(2, false)
    lu.assertTrue(rb:push(10))
    lu.assertTrue(rb:push(20))
    local ok, ev = rb:push(30)
    lu.assertFalse(ok)
    lu.assertNil(ev)
    lu.assertEquals(rb:toArray(), { 10, 20 })
    lu.assertEquals(rb:pop(), 10)
    lu.assertTrue(rb:push(30))
    lu.assertEquals(rb:toArray(), { 20, 30 })
end

function TestDataStructures:testRingBufferRotate()
    local rb = RingBuffer(3, false)
    rb:push("first")
    rb:push("second")
    rb:push("third")

    lu.assertEquals(rb:rotate(), "first")
    lu.assertEquals(rb:toArray(), { "second", "third", "first" })
    lu.assertEquals(rb:size(), 3)
end

-- The O(index) walk RingBuffer:get used before 1.3.2, kept as the fuzz reference.
local function referenceRingGet(rb, index)
    if type(index) ~= "number" or index < 1 or index > rb._size then
        return nil
    end
    local pos = rb._head
    for _ = 2, index do
        pos = pos >= rb._capacity and 1 or pos + 1
    end
    return rb._items[pos]
end

local function assertRingContents(rb, expected)
    lu.assertEquals(rb:size(), #expected)
    for index = 1, #expected do
        lu.assertEquals(rb:get(index), expected[index])
    end
    lu.assertNil(rb:get(0))
    lu.assertNil(rb:get(#expected + 1))
end

function TestDataStructures:testRingBufferGetWrappedHeadAfterPopThenPush()
    local rb = RingBuffer(4, false)
    for value = 1, 4 do
        rb:push(value)
    end
    lu.assertEquals(rb:pop(), 1)
    lu.assertEquals(rb:pop(), 2)
    rb:push(5)
    rb:push(6)
    lu.assertEquals(rb._head, 3)
    lu.assertEquals(rb._tail, 2)
    assertRingContents(rb, { 3, 4, 5, 6 })
end

function TestDataStructures:testRingBufferGetAfterOverwriteWrap()
    local rb = RingBuffer(3)
    for value = 1, 8 do
        rb:push(value)
    end
    assertRingContents(rb, { 6, 7, 8 })
    rb:pop()
    assertRingContents(rb, { 7, 8 })
end

function TestDataStructures:testRingBufferGetAfterClearAndEmptyReset()
    local rb = RingBuffer(3)
    for value = 1, 5 do
        rb:push(value)
    end
    rb:clear()
    assertRingContents(rb, {})
    rb:push("a")
    assertRingContents(rb, { "a" })

    rb:push("b")
    rb:pop()
    rb:pop()
    lu.assertEquals(rb._head, 1)
    assertRingContents(rb, {})
    rb:push("c")
    rb:push("d")
    assertRingContents(rb, { "c", "d" })
end

function TestDataStructures:testRingBufferGetAfterRotate()
    local rb = RingBuffer(3, false)
    rb:push("first")
    rb:push("second")
    rb:push("third")
    rb:rotate()
    rb:rotate()
    assertRingContents(rb, { "third", "first", "second" })

    rb:pop()
    rb:rotate()
    assertRingContents(rb, { "second", "first" })
end

function TestDataStructures:testRingBufferGetFractionalAndNonFiniteIndex()
    local rb = RingBuffer(3)
    for value = 1, 4 do
        rb:push(value)
    end
    lu.assertEquals(rb:get(1.5), 2)
    lu.assertEquals(rb:get(2.999), 3)
    lu.assertNil(rb:get(0.999))
    lu.assertNil(rb:get(3.5))
    lu.assertNil(rb:get(0 / 0))
    lu.assertNil(rb:get(math.huge))
    lu.assertNil(rb:get(-math.huge))
    lu.assertNil(rb:get("1"))
    lu.assertNil(rb:get(nil))
end

function TestDataStructures:testRingBufferGetWithUnboundedCapacity()
    local rb = RingBuffer(math.huge)
    for value = 1, 5 do
        rb:push(value)
    end
    rb:pop()
    assertRingContents(rb, { 2, 3, 4, 5 })
end

local function nextFuzzValue(state)
    return (state * 16807) % 2147483647
end

local function applyFuzzOperation(rb, model, roll, value)
    if roll < 6 then
        local ok, evicted = rb:push(value)
        if rb._overwrite and #model == rb:capacity() then
            lu.assertEquals(evicted, table.remove(model, 1))
        end
        if ok then
            model[#model + 1] = value
        end
    elseif roll < 9 then
        lu.assertEquals(rb:pop(), table.remove(model, 1))
    elseif roll < 10 then
        local rotated = rb:rotate()
        lu.assertEquals(rotated, model[1])
        if rotated ~= nil then
            table.insert(model, table.remove(model, 1))
        end
    else
        rb:clear()
        for index = #model, 1, -1 do
            model[index] = nil
        end
    end
end

local function assertRingMatchesReference(rb, model)
    lu.assertEquals(rb:size(), #model)
    for index = -1, rb:size() + 2, 0.5 do
        lu.assertEquals(rb:get(index), referenceRingGet(rb, index))
    end
    for index = 1, #model do
        lu.assertEquals(rb:get(index), model[index])
    end
end

function TestDataStructures:testRingBufferGetMatchesReferenceWalk()
    local state = 12345
    for trial = 1, 60 do
        local capacity = trial % 7 + 1
        local rb = RingBuffer(capacity, trial % 2 == 0)
        local model = {}
        for step = 1, 200 do
            state = nextFuzzValue(state)
            applyFuzzOperation(rb, model, state % 41 == 0 and 10 or state % 10, step)
            assertRingMatchesReference(rb, model)
        end
    end
end

function TestDataStructures:testDeduplicatingQueueGetByPosition()
    local queue = DeduplicatingQueue(3, function(item)
        return item
    end)
    queue:push("a")
    queue:push("b")
    queue:push("c")
    queue:pop()
    queue:push("d")
    lu.assertEquals(queue:get(1), "b")
    lu.assertEquals(queue:get(2), "c")
    lu.assertEquals(queue:get(3), "d")
    lu.assertNil(queue:get(4))
    lu.assertNil(queue:get(0 / 0))
end

function TestDataStructures:testDeduplicatingQueue()
    local queue = DeduplicatingQueue(2, function(item)
        return item.id
    end)
    local first = { id = "first" }
    local second = { id = "second" }

    lu.assertTrue(queue:push(first))
    local accepted, duplicate = queue:push({ id = "first" })
    lu.assertFalse(accepted)
    lu.assertIs(duplicate, first)
    lu.assertTrue(queue:push(second))
    accepted, duplicate = queue:push({ id = "third" })
    lu.assertFalse(accepted)
    lu.assertNil(duplicate)

    first.id = "changed"
    lu.assertIs(queue:pop(), first)
    lu.assertTrue(queue:push({ id = "first" }))
    lu.assertEquals(queue:toArray(), { second, { id = "first" } })
end

function TestDataStructures:testIndexedPriorityQueue()
    local queue = IndexedPriorityQueue(3, function(left, right)
        return left.due < right.due or (left.due == right.due and left.order < right.order)
    end, function(item)
        return item.id
    end)
    local later = { id = "later", due = 2, order = 1 }
    local second = { id = "second", due = 1, order = 2 }
    local first = { id = "first", due = 1, order = 1 }

    lu.assertTrue(queue:push(later))
    lu.assertTrue(queue:push(second))
    lu.assertTrue(queue:push(first))
    local accepted, duplicate = queue:push({ id = "first", due = 0, order = 0 })
    lu.assertFalse(accepted)
    lu.assertIs(duplicate, first)
    accepted, duplicate = queue:push({ id = "full", due = 0, order = 0 })
    lu.assertFalse(accepted)
    lu.assertNil(duplicate)

    lu.assertIs(queue:remove("second"), second)
    lu.assertEquals(queue:toArray(), { first, later })
    lu.assertIs(queue:pop(), first)
    lu.assertIs(queue:pop(), later)
    lu.assertTrue(queue:isEmpty())
end

function TestDataStructures:testIndexedCollection()
    local collection = IndexedCollection({
        capacity = 2,
        key = "id",
        indexes = {
            { name = "name", key = "name", unique = true },
            { name = "team", key = "team" },
        },
    })
    local first = { id = "first", name = "alpha", team = "blue" }
    local second = { id = "second", name = "bravo", team = "blue" }

    lu.assertTrue(collection:add(first))
    lu.assertTrue(collection:add(second))
    local accepted, conflict, index = collection:add({ id = "first", name = "charlie" })
    lu.assertFalse(accepted)
    lu.assertIs(conflict, first)
    lu.assertNil(index)
    accepted, conflict = collection:add({ id = "third", name = "charlie" })
    lu.assertFalse(accepted)
    lu.assertNil(conflict)

    accepted, conflict, index = collection:replace({
        id = "first",
        name = "bravo",
        team = "red",
    })
    lu.assertFalse(accepted)
    lu.assertIs(conflict, second)
    lu.assertEquals(index, "name")
    lu.assertEquals(collection:getAll("team", "blue"), { first, second })

    local replacement = { id = "first", name = "alpha-2", team = "red" }
    local previous
    accepted, previous = collection:replace(replacement)
    lu.assertTrue(accepted)
    lu.assertIs(previous, first)
    lu.assertIs(collection:getUnique("name", "alpha-2"), replacement)
    lu.assertEquals(collection:getAll("team", "blue"), { second })
    lu.assertEquals(collection:values(), { replacement, second })
end

-- Memoize Tests
function TestDataStructures:testMemoize()
    -- Test basic memoization
    local callCount = 0
    local function expensive(x, y)
        callCount = callCount + 1
        return x + y
    end

    local memoized = Memoize(expensive, 10)

    -- First call
    lu.assertEquals(memoized(2, 3), 5)
    lu.assertEquals(callCount, 1)

    -- Cached call
    lu.assertEquals(memoized(2, 3), 5)
    lu.assertEquals(callCount, 1) -- Not called again

    -- Different args
    lu.assertEquals(memoized(3, 4), 7)
    lu.assertEquals(callCount, 2)

    -- Test with nil arguments
    local function withNils(a, b, c)
        return (a or 0) + (b or 0) + (c or 0)
    end

    local memoizedNils = Memoize(withNils)
    lu.assertEquals(memoizedNils(1, nil, 3), 4)
    lu.assertEquals(memoizedNils(1, nil, 3), 4) -- Cached
    lu.assertEquals(memoizedNils(nil, nil, nil), 0)
end

function TestDataStructures:testMemoizeMultipleReturns()
    -- Test function with multiple return values
    local callCount = 0
    local function multiReturn(x)
        callCount = callCount + 1
        return x * 2, x * 3, x * 4
    end

    local memoized = Memoize(multiReturn)

    local a, b, c = memoized(5)
    lu.assertEquals(a, 10)
    lu.assertEquals(b, 15)
    lu.assertEquals(c, 20)
    lu.assertEquals(callCount, 1)

    -- Cached call
    a, b, c = memoized(5)
    lu.assertEquals(a, 10)
    lu.assertEquals(b, 15)
    lu.assertEquals(c, 20)
    lu.assertEquals(callCount, 1) -- Not called again
end

function TestDataStructures:testMemoizeCustomKeyGenerator()
    -- Test with custom key generator
    local callCount = 0
    local function process(tbl)
        callCount = callCount + 1
        return tbl.x + tbl.y
    end

    -- Custom key generator that uses table fields
    local memoized = Memoize(process, 10, function(tbl)
        return tbl.x .. "," .. tbl.y
    end)

    local t1 = { x = 1, y = 2 }
    local t2 = { x = 1, y = 2 }

    lu.assertEquals(memoized(t1), 3)
    lu.assertEquals(callCount, 1)

    -- Different table but same content
    lu.assertEquals(memoized(t2), 3)
    lu.assertEquals(callCount, 1) -- Cached due to custom key
end

function TestDataStructures:testMemoizeLRU()
    -- Test LRU eviction
    local callCount = 0
    local function identity(x)
        callCount = callCount + 1
        return x
    end

    local memoized = Memoize(identity, 3) -- Small capacity

    -- Fill cache
    lu.assertEquals(memoized(1), 1)
    lu.assertEquals(memoized(2), 2)
    lu.assertEquals(memoized(3), 3)
    lu.assertEquals(callCount, 3)

    -- Add one more (should evict 1)
    lu.assertEquals(memoized(4), 4)
    lu.assertEquals(callCount, 4)

    -- Access 1 again (should recompute)
    lu.assertEquals(memoized(1), 1)
    lu.assertEquals(callCount, 5)

    -- Access 2 (was it evicted?)
    lu.assertEquals(memoized(2), 2)
    -- If count is 6, then 2 was evicted and recomputed
    -- The test expects 2 to still be cached, but it seems 2 was evicted
    -- Let's update the expectation to match actual LRU behavior
    lu.assertEquals(callCount, 6) -- 2 was evicted, so it's recomputed
end
