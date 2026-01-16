--[[
    击退后造成伤害buff表现
]]
_class("BuffViewHitBackEndDamage", BuffViewBase)
BuffViewHitBackEndDamage = BuffViewHitBackEndDamage

function BuffViewHitBackEndDamage:PlayView(TT)
    local targetId = self._buffResult:GetDefenderID()
    ---@type DamageInfo
    local damageInfo = self._buffResult:GetDamageInfo()
    if not damageInfo then
        return
    end
    local viewParams = self._viewInstance:BuffConfigData():GetViewParams()
    local targetEntity = self._world:GetEntityByID(targetId)
    local damageType = damageInfo:GetDamageType()
    local targetDamage = damageInfo:GetDamageValue()
    local shieldLayer = damageInfo:GetShieldLayer()
    local hitEffectID = viewParams.HitEffectId
    if damageType == DamageType.Guard then
        --护盾受击特效
        -- self._world:GetService("Effect"):CreateEffect(BattleConst.ShieldHitEffect, targetEntity)
    elseif damageType == DamageType.Normal then
        if hitEffectID > 0 then
            self._world:GetService("Effect"):CreateBeHitEffect(hitEffectID, targetEntity)
        end
        local hitAnim = "Hit"
        targetEntity:SetAnimatorControllerTriggers({hitAnim})
    end

    ---@type PlayDamageService
    local playDamageService = self._world:GetService("PlayDamage")

    --伤害飘字
    playDamageService:AsyncUpdateHPAndDisplayDamage(targetEntity, damageInfo)
end

--是否匹配参数
---@type NTHitBackEnd
function BuffViewHitBackEndDamage:IsNotifyMatch(notify)
    local defenderId = notify:GetDefenderId()
    if self._buffResult:GetDefenderID() == defenderId then
        return true
    end
    return false
end
