--[[
    DamageOnTargetCount = 78, -- 根据技能覆盖的目标数量决定伤害参数
]]
---@class SkillEffectCalc_DamageOnTargetCount: Object
_class("SkillEffectCalc_DamageOnTargetCount", Object)
SkillEffectCalc_DamageOnTargetCount = SkillEffectCalc_DamageOnTargetCount

function SkillEffectCalc_DamageOnTargetCount:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_DamageOnTargetCount:DoSkillEffectCalculator(skillEffectCalcParam)
    local casterEntityID = skillEffectCalcParam.casterEntityID
    local casterEntity = self._world:GetEntityByID(casterEntityID)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()

    ---@type SkillEffectDamageOnTargetCountParam
    local skillEffectParam = skillEffectCalcParam.skillEffectParam
    local targetCount = #(scopeResult:GetTargetIDs())
    local countNoRepeat = skillEffectParam:IsCountNoRepeat()
    if countNoRepeat then
        local targetIds = scopeResult:GetTargetIDs()
        local targetIdsNoRepeat = {}
        for i = 1, #targetIds do
            local targetId = targetIds[i]
            if false == table.icontains(targetIdsNoRepeat, targetId) then
                table.insert(targetIdsNoRepeat, targetId)
            end
        end
        targetCount = #targetIdsNoRepeat
    end
    local damageEffectParam = skillEffectParam:GetDamageParamByCount(targetCount)

    ---@type SkillEffectCalcParam
    local damageCalcParam =
        SkillEffectCalcParam:New(
        skillEffectCalcParam:GetCasterEntityID(),
        skillEffectCalcParam:GetTargetEntityIDs(),
        damageEffectParam,
        skillEffectCalcParam:GetSkillID(),
        skillEffectCalcParam:GetSkillRange(),
        skillEffectCalcParam:GetAttackPos(),
        skillEffectCalcParam:GetGridPos()
    )

    ---@type SkillEffectCalc_Damage
    local skillEffectCalc = SkillEffectCalc_Damage:New(self._world)
    local result = skillEffectCalc:DoSkillEffectCalculator(damageCalcParam)
    return result
end
