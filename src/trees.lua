--[[
==================================================================================================
    TREE STRUCTURES MODULE
    Tree data structures for DCS World scripting
==================================================================================================
]]

-- Binary Search Tree Node
local function BSTNode(key, value)
    return {
        key = key,
        value = value,
        left = nil,
        right = nil,
        parent = nil
    }
end

-- Binary Search Tree Implementation
--- Create a new Binary Search Tree
---@param compareFunc function? Custom comparison function(a, b) returns -1, 0, or 1
---@return table bst New BST instance
---@usage local bst = BinarySearchTree()
function BinarySearchTree(compareFunc)
    local bst = {
        _root = nil,
        _size = 0,
        _compare = compareFunc or function(a, b)
            if a < b then return -1
            elseif a > b then return 1
            else return 0 end
        end
    }
    
    --- Insert key-value pair
    ---@param key any Key to insert
    ---@param value any? Value associated with key
    ---@usage bst:insert(5, "five")
    function bst:insert(key, value)
        local newNode = BSTNode(key, value)
        
        if not self._root then
            self._root = newNode
            self._size = self._size + 1
            return
        end
        
        local current = self._root
        while true do
            local cmp = self._compare(key, current.key)
            if cmp == 0 then
                -- Update existing value
                current.value = value
                return
            elseif cmp < 0 then
                if not current.left then
                    current.left = newNode
                    newNode.parent = current
                    self._size = self._size + 1
                    return
                end
                current = current.left
            else
                if not current.right then
                    current.right = newNode
                    newNode.parent = current
                    self._size = self._size + 1
                    return
                end
                current = current.right
            end
        end
    end
    
    --- Find value by key
    ---@param key any Key to search for
    ---@return any? value Value if found, nil otherwise
    ---@usage local value = bst:find(5)
    function bst:find(key)
        local node = self:_findNode(key)
        return node and node.value or nil
    end
    
    --- Remove key from tree
    ---@param key any Key to remove
    ---@return boolean removed True if key was removed
    ---@usage bst:remove(5)
    function bst:remove(key)
        local node = self:_findNode(key)
        if not node then
            return false
        end
        
        self:_removeNode(node)
        self._size = self._size - 1
        return true
    end
    
    --- Get minimum key
    ---@return any? key Minimum key or nil if empty
    ---@usage local min = bst:min()
    function bst:min()
        if not self._root then return nil end
        local node = self:_minNode(self._root)
        return node.key
    end
    
    --- Get maximum key
    ---@return any? key Maximum key or nil if empty
    ---@usage local max = bst:max()
    function bst:max()
        if not self._root then return nil end
        local node = self:_maxNode(self._root)
        return node.key
    end
    
    --- Check if tree contains key
    ---@param key any Key to check
    ---@return boolean contains True if tree contains key
    ---@usage if bst:contains(5) then ... end
    function bst:contains(key)
        return self:_findNode(key) ~= nil
    end
    
    --- Get number of nodes
    ---@return number size Number of nodes
    ---@usage local size = bst:size()
    function bst:size()
        return self._size
    end
    
    --- Check if tree is empty
    ---@return boolean empty True if tree is empty
    ---@usage if bst:isEmpty() then ... end
    function bst:isEmpty()
        return self._size == 0
    end
    
    --- Clear all nodes
    ---@usage bst:clear()
    function bst:clear()
        self._root = nil
        self._size = 0
    end
    
    --- In-order traversal
    ---@param callback function Function(key, value) called for each node
    ---@usage bst:inorder(function(k, v) print(k, v) end)
    function bst:inorder(callback)
        self:_inorderRecursive(self._root, callback)
    end
    
    --- Get array of keys in sorted order
    ---@return table keys Array of keys
    ---@usage local keys = bst:keys()
    function bst:keys()
        local keys = {}
        self:inorder(function(k, v) table.insert(keys, k) end)
        return keys
    end
    
    -- Internal methods
    function bst:_findNode(key)
        local current = self._root
        while current do
            local cmp = self._compare(key, current.key)
            if cmp == 0 then
                return current
            elseif cmp < 0 then
                current = current.left
            else
                current = current.right
            end
        end
        return nil
    end
    
    function bst:_minNode(node)
        while node.left do
            node = node.left
        end
        return node
    end
    
    function bst:_maxNode(node)
        while node.right do
            node = node.right
        end
        return node
    end
    
    function bst:_removeNode(node)
        if not node.left and not node.right then
            -- Leaf node
            if node.parent then
                if node.parent.left == node then
                    node.parent.left = nil
                else
                    node.parent.right = nil
                end
            else
                self._root = nil
            end
        elseif not node.left or not node.right then
            -- One child
            local child = node.left or node.right
            if node.parent then
                if node.parent.left == node then
                    node.parent.left = child
                else
                    node.parent.right = child
                end
                child.parent = node.parent
            else
                self._root = child
                child.parent = nil
            end
        else
            -- Two children - replace with inorder successor
            local successor = self:_minNode(node.right)
            node.key = successor.key
            node.value = successor.value
            self:_removeNode(successor)
        end
    end
    
    function bst:_inorderRecursive(node, callback)
        if not node then return end
        self:_inorderRecursive(node.left, callback)
        callback(node.key, node.value)
        self:_inorderRecursive(node.right, callback)
    end
    
    return bst
