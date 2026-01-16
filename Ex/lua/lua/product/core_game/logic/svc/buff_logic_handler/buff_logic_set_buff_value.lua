--[[
    设置buff value
]]
--------------------------------
_class("BuffLogicSetBuffValue", BuffLogicBase)
---@class BuffLogicSetBuffValue:BuffLogicBase
BuffLogicSetBuffValue = BuffLogicSetBuffValue

function BuffLogicSetBuffValue:Constructor(buffInstance, logicParam)
    self._key = logicParam.key or ""
    self._value = logicParam.value
end

function BuffLogicSetBuffValue:DoLogic()
    ---@type BuffComponent
    local buffComponent = self._entity:BuffComponent()
    if not buffComponent then
        return
    end
    if type(self._value) == "table" then
        local tmp = table.clone(self._value)
        buffComponent:SetBuffValue(self._key, tmp)
    else
        buffComponent:SetBuffValue(self._key, self._value)
    end

end
