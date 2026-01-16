--[[
    通过buffValue 记录通知时的当前位置
]]
--------------------------------
_class("BuffLogicRecordCurrentPos", BuffLogicBase)
---@class BuffLogicRecordCurrentPos:BuffLogicBase
BuffLogicRecordCurrentPos = BuffLogicRecordCurrentPos

function BuffLogicRecordCurrentPos:Constructor(buffInstance, logicParam)
    self._key = logicParam.key or "buff_recorded_pos"
    self._value = logicParam.value
end

function BuffLogicRecordCurrentPos:DoLogic(notify)
    ---@type BuffComponent
    local buffComponent = self._entity:BuffComponent()
    if not buffComponent then
        return
    end
    local curPos = self._entity:GetGridPosition()
    if curPos then
        local keyX = self._key .. "_x"
        buffComponent:SetBuffValue(keyX, curPos.x)
        local keyX = self._key .. "_y"
        buffComponent:SetBuffValue(keyX, curPos.y)
    end
end
