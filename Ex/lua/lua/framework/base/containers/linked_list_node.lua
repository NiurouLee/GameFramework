---@class LinkedListNode:Object
_class("LinkedListNode", Object)
LinkedListNode = LinkedListNode
function LinkedListNode:Constructor(v)
    self.value = v
    ---@type LinkedListNode
    self.next = nil
    ---@type LinkedListNode
    self.prev = nil
end

---@private
---@param prev LinkedListNode
---@param next LinkedListNode
function LinkedListNode:SetNear(prev,next)
    self.prev = prev
    self.next = next
end