end

-- Red-Black Tree Node
local RBColor = { RED = 1, BLACK = 2 }

local function RBNode(key, value)
    return {
        key = key,
        value = value,
        color = RBColor.RED,
        left = nil,
        right = nil,
        parent = nil
    }
end

-- Sentinel node for RB tree
local RBNil = {
    color = RBColor.BLACK,
    left = nil,
    right = nil,
    parent = nil
}

-- Red-Black Tree Implementation
--- Create a new Red-Black Tree (self-balancing BST)
---@param compareFunc function? Custom comparison function(a, b) returns -1, 0, or 1
---@return table rbtree New RB tree instance
---@usage local rbt = RedBlackTree()
function RedBlackTree(compareFunc)
    local rbt = {
        _root = RBNil,
        _size = 0,
        _compare = compareFunc or function(a, b)
            if a < b then return -1
            elseif a > b then return 1
            else return 0 end
        end
    }
    
    --- Insert key-value pair
    ---@param key any Key to insert
    ---@param value any? Value associated with key
    ---@usage rbt:insert(5, "five")
    function rbt:insert(key, value)
        local newNode = RBNode(key, value)
        newNode.left = RBNil
        newNode.right = RBNil
        
        local parent = nil
        local current = self._root
        
        while current ~= RBNil do
            parent = current
            local cmp = self._compare(key, current.key)
            if cmp == 0 then
                -- Update existing value
                current.value = value
                return
            elseif cmp < 0 then
                current = current.left
            else
                current = current.right
            end
        end
        
        newNode.parent = parent
        
        if parent == nil then
            self._root = newNode
        elseif self._compare(key, parent.key) < 0 then
            parent.left = newNode
        else
            parent.right = newNode
        end
        
        self._size = self._size + 1
        self:_insertFixup(newNode)
    end
    
    --- Find value by key
    ---@param key any Key to search for
    ---@return any? value Value if found, nil otherwise
    ---@usage local value = rbt:find(5)
    function rbt:find(key)
        local node = self:_findNode(key)
        return (node ~= RBNil) and node.value or nil
    end
    
    --- Remove key from tree
    ---@param key any Key to remove
    ---@return boolean removed True if key was removed
    ---@usage rbt:remove(5)
    function rbt:remove(key)
        local node = self:_findNode(key)
        if node == RBNil then
            return false
        end
        
        self:_removeNode(node)
        self._size = self._size - 1
        return true
    end
    
    --- Get minimum key
    ---@return any? key Minimum key or nil if empty
    ---@usage local min = rbt:min()
    function rbt:min()
        if self._root == RBNil then return nil end
        local node = self:_minNode(self._root)
        return node.key
    end
    
    --- Get maximum key
    ---@return any? key Maximum key or nil if empty
    ---@usage local max = rbt:max()
    function rbt:max()
        if self._root == RBNil then return nil end
        local node = self:_maxNode(self._root)
        return node.key
    end
    
    --- Get number of nodes
    ---@return number size Number of nodes
    ---@usage local size = rbt:size()
    function rbt:size()
        return self._size
    end
    
    --- Check if tree is empty
    ---@return boolean empty True if tree is empty
    ---@usage if rbt:isEmpty() then ... end
    function rbt:isEmpty()
        return self._size == 0
    end
    
    --- Clear all nodes
    ---@usage rbt:clear()
    function rbt:clear()
        self._root = RBNil
        self._size = 0
    end
    
    -- Internal methods
    function rbt:_findNode(key)
        local current = self._root
        while current ~= RBNil do
            local cmp = self._compare(key, current.key)
            if cmp == 0 then
                return current
            elseif cmp < 0 then
                current = current.left
            else
                current = current.right
            end
        end
        return RBNil
    end
    
    function rbt:_minNode(node)
        while node.left ~= RBNil do
            node = node.left
        end
        return node
    end
    
    function rbt:_maxNode(node)
        while node.right ~= RBNil do
            node = node.right
        end
        return node
    end
    
    function rbt:_rotateLeft(x)
        local y = x.right
        x.right = y.left
        
        if y.left ~= RBNil then
            y.left.parent = x
        end
        
        y.parent = x.parent
        
        if x.parent == nil then
            self._root = y
        elseif x == x.parent.left then
            x.parent.left = y
        else
            x.parent.right = y
        end
        
        y.left = x
        x.parent = y
    end
    
    function rbt:_rotateRight(x)
        local y = x.left
        x.left = y.right
        
        if y.right ~= RBNil then
            y.right.parent = x
        end
        
        y.parent = x.parent
        
        if x.parent == nil then
            self._root = y
        elseif x == x.parent.right then
            x.parent.right = y
        else
            x.parent.left = y
        end
        
        y.right = x
        x.parent = y
    end
    
    function rbt:_insertFixup(z)
        while z.parent and z.parent.color == RBColor.RED do
            if z.parent == z.parent.parent.left then
                local y = z.parent.parent.right
                if y.color == RBColor.RED then
                    z.parent.color = RBColor.BLACK
                    y.color = RBColor.BLACK
                    z.parent.parent.color = RBColor.RED
                    z = z.parent.parent
                else
                    if z == z.parent.right then
                        z = z.parent
                        self:_rotateLeft(z)
                    end
                    z.parent.color = RBColor.BLACK
                    z.parent.parent.color = RBColor.RED
                    self:_rotateRight(z.parent.parent)
                end
            else
                local y = z.parent.parent.left
                if y.color == RBColor.RED then
                    z.parent.color = RBColor.BLACK
                    y.color = RBColor.BLACK
                    z.parent.parent.color = RBColor.RED
                    z = z.parent.parent
                else
                    if z == z.parent.left then
                        z = z.parent
                        self:_rotateRight(z)
                    end
                    z.parent.color = RBColor.BLACK
                    z.parent.parent.color = RBColor.RED
                    self:_rotateLeft(z.parent.parent)
                end
            end
        end
        self._root.color = RBColor.BLACK
    end
    
    function rbt:_removeNode(z)
        local y = z
        local yOrigColor = y.color
        local x
        
        if z.left == RBNil then
            x = z.right
            self:_transplant(z, z.right)
        elseif z.right == RBNil then
            x = z.left
            self:_transplant(z, z.left)
        else
            y = self:_minNode(z.right)
            yOrigColor = y.color
            x = y.right
            
            if y.parent == z then
                x.parent = y
            else
                self:_transplant(y, y.right)
                y.right = z.right
                y.right.parent = y
            end
            
            self:_transplant(z, y)
            y.left = z.left
            y.left.parent = y
            y.color = z.color
        end
        
        if yOrigColor == RBColor.BLACK then
            self:_deleteFixup(x)
        end
    end
    
    function rbt:_transplant(u, v)
        if u.parent == nil then
            self._root = v
        elseif u == u.parent.left then
            u.parent.left = v
        else
            u.parent.right = v
        end
        v.parent = u.parent
    end
    
    function rbt:_deleteFixup(x)
        while x ~= self._root and x.color == RBColor.BLACK do
            if x == x.parent.left then
                local w = x.parent.right
                if w.color == RBColor.RED then
                    w.color = RBColor.BLACK
                    x.parent.color = RBColor.RED
                    self:_rotateLeft(x.parent)
                    w = x.parent.right
                end
                
                if w.left.color == RBColor.BLACK and w.right.color == RBColor.BLACK then
                    w.color = RBColor.RED
                    x = x.parent
                else
                    if w.right.color == RBColor.BLACK then
                        w.left.color = RBColor.BLACK
                        w.color = RBColor.RED
                        self:_rotateRight(w)
                        w = x.parent.right
                    end
                    w.color = x.parent.color
                    x.parent.color = RBColor.BLACK
                    w.right.color = RBColor.BLACK
                    self:_rotateLeft(x.parent)
                    x = self._root
                end
            else
                local w = x.parent.left
                if w.color == RBColor.RED then
                    w.color = RBColor.BLACK
                    x.parent.color = RBColor.RED
                    self:_rotateRight(x.parent)
                    w = x.parent.left
                end
                
                if w.right.color == RBColor.BLACK and w.left.color == RBColor.BLACK then
                    w.color = RBColor.RED
                    x = x.parent
                else
                    if w.left.color == RBColor.BLACK then
                        w.right.color = RBColor.BLACK
                        w.color = RBColor.RED
                        self:_rotateLeft(w)
                        w = x.parent.left
                    end
                    w.color = x.parent.color
                    x.parent.color = RBColor.BLACK
                    w.left.color = RBColor.BLACK
                    self:_rotateRight(x.parent)
                    x = self._root
                end
            end
        end
        x.color = RBColor.BLACK
    end
    
    return rbt
