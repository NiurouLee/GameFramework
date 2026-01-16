require("_buff_view_base_r")

_class("BuffViewRecoverFromGreyHPByLayer", BuffViewBase)
---@class BuffViewRecoverFromGreyHPByLayer : BuffViewBase
BuffViewRecoverFromGreyHPByLayer = BuffViewRecoverFromGreyHPByLayer

---
---@param notify INotifyBase
function BuffViewRecoverFromGreyHPByLayer:IsNotifyMatch(notify)
    return true
end

---
function BuffViewRecoverFromGreyHPByLayer:PlayView(TT)
    ---@type DamageInfo
    local damageInfo = self._buffResult:GetDamageInfo()

    ---@type PlayDamageService
    local playDamageService = self._world:GetService("PlayDamage")
    playDamageService:AsyncUpdateHPAndDisplayDamage(self._entity, damageInfo)

    ---@type BuffResultRecoverFromGreyHPByLayer
    local result = self._buffResult
    local greyHPVal = result:GetFinalGreyHPVal()
    self._entity:ReplaceGreyHP(greyHPVal)
end
