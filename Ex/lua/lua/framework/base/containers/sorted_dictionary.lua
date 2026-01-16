--[[-------------------------------------------
    容器：排序字典
]] ---------------------------------------------
---@class SortedDictionary:Object
_class("SortedDictionary", Object)
SortedDictionary = SortedDictionary

function SortedDictionary:Constructor(compare_method,less_comparer)
    --less_comparer的用法见SortedArray:SortedList_Constructor(less_comparer)
    self.sorted_key = SortedArray:New(compare_method,less_comparer)
    self.dictionary = {}
end

function SortedDictionary:Empty()
    return self.sorted_key:Empty()
end

--插入
function SortedDictionary:Insert(key, value)
    if not key or not value then
        return
    end
    self.sorted_key:Insert(key)
    self.dictionary[key] = value
end

--删除，返回元素表示是否删除成功
function SortedDictionary:Remove(key)
    if self.sorted_key:Remove(key) then
        local value = self.dictionary[key]
        self.dictionary[key] = nil
        return value
    end
end

--删除，根据索引
function SortedDictionary:RemoveByIndex(index)
    local key = self.sorted_key:RemoveByIndex(index)
    if key then
        local value = self.dictionary[key]
        self.dictionary[key] = nil
        return value
    end
end

--清空
function SortedDictionary:Clear()
    local cnt = self.sorted_key:Size()
    if cnt == 0 then
        return
    end
    local key
    for i = 1, cnt do
        key = self.sorted_key:GetAt(i)
        self.dictionary[key] = nil
    end
    self.sorted_key:Clear()
end

--查找，根据键查值
function SortedDictionary:Find(key)
    --[[
    if self.sorted_key:Contains(key) then
        return self.dictionary[key]
    else
        return nil
    end
    ]]
    return self.dictionary[key]
end

function SortedDictionary:FindIndex(key)
    return self.sorted_key:Find(key)
end

--修改
function SortedDictionary:Modify(key, value)
    if not key or not value then
        return
    end
    if self.sorted_key:Contains(key) then
        self.dictionary[key] = value
    end
end

--查找，返回bool
function SortedDictionary:ContainsKey(key)
    return self.sorted_key:Contains(key)
end

--枚举，通过数量和索引
function SortedDictionary:Size()
    return self.sorted_key:Size()
end

function SortedDictionary:GetAt(index)
    local key = self.sorted_key:GetAt(index)
    if not key then
        return nil
    end
    return self.dictionary[key], key
end

function SortedDictionary:GetKeyAt(index)
    local key = self.sorted_key:GetAt(index)
    return key
end

function SortedDictionary:GetPairAt(index)
    local key = self.sorted_key:GetAt(index)
    if not key then
        return nil
    end
    return key, self.dictionary[key]
end

---@param src SortedDictionary
function SortedDictionary:Copy(src)
    if src == nil then return end
    for i = 1, src:Size() do
        self:Insert(src:GetKeyAt(i),src:GetAt(i))
    end
end