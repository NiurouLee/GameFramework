--[[
    加血效果
]]
_class("BuffViewAddHPByTargetBuffEffectType", BuffViewBase)
---@class BuffViewAddHPByTargetBuffEffectType:BuffViewBase
BuffViewAddHPByTargetBuffEffectType = BuffViewAddHPByTargetBuffEffectType

function BuffViewAddHPByTargetBuffEffectType:Constructor()
end

function BuffViewAddHPByTargetBuffEffectType:PlayView(TT)
    ---@type  Entity
    local entity = self._entity
    local addValue = self._buffResult:GetAddHP()
    local damageInfo = self._buffResult:GetDamageInfo()
    if addValue <= 0 then
        return
    end

    YIELD(TT)
    local materialEntity = entity
    if entity:HasTeam() then
        materialEntity = entity:GetTeamLeaderPetEntity()
    end
    --材质动画
    if materialEntity:MaterialAnimationComponent() then 
        materialEntity:MaterialAnimationComponent():PlayCure()
    end
    --加血飘字
    ---@type PlayDamageService
    local playDamageService = self._world:GetService("PlayDamage")
    playDamageService:AsyncUpdateHPAndDisplayDamage( materialEntity, damageInfo)
end
