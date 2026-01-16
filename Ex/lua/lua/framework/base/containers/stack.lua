--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    容器：栈
**********************************************************************************************
]] --------------------------------------------------------------------------------------------
---@class Stack:Object
_class("Stack", Object)
Stack = Stack
function Stack:Constructor()
    self.elements = {}
end

function Stack:Empty()
    return #self.elements == 0
end

function Stack:Size()
    return #self.elements
end

function Stack:Clear()
    self.elements = {}
end

--[[-------------------------------------------
    入栈
    检查nil是为了维护好索引的连续性
]]---------------------------------------------
function Stack:Push(value)
    if value == nil then
        return
    end
    local elements = self.elements
    elements[#elements + 1] = value
end

--[[-------------------------------------------
    出栈并返回
]]---------------------------------------------
function Stack:Pop()
    local elements = self.elements
    local size = #elements
    local temp = elements[size]
    elements[size] = nil
    return temp
end

--[[-------------------------------------------
    返回栈顶
]]---------------------------------------------
function Stack:Top()
    local elements = self.elements
    return elements[#elements]
end

--[[-------------------------------------------
    对所有元素依次调用函数func
]]---------------------------------------------
function Stack:ForEach(func)
    local elements = self.elements
    local size = #elements
    for i = size, 1, -1 do
        func(elements[i])
    end
end

---若数组里存放的是简单的值类型，比如number，string这种，可以调用该函数；如果是table，建议不要调用该函数，自己遍历，通过比较table的某个属性，比如通过比较ID
function Stack:Contains(value)
    local elements = self.elements
    local size = #elements
    for i = size, 1, -1 do
        if elements[i] == value then
            return true
        end
    end
    return false
end

---注意：这里是浅拷贝，如果是table这种引用类型，在外部对Array的修改会影响到Stack中的对象
function Stack:ToArray()
    local t = {}
    local elements = self.elements
    local size = #elements
    for i = size, 1, -1 do
        t[#t + 1] = elements[i]
    end
    return t
end
