--[[
    加血效果
]]
_class("BuffViewAddHPBySanChange", BuffViewBase)
---@class BuffViewAddHPBySanChange:BuffViewBase
BuffViewAddHPBySanChange = BuffViewAddHPBySanChange

function BuffViewAddHPBySanChange:IsNotifyMatch(notify)
    local nt = self._buffResult:GetLogicNotify()
    if (nt and notify and
            nt:GetNotifyType() == NotifyType.SanValueChange and
            notify:GetNotifyType() == NotifyType.SanValueChange) then
        return (nt:GetCurValue() == notify:GetCurValue()) and (nt:GetOldValue() == notify:GetOldValue())
    end
end

function BuffViewAddHPBySanChange:PlayView(TT)
    ---@type  Entity
    local entity = self._entity
    ---@type DamageInfo
    local damageInfo = self._buffResult:GetDamageInfo()

    YIELD(TT)
    local materialEntity = entity
    --维多利亚吸血通过buff放技能给skillholder回血
    if entity:HasSuperEntity() and entity:EntityType():IsSkillHolder() then
        materialEntity = entity:GetSuperEntity()
    end
    if entity:HasTeam() then
        materialEntity = entity:GetTeamLeaderPetEntity()
    end

    if materialEntity:MaterialAnimationComponent() then
        --材质动画
        if damageInfo:GetDamageType() == DamageType.Recover then
            materialEntity:MaterialAnimationComponent():PlayCure()
        end
    end

    ---@type PlayDamageService
    local playDamageService = self._world:GetService("PlayDamage")

    --伤害飘字
    playDamageService:AsyncUpdateHPAndDisplayDamage(materialEntity, damageInfo)
end
