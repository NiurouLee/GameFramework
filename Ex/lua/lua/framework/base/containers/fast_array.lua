--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    容器：不维护插入顺序的数组
    在数组中间删除元素会直接把最后一个元素移过来
**********************************************************************************************
]] --------------------------------------------------------------------------------------------
---@class FastArray:Object
_class("FastArray", Object)
FastArray = FastArray
function FastArray:Constructor()
    self.elements = {}
end

function FastArray:Empty()
    return #self.elements == 0
end

function FastArray:Size()
    return #self.elements
end

function FastArray:Clear()
    self.elements = {}
end

--[[-------------------------------------------
    把value插在数组末尾
    检查nil是为了维护好索引的连续性
]]---------------------------------------------
function FastArray:PushBack(value)
    if value == nil then
        return
    end
    local elements = self.elements
    elements[#elements + 1] = value
end

--[[-------------------------------------------
    插入等同于在末尾添加
]]---------------------------------------------
FastArray.Insert = FastArray.PushBack

--[[-------------------------------------------
    移除并返回数组末尾的元素
]]---------------------------------------------
function FastArray:PopBack()
    local elements = self.elements
    local size = #elements
    local temp = elements[size]
    elements[size] = nil
    return temp
end

--[[-------------------------------------------
    删除并返回索引index处的元素
]]---------------------------------------------
function FastArray:RemoveByIndex(index)
    local elements = self.elements
    local size = #elements
    if index < 1 or index > size then
        return
    end
    local temp = elements[index]
    elements[index] = elements[size]
    elements[size] = nil
    return temp
end

--[[-------------------------------------------
    RemoveAt等同于RemoveByIndex
]]---------------------------------------------
FastArray.RemoveAt = FastArray.RemoveByIndex

--[[-------------------------------------------
    从数组开头遍历搜索第一个值为value的元素，如果找到则删除
]]---------------------------------------------
function FastArray:RemoveFirst(value)
    local index = self:Find(value, 1)
    self:RemoveAt(index)
end

--[[-------------------------------------------
    Remove等同于RemoveFirst
]]---------------------------------------------
FastArray.Remove = FastArray.RemoveFirst

--[[-------------------------------------------
    从索引from_index开始遍历搜索第一个值为value的元素，如果找到则返回索引
]]---------------------------------------------
function FastArray:Find(value, from_index)
    if not from_index then
        from_index = 1
    end
    local elements = self.elements
    for i = from_index, #elements do
        if elements[i] == value then
            return i
        end
    end
    return -1
end

---若数组里存放的是简单的值类型，比如number，string这种，可以调用该函数；如果是table，建议不要调用该函数，自己遍历，通过比较table的某个属性，比如通过比较ID
function FastArray:Contains(value, from_index)
    local index = self:Find(value, from_index)
    if index == -1 then
        return false
    else
        return true
    end
end

--[[-------------------------------------------
    返回索引index处的元素
]]---------------------------------------------
function FastArray:GetAt(index)
    return self.elements[index]
end

--[[-------------------------------------------
    对所有元素依次调用函数func
]]---------------------------------------------
function FastArray:ForEach(func)
    local elements = self.elements
    for i = 1, #elements do
        func(elements[i])
    end
end
