_class("BuffResultDecreaseMaxHP", BuffResultBase)
---@class BuffResultDecreaseMaxHP : BuffResultBase
BuffResultDecreaseMaxHP = BuffResultDecreaseMaxHP

function BuffResultDecreaseMaxHP:Constructor(eid, damageInfo, maxHPResult)
    ---@type number
    self._eid = eid
    ---@type DamageInfo
    self._damageInfo = damageInfo
    self._maxHPResult = maxHPResult
end

function BuffResultDecreaseMaxHP:GetDamageInfo() return self._damageInfo end
function BuffResultDecreaseMaxHP:GetEntityID() return self._eid end
function BuffResultDecreaseMaxHP:GetMaxHPResult() return self._maxHPResult end