end

-- Trie (Prefix Tree) Implementation
--- Create a new Trie for string operations
---@return table trie New trie instance
---@usage local trie = Trie()
function Trie()
    local trie = {
        _root = { children = {}, isEnd = false },
        _size = 0
    }
    
    --- Insert word into trie
    ---@param word string Word to insert
    ---@usage trie:insert("hello")
    function trie:insert(word)
        if type(word) ~= "string" then
            _HarnessInternal.log.error("Trie:insert requires string", "Trees.Trie")
            return
        end
        
        local node = self._root
        local isNew = false
        
        for i = 1, #word do
            local char = word:sub(i, i)
            if not node.children[char] then
                node.children[char] = { children = {}, isEnd = false }
                isNew = true
            end
            node = node.children[char]
        end
        
        if not node.isEnd then
            node.isEnd = true
            self._size = self._size + 1
        end
    end
    
    --- Search for word in trie
    ---@param word string Word to search for
    ---@return boolean found True if word exists
    ---@usage if trie:search("hello") then ... end
    function trie:search(word)
        if type(word) ~= "string" then
            return false
        end
        
        local node = self._root
        for i = 1, #word do
            local char = word:sub(i, i)
            if not node.children[char] then
                return false
            end
            node = node.children[char]
        end
        
        return node.isEnd
    end
    
    --- Check if any word starts with prefix
    ---@param prefix string Prefix to check
    ---@return boolean hasPrefix True if any word has this prefix
    ---@usage if trie:startsWith("hel") then ... end
    function trie:startsWith(prefix)
        if type(prefix) ~= "string" then
            return false
        end
        
        local node = self._root
        for i = 1, #prefix do
            local char = prefix:sub(i, i)
            if not node.children[char] then
                return false
            end
            node = node.children[char]
        end
        
        return true
    end
    
    --- Get all words with given prefix
    ---@param prefix string? Prefix to search (empty for all words)
    ---@return table words Array of words with prefix
    ---@usage local words = trie:wordsWithPrefix("hel")
    function trie:wordsWithPrefix(prefix)
        prefix = prefix or ""
        if type(prefix) ~= "string" then
            return {}
        end
        
        local node = self._root
        for i = 1, #prefix do
            local char = prefix:sub(i, i)
            if not node.children[char] then
                return {}
            end
            node = node.children[char]
        end
        
        local words = {}
        self:_collectWords(node, prefix, words)
        return words
    end
    
    --- Delete word from trie
    ---@param word string Word to delete
    ---@return boolean deleted True if word was deleted
    ---@usage trie:delete("hello")
    function trie:delete(word)
        if type(word) ~= "string" then
            return false
        end
        
        if not self:search(word) then
            return false
        end
        
        self:_deleteHelper(self._root, word, 1)
        self._size = self._size - 1
        return true
    end
    
    --- Get number of words in trie
    ---@return number size Number of words
    ---@usage local count = trie:size()
    function trie:size()
        return self._size
    end
    
    --- Check if trie is empty
    ---@return boolean empty True if trie is empty
    ---@usage if trie:isEmpty() then ... end
    function trie:isEmpty()
        return self._size == 0
    end
    
    --- Clear all words
    ---@usage trie:clear()
    function trie:clear()
        self._root = { children = {}, isEnd = false }
        self._size = 0
    end
    
    -- Internal methods
    function trie:_collectWords(node, prefix, words)
        if node.isEnd then
            table.insert(words, prefix)
        end
        
        for char, child in pairs(node.children) do
            self:_collectWords(child, prefix .. char, words)
        end
    end
    
    function trie:_deleteHelper(node, word, index)
        if index > #word then
            node.isEnd = false
            return next(node.children) == nil and not node.isEnd
        end
        
        local char = word:sub(index, index)
        local child = node.children[char]
        
        if not child then
            return false
        end
        
        local shouldDelete = self:_deleteHelper(child, word, index + 1)
        
        if shouldDelete then
            node.children[char] = nil
            return next(node.children) == nil and not node.isEnd
        end
        
        return false
    end
    
    return trie
