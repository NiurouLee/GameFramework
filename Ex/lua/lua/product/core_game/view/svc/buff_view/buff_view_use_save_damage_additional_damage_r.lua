--[[
    加血效果
]]
_class("BuffViewUseSaveDamageAdditionalDamage", BuffViewBase)
---@class BuffViewUseSaveDamageAdditionalDamage:BuffViewBase
BuffViewUseSaveDamageAdditionalDamage = BuffViewUseSaveDamageAdditionalDamage

function BuffViewUseSaveDamageAdditionalDamage:Constructor()
end

---@param notify INotifyBase
function BuffViewUseSaveDamageAdditionalDamage:IsNotifyMatch(notify)
    return true
end

function BuffViewUseSaveDamageAdditionalDamage:PlayView(TT)
    ---@type  Entity
    local entity = self._entity
    ---@type DamageInfo
    local damageInfo = self._buffResult:GetDamageInfo()
    local effectID = self._buffResult:GetEffectID()

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

    if effectID then
        --如果是星灵加血  改成队伍飘特效
        if entity:HasPet() then
            entity = entity:Pet():GetOwnerTeamEntity()
        end

        ---@type EffectService
        local effectService = self._world:GetService("Effect")
        local effectEntity = effectService:CreateEffect(effectID, entity)
    end
end
