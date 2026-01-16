require("_buff_view_base_r")

_class("BuffViewRecoverFromGreyHP", BuffViewBase)
---@class BuffViewRecoverFromGreyHP : BuffViewBase
BuffViewRecoverFromGreyHP = BuffViewRecoverFromGreyHP

---
---@param notify INotifyBase
function BuffViewRecoverFromGreyHP:IsNotifyMatch(notify)
    return true
end

---
function BuffViewRecoverFromGreyHP:PlayView(TT)
    ---@type DamageInfo
    local damageInfo = self._buffResult:GetDamageInfo()

    ---@type PlayDamageService
    local playDamageService = self._world:GetService("PlayDamage")
    playDamageService:AsyncUpdateHPAndDisplayDamage(self._entity, damageInfo)

    ---@type BuffResultRecoverFromGreyHP
    local result = self._buffResult
    local greyHPVal = result:GetFinalGreyHPVal()
    self._entity:ReplaceGreyHP(greyHPVal)
end
