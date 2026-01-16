---@class SeasonQueue:Object
_class("SeasonQueue", Object)
SeasonQueue = SeasonQueue

function SeasonQueue:Constructor()
    self._first = nil
    self._last = nil
    self._count = 0
end

function SeasonQueue:Clear()
    self._first = nil
    self._last = nil
    self._count = 0
end
--入队列，到末尾
function SeasonQueue:Enqueue(item)
    if self._first == nil then
        local element = self:NewItem(item)
        self._first = element
        self._last = element
        self._count = 1
        return
    end

    local last = self:NewItem(item)
    self._last.next = last
    self._last = last
    self._count = self._count + 1
end
--返回队列头并删除
function SeasonQueue:Dequeue()
    if self._first == nil then
        return nil
    end
    local item = self._first.value
    local first = self._first.next
    self._first = first
    self._count = self._count - 1
    return item
end
--返回队列头，不删除
function SeasonQueue:Peek()
    if self._first == nil then
        return nil
    end
    return self._first.value
end
--移动头节点到末尾
function SeasonQueue:FrontToBack()
    if self._first == nil then
        return
    end
    local item = self:Dequeue()
    self:Enqueue(item)
end
--遍历
function SeasonQueue:ForEach(func)
    local cur = self._first
    while cur do
        func(cur.value)
        cur = cur.next
    end
end
function SeasonQueue:Contains(item)
    self:ForEach(
        function(val)
            if val == item then
                return true
            end
        end
    )
    return false
end
function SeasonQueue:Count()
    return self._count
end
function SeasonQueue:NewItem(val)
    return {next = nil, value = val}
end

function SeasonQueue:RemoveFirst(func)
    if self._first == nil then
        return false
    end

    if func(self._first.value) then
        self._first = self._first.next
        self._count = self._count - 1
        if self._count == 0 then
            self._last = nil
        end
        return true
    end
    local cur = self._first
    local next = cur.next
    while next do
        if func(next.value) then
            cur.next = next.next
            self._count = self._count - 1
            if cur.next == nil then
                self._last = cur
            end
            return true
        end
        cur = next
        next = cur.next
    end
    return false
end

--查找第1个符合条件的元素，删除并返回
function SeasonQueue:PopFirst(filter)
    if self._first == nil then
        return
    end

    if filter(self._first.value) then
        local item = self._first.value
        self._first = self._first.next
        self._count = self._count - 1
        if self._count == 0 then
            self._last = nil
        end
        return item
    end
    local cur = self._first
    local next = cur.next
    while next do
        if filter(next.value) then
            local item = next.value
            cur.next = next.next
            self._count = self._count - 1
            if cur.next == nil then
                self._last = cur
            end
            return item
        end
        cur = next
        next = cur.next
    end
end

--是否包含符合条件的元素
function SeasonQueue:ContainsBy(filter)
    local cur = self._first
    while cur do
        if filter(cur.value) then
            return true
        end
        cur = cur.next
    end
    return false
end
