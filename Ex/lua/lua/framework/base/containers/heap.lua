--[[-------------------------------------------
-----------------------------------------------
    容器：基于最大堆的优先级队列
    注意：
        1、元素插入时会设置_heap_index和_insertion_index
            _heap_index（hi）是元素在堆数组中的索引，插入堆/堆内移动/从堆中移除时都需要维护，移除时置为-1！！！！！！！！！！
            _insertion_index（ii）表示第几个插入这个堆的元素；相同优先级的，插入越早优先级越高；同时也用于比较函数，永远不会相等。
        2、默认越大优先级越高
            comparer是函数，参数是2个元素。如果前者比后者优先级高，返回1；如果后者比前者优先级高，返回-1；相同，返回0。
-----------------------------------------------
]] ---------------------------------------------
local floor = math.floor
---@class Heap:Object
_class("Heap", Object)
Heap = Heap

--CheckPriorityMethod
Heap.CPM_CUSTOM = 1
Heap.CPM_GREATER = 2
Heap.CPM_LESS = 3

function Heap:Constructor(cpm, comparer)
    self.array = {}
    self.size = 0
    self.item_ever_enqueued = 0
    if cpm == Heap.CPM_CUSTOM then
        self.CheckPriority = Heap.CheckPriorityByComparer
        self.comparer = comparer
    elseif cpm == Heap.CPM_GREATER then
        self.CheckPriority = Heap.CheckPriorityByGreater
    elseif cpm == Heap.CPM_LESS then
        self.CheckPriority = Heap.CheckPriorityByLess
    else
        self.CheckPriority = Heap.CheckPriorityByGreater
    end
end --重建堆
---------------------------------------------

--[[-------------------------------------------
    公开接口
]] function Heap:BuildHeapPriorityQueue()
    local last_parent = floor(self.size * 0.5)
    for hi = last_parent, 1, -1 do
        self:CascadeDown(hi)
    end
end

--重置为空堆
function Heap:Clear()
    self.array = {}
    self.size = 0
end

--获取元素个数
function Heap:Size()
    return self.size
end

--是否是空
function Heap:Empty()
    return self.size == 0
end

--返回最优先的元素
function Heap:Peek()
    if self.size > 0 then
        return self.array[1]
    end
end

--按索引取元素
function Heap:GetAt(hi)
    if hi > 0 and hi <= self.size then
        return self.array[hi]
    end
end

--判断是否已经在堆中
function Heap:Contains(item)
    --Fixme 没啥好的办法，记得移除时置为-1
    local hi = item._heap_index
    if hi and hi > 0 then
        return true
    end
end

--插入（如果已经在队列，会变成更新）
function Heap:Enqueue(item)
    local hi = item._heap_index
    if hi and hi > 0 then
        self:UpdatePriorityByIndex(hi)
        return
    end
    hi = self.size + 1
    self.size = hi
    self.array[hi] = item
    item._heap_index = hi --插入时设置
    local ii = self.item_ever_enqueued + 1
    self.item_ever_enqueued = ii
    item._insertion_index = ii
    self:CascadeUp(hi)
end

--移除最优先的
function Heap:Dequeue()
    local size = self.size
    if size == 0 then
        return
    end
    local item = self.array[1]
    item._heap_index = -1 --移除置为-1
    if size == 1 then
        self.array[1] = nil --赋nil释放引用
        self.size = 0
    else
        local temp = self.array[size]
        self.array[1] = temp
        temp._heap_index = 1 --移动时维护
        self.array[size] = nil --赋nil释放引用
        self.size = size - 1
        self:CascadeDown(1)
    end
    return item
end

--动态更新（根据元素）
function Heap:UpdatePriority(item)
    local hi = item._heap_index
    if hi and hi > 0 then
        self:UpdatePriorityByIndex(hi)
    end
end

