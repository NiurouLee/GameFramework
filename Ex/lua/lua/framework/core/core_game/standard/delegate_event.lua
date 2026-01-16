--事件原型对象, 所有事件由此原型生成

---@class DelegateEvent
DelegateEvent = {}

function DelegateEvent:New()
    local event = {}
    setmetatable(event, self)
    self.__index = self
    self.__call = self.Call
    event._callArray = ArrayList:New()
    return event
end

--事件注册, 通过此方法将响应方法注册到事件上.
--@source:响应方法的所属对象
--@func:响应方法
function DelegateEvent:AddEvent(source, func)
    self._callArray:PushBack({source, func})
    --table.insert(self, {source, func})
end


function DelegateEvent:RemoveEvent(source, func)
    for i = 1, self._callArray:Size() do
        local item = self._callArray:GetAt(i)
        if item[2] == func and item[1] == source then
            self._callArray:RemoveAt(i)
            return true
        end
    end
    return false
end


function DelegateEvent:Clear()
    self._callArray:Clear()
end


--当event被触发调用时, 按序执行响应方法
function DelegateEvent:Call(...)
    local size = self._callArray:Size()
    for i = 1, size do
        local item = self._callArray:GetAt(i)
        -- obj : item[1]
        -- callfunc : item[2]
        item[2](item[1], ...)
    end
end
