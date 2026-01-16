--[[
    怪物精英化：受控加重

    增加指定effectType的buff在挂载时的最大回合数
]]
_class("BuffLogicDoControlIncrease", BuffLogicBase)
---@class BuffLogicDoControlIncrease : BuffLogicBase
BuffLogicDoControlIncrease = BuffLogicDoControlIncrease

function BuffLogicDoControlIncrease:Constructor(_buffIns, logicParam)
    self._val = tonumber(logicParam.val)
    assert(self._val, "DoControlIncrease: parameter [val] is required. ")
end

---@param notify INotifyBase
function BuffLogicDoControlIncrease:DoLogic(notify)
    ---@type Entity
    local e = self:GetEntity()
    self._buffLogicService:ChangeControlIncrease(e, self:GetBuffSeq(), self._val)
end

_class("BuffLogicUndoControlIncrease", BuffLogicBase)
---@class BuffLogicUndoControlIncrease : BuffLogicBase
BuffLogicUndoControlIncrease = BuffLogicUndoControlIncrease

---@param notify INotifyBase
function BuffLogicUndoControlIncrease:DoLogic(notify)
    ---@type Entity
    local e = self:GetEntity()
    self._buffLogicService:RemoveControlIncrease(e, self:GetBuffSeq())
end