end

-- AVL Tree Node
local function AVLNode(key, value)
    return {
        key = key,
        value = value,
        height = 1,
        left = nil,
        right = nil
    }
end

-- AVL Tree Implementation (self-balancing BST)
--- Create a new AVL Tree
---@param compareFunc function? Custom comparison function(a, b) returns -1, 0, or 1
---@return table avl New AVL tree instance
---@usage local avl = AVLTree()
function AVLTree(compareFunc)
    local avl = {
        _root = nil,
        _size = 0,
        _compare = compareFunc or function(a, b)
            if a < b then return -1
            elseif a > b then return 1
            else return 0 end
        end
    }
    
    --- Insert key-value pair
    ---@param key any Key to insert
    ---@param value any? Value associated with key
    ---@usage avl:insert(5, "five")
    function avl:insert(key, value)
        self._root = self:_insertNode(self._root, key, value)
    end
    
    --- Find value by key
    ---@param key any Key to search for
    ---@return any? value Value if found, nil otherwise
    ---@usage local value = avl:find(5)
    function avl:find(key)
        local node = self:_findNode(self._root, key)
        return node and node.value or nil
    end
    
    --- Remove key from tree
    ---@param key any Key to remove
    ---@return boolean removed True if key was removed
    ---@usage avl:remove(5)
    function avl:remove(key)
        local oldSize = self._size
        self._root = self:_removeNode(self._root, key)
        return self._size < oldSize
    end
    
    --- Get number of nodes
    ---@return number size Number of nodes
    ---@usage local size = avl:size()
    function avl:size()
        return self._size
    end
    
    --- Check if tree is empty
    ---@return boolean empty True if tree is empty
    ---@usage if avl:isEmpty() then ... end
    function avl:isEmpty()
        return self._size == 0
    end
    
    --- Clear all nodes
    ---@usage avl:clear()
    function avl:clear()
        self._root = nil
        self._size = 0
    end
    
    -- Internal methods
    function avl:_getHeight(node)
        return node and node.height or 0
    end
    
    function avl:_updateHeight(node)
        if node then
            node.height = 1 + math.max(self:_getHeight(node.left), self:_getHeight(node.right))
        end
    end
    
    function avl:_getBalance(node)
        return node and (self:_getHeight(node.left) - self:_getHeight(node.right)) or 0
    end
    
    function avl:_rotateRight(y)
        local x = y.left
        local T2 = x.right
        
        x.right = y
        y.left = T2
        
        self:_updateHeight(y)
        self:_updateHeight(x)
        
        return x
    end
    
    function avl:_rotateLeft(x)
        local y = x.right
        local T2 = y.left
        
        y.left = x
        x.right = T2
        
        self:_updateHeight(x)
        self:_updateHeight(y)
        
        return y
    end
    
    function avl:_insertNode(node, key, value)
        if not node then
            self._size = self._size + 1
            return AVLNode(key, value)
        end
        
        local cmp = self._compare(key, node.key)
        if cmp < 0 then
            node.left = self:_insertNode(node.left, key, value)
        elseif cmp > 0 then
            node.right = self:_insertNode(node.right, key, value)
        else
            -- Update existing value
            node.value = value
            return node
        end
        
        self:_updateHeight(node)
        
        local balance = self:_getBalance(node)
        
        -- Left Left
        if balance > 1 and self._compare(key, node.left.key) < 0 then
            return self:_rotateRight(node)
        end
        
        -- Right Right
        if balance < -1 and self._compare(key, node.right.key) > 0 then
            return self:_rotateLeft(node)
        end
        
        -- Left Right
        if balance > 1 and self._compare(key, node.left.key) > 0 then
            node.left = self:_rotateLeft(node.left)
            return self:_rotateRight(node)
        end
        
        -- Right Left
        if balance < -1 and self._compare(key, node.right.key) < 0 then
            node.right = self:_rotateRight(node.right)
            return self:_rotateLeft(node)
        end
        
        return node
    end
    
    function avl:_findNode(node, key)
        if not node then return nil end
        
        local cmp = self._compare(key, node.key)
        if cmp < 0 then
            return self:_findNode(node.left, key)
        elseif cmp > 0 then
            return self:_findNode(node.right, key)
        else
            return node
        end
    end
    
    function avl:_minNode(node)
        while node.left do
            node = node.left
        end
        return node
    end
    
    function avl:_removeNode(node, key)
        if not node then return nil end
        
        local cmp = self._compare(key, node.key)
        if cmp < 0 then
            node.left = self:_removeNode(node.left, key)
        elseif cmp > 0 then
            node.right = self:_removeNode(node.right, key)
        else
            self._size = self._size - 1
            
            if not node.left or not node.right then
                return node.left or node.right
            end
            
            local temp = self:_minNode(node.right)
            node.key = temp.key
            node.value = temp.value
            node.right = self:_removeNode(node.right, temp.key)
            self._size = self._size + 1 -- Compensate for double decrement
        end
        
        self:_updateHeight(node)
        
        local balance = self:_getBalance(node)
        
        -- Left Left
        if balance > 1 and self:_getBalance(node.left) >= 0 then
            return self:_rotateRight(node)
        end
        
        -- Left Right
        if balance > 1 and self:_getBalance(node.left) < 0 then
            node.left = self:_rotateLeft(node.left)
            return self:_rotateRight(node)
        end
        
        -- Right Right
        if balance < -1 and self:_getBalance(node.right) <= 0 then
            return self:_rotateLeft(node)
        end
        
        -- Right Left
        if balance < -1 and self:_getBalance(node.right) > 0 then
            node.right = self:_rotateRight(node.right)
            return self:_rotateLeft(node)
        end
        
        return node
    end
    
    return avl
end