--[[
    DamageByBuffLayer = 196, -- 根据施法者Buff层数决定伤害参数
]]
---@class SkillEffectCalc_DamageByBuffLayer: Object
_class("SkillEffectCalc_DamageByBuffLayer", Object)
SkillEffectCalc_DamageByBuffLayer = SkillEffectCalc_DamageByBuffLayer

function SkillEffectCalc_DamageByBuffLayer:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_DamageByBuffLayer:DoSkillEffectCalculator(skillEffectCalcParam)
    local casterEntityID = skillEffectCalcParam.casterEntityID
    local casterEntity = self._world:GetEntityByID(casterEntityID)

    ---@type SkillEffectDamageByBuffLayerParam
    local skillEffectParam = skillEffectCalcParam:GetSkillEffectParam()
    local buffEffectType = skillEffectParam:GetAddPercentBuffEffectType()
    local maxLayerCount = skillEffectParam:GetMaxLayerCount()
    local maxAddPercent = skillEffectParam:GetMaxAddPercent()
    local percent = skillEffectParam:GetDamagePercent()
    local power = skillEffectParam:GetDamagePower()
    local basePercent = table.cloneconf(percent)

    ---@type BuffLogicService
    local buffSvc = self._world:GetService("BuffLogic")
    local curLayerCount = buffSvc:GetBuffLayer(casterEntity, buffEffectType)
    local powerAdd = (curLayerCount / maxLayerCount) ^ power
    local addPercent = powerAdd * maxAddPercent
    if addPercent > maxAddPercent then
        addPercent = maxAddPercent
    end

    local finalPercent = {}
    for _, value in ipairs(percent) do
        local tmpPercent = value + addPercent
        table.insert(finalPercent, tmpPercent)
    end

    skillEffectParam._percent = finalPercent

    ---@type SkillEffectCalcParam
    local damageCalcParam =
        SkillEffectCalcParam:New(
            skillEffectCalcParam:GetCasterEntityID(),
            skillEffectCalcParam:GetTargetEntityIDs(),
            skillEffectParam,
            skillEffectCalcParam:GetSkillID(),
            skillEffectCalcParam:GetSkillRange(),
            skillEffectCalcParam:GetAttackPos(),
            skillEffectCalcParam:GetGridPos()
        )

    ---@type SkillEffectCalc_Damage
    local skillEffectCalc = SkillEffectCalc_Damage:New(self._world)
    local resultList = skillEffectCalc:DoSkillEffectCalculator(damageCalcParam)

    --恢复伤害
    skillEffectParam._percent = basePercent

    --伤害后处理
    for _, damageRes in ipairs(resultList) do
        damageRes:SetBuffLayerCountForDamage(curLayerCount)
    end
    return resultList
end
