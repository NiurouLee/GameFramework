require("_buff_view_base_r")

---@class BuffViewRecoverByMaxHPAndClearGreyHP : BuffViewBase
_class("BuffViewRecoverByMaxHPAndClearGreyHP", BuffViewBase)
BuffViewRecoverByMaxHPAndClearGreyHP = BuffViewRecoverByMaxHPAndClearGreyHP

---
---@param notify INotifyBase
function BuffViewRecoverByMaxHPAndClearGreyHP:IsNotifyMatch(notify)
    return true
end

---
function BuffViewRecoverByMaxHPAndClearGreyHP:PlayView(TT)
    ---@type BuffResultRecoverByMaxHPAndClearGreyHP
    local result = self._buffResult
    ---@type DamageInfo
    local damageInfo = result:GetDamageInfo()

    ---@type PlayDamageService
    local playDamageService = self._world:GetService("PlayDamage")
    playDamageService:AsyncUpdateHPAndDisplayDamage(self._entity, damageInfo)

    self._entity:ReplaceGreyHP(0)
end