--动态更新（根据堆索引）
function Heap:UpdatePriorityByIndex(hi)
    if hi < 1 or hi > self.size then
        return
    end
    local parent = floor(hi * 0.5) --self:Parent(hi)
    if parent > 0 and self:CheckPriority(self.array[hi], self.array[parent]) then
        self:CascadeUp(hi)
    else
        self:CascadeDown(hi)
    end
end

--随意删除（根据元素）
function Heap:Remove(item)
    local hi = item._heap_index
    if hi and hi > 0 then
        self:RemoveByIndex(hi)
    end
end

--随意删除（根据堆索引）
function Heap:RemoveByIndex(hi)
    if hi < 1 or hi > self.size then
        Log.error("Heap:RemoveByIndex error index ", hi, self.size, Log.traceback())
        return
    end
    self.array[hi]._heap_index = -1 --移除置为-1
    local size = self.size
    if hi == size then
        self.array[hi] = nil --赋nil释放引用
        self.size = size - 1
    else
        local temp = self.array[size]
        self.array[hi] = temp
        temp._heap_index = hi --移动时维护
        self.array[size] = nil --赋nil释放引用
        self.size = size - 1
        self:UpdatePriorityByIndex(hi)
    end
end

--检查
function Heap:Check(must_less_priority_than_this)
    for hi = 1, #self.array do
        local item = self.array[hi]
        if item._heap_index ~= hi then
            return false
        end
        if must_less_priority_than_this and self:CheckPriority(item, must_less_priority_than_this) then
            return false
        end
        local pi = floor(hi * 0.5)
        if pi > 0 then
            local parent = self.array[pi]
            if self:CheckPriority(item, parent) then
                return false
            end
        end
    end
    return true
end --交换
---------------------------------------------

--[[-------------------------------------------
    内部私有
]] function Heap:Swap(i, j)
    local item_i = self.array[i]
    local item_j = self.array[j]
    self.array[i] = item_j
    self.array[j] = item_i
    item_i._heap_index = j --移动时维护
    item_j._heap_index = i --移动时维护
end

--向上调整
function Heap:CascadeUp(hi)
    local parent = floor(hi * 0.5) --self:Parent(hi)
    while parent > 0 do
        if self:CheckPriority(self.array[hi], self.array[parent]) then
            self:Swap(hi, parent)
            hi = parent
            parent = floor(hi * 0.5) --self:Parent(hi)
        else
            break
        end
    end
end

--向下调整
function Heap:CascadeDown(hi)
    local l
    local r
    local largest = hi
    while true do
        l = 2 * hi --self:Left(hi)
        r = 2 * hi + 1 --self:Right(hi)
        if l <= self.size and self:CheckPriority(self.array[l], self.array[largest]) then
            largest = l
        end
        if r <= self.size and self:CheckPriority(self.array[r], self.array[largest]) then
            largest = r
        end
        if largest == hi then
            break
        end
        self:Swap(hi, largest)
        hi = largest
    end
end

--[[
--取父节点的索引
function Heap:Parent(hi)
    return floor(hi * 0.5)
end
--取左子节点的索引
function Heap:Left(hi)
    return 2 * hi
end
--取右子节点的索引
function Heap:Right(hi)
    return 2 * hi + 1
end
]]
--根据元表进行优先级比较，越大优先级越高
function Heap:CheckPriorityByGreater(higher, lower)
    if higher > lower then
        return true
    elseif higher < lower then
        return false
    else
        return higher._insertion_index < lower._insertion_index
    end
end

--根据元表进行优先级比较，越小优先级越高
function Heap:CheckPriorityByLess(higher, lower)
    if higher < lower then
        return true
    elseif higher > lower then
        return false
    else
        return higher._insertion_index < lower._insertion_index
    end
end

--根据自定义比较函数进行优先级比较
function Heap:CheckPriorityByComparer(higher, lower)
    local result = self.comparer(higher, lower)
    if result > 0 then
        return true
    elseif result < 0 then
        return false
    else
        return higher._insertion_index < lower._insertion_index
    end
end
