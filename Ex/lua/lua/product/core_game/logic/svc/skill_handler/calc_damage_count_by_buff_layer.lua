--[[
    DamageByBuffLayer = 196, -- 根据施法者Buff层数决定伤害次数
]]
---@class SkillEffectCalc_DamageCountByBuffLayer: SkillEffectCalc_Damage
_class("SkillEffectCalc_DamageCountByBuffLayer", SkillEffectCalc_Damage)
SkillEffectCalc_DamageCountByBuffLayer = SkillEffectCalc_DamageCountByBuffLayer

function SkillEffectCalc_DamageCountByBuffLayer:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_DamageCountByBuffLayer:DoSkillEffectCalculator(skillEffectCalcParam)
    local casterEntityID = skillEffectCalcParam.casterEntityID
    local casterEntity = self._world:GetEntityByID(casterEntityID)
    local targetIDList = skillEffectCalcParam:GetTargetEntityIDs()

    ---@type SkillEffectDamageCountByBuffLayerParam
    local skillEffectParam = skillEffectCalcParam:GetSkillEffectParam()
    local buffEffectType = skillEffectParam:GetAddPercentBuffEffectType()
    ---@type BuffLogicService
    local buffSvc = self._world:GetService("BuffLogic")
    ---@type SkillDamageEffectResult
    local skillResultList = {}
    local buffPreCount = skillEffectParam:GetBuffPreCount()
    if #targetIDList==1 and targetIDList[1]== -1 then
        return {}
    end

    for _, targetID in ipairs(targetIDList) do
        local targetEntity = self._world:GetEntityByID(targetID)
        local curLayerCount = buffSvc:GetBuffLayer(targetEntity, buffEffectType)
        local i = 1
        while curLayerCount>=buffPreCount do
            ---@type SkillDamageEffectResult[]
            local results = self:_CalculateSingleTarget(skillEffectCalcParam, targetID)
            for _, result in ipairs(results) do
                result:SetDamageIndex(i)
                table.insert(skillResultList, result)
            end
            i = i + 1
            curLayerCount = curLayerCount -buffPreCount
        end
    end
    return skillResultList
end