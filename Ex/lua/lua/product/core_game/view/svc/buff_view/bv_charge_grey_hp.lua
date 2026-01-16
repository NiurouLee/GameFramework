_class("BuffViewDisableGreyHPCharge", BuffViewBase)
---@class BuffViewDisableGreyHPCharge:BuffViewBase
BuffViewDisableGreyHPCharge = BuffViewDisableGreyHPCharge

function BuffViewDisableGreyHPCharge:PlayView(TT)
    ---@type BuffResultChargeGreyHP
    local result = self._buffResult

    self._entity:ReplaceGreyHP(0)
end

_class("BuffViewChargeGreyHP", BuffViewBase)
---@class BuffViewChargeGreyHP:BuffViewBase
BuffViewChargeGreyHP = BuffViewChargeGreyHP

---@param notify NTMonsterHPCChange
function BuffViewChargeGreyHP:IsNotifyMatch(notify)
    if notify:GetNotifyType() == NotifyType.MonsterHPCChange then
        local r = self._buffResult
        local isRecovery = false
        if notify:GetDamageInfo() and (notify:GetDamageInfo():GetDamageType() == DamageType.Recover) then
            isRecovery = true
        end
        return (not isRecovery) and r:GetNotifyType() == NotifyType.MonsterHPCChange and r:GetDamageHP() == notify:GetChangeHP()
    end
end

function BuffViewChargeGreyHP:PlayView(TT)
    ---@type BuffResultChargeGreyHP
    local result = self._buffResult

    local val = result:GetGreyHPVal()
    self._entity:ReplaceGreyHP(val)
end
