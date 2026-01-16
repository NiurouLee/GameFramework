require("_buff_result_base")

---@class BuffResultRecoverByMaxHPAndClearGreyHP : BuffResultBase
_class("BuffResultRecoverByMaxHPAndClearGreyHP", BuffResultBase)
BuffResultRecoverByMaxHPAndClearGreyHP = BuffResultRecoverByMaxHPAndClearGreyHP

---
function BuffResultRecoverByMaxHPAndClearGreyHP:Constructor(entityID, damageInfo)
    self._entityID = entityID
    ---@type DamageInfo
    self._damageInfo = damageInfo
end

---
function BuffResultRecoverByMaxHPAndClearGreyHP:GetEntityID()
    return self._entityID
end

---
function BuffResultRecoverByMaxHPAndClearGreyHP:GetDamageInfo()
    return self._damageInfo
end
