
---@class SkillEffectCalc_DamageCountByBuffLayer2: SkillEffectCalc_Damage
_class("SkillEffectCalc_DamageCountByBuffLayer2", SkillEffectCalc_Damage)
SkillEffectCalc_DamageCountByBuffLayer2 = SkillEffectCalc_DamageCountByBuffLayer2

function SkillEffectCalc_DamageCountByBuffLayer2:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_DamageCountByBuffLayer2:DoSkillEffectCalculator(skillEffectCalcParam)
    local casterEntityID = skillEffectCalcParam.casterEntityID
    local casterEntity = self._world:GetEntityByID(casterEntityID)
    local targetIDList = skillEffectCalcParam:GetTargetEntityIDs()

    ---@type SkillEffectDamageCountByBuffLayer2Param
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
    local scopeType =  skillEffectParam:GetMyEffectScopeType()
    local scopeParam = skillEffectParam:GetMyEffectScopeParam()
    local targetType = skillEffectParam:GetMyEffectTargetType()
    local centerType = skillEffectParam:GetMyEffectCenterType()

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local calcScope = utilScopeSvc:GetSkillScopeCalc()
    local casterBodyArea = casterEntity:BodyArea():GetArea()
    local casterDirection = casterEntity:GetGridDirection()
    local scopeResult =
    calcScope:ComputeScopeRange(
            scopeType,
            scopeParam,
            casterEntity:GetGridPosition(),
            casterBodyArea,
            casterDirection,
            targetType,
            casterEntity:GetGridPosition()
    )
    -- 用新范围获取挨打的目标
    local targetSelector = self._world:GetSkillScopeTargetSelector()
    local damageTargetArray = targetSelector:DoSelectSkillTarget(casterEntity, targetType, scopeResult)
    for _, targetID in ipairs(targetIDList) do
        local targetEntity = self._world:GetEntityByID(targetID)
        local curLayerCount = buffSvc:GetBuffLayer(targetEntity, buffEffectType)
        local i = 1
        while curLayerCount>=buffPreCount do
            for _, damageTargetID in ipairs(damageTargetArray) do
                ---@type Entity
                local damageTargetEntity = self._world:GetEntityByID(damageTargetID)
                skillEffectCalcParam.gridPos= damageTargetEntity:GetGridPosition()
                ---@type SkillDamageEffectResult[]
                local results = self:_CalculateSingleTarget(skillEffectCalcParam, damageTargetID)
                for _, result in ipairs(results) do
                    result:SetDamageIndex(i)
                    table.insert(skillResultList, result)
                end
            end
            i = i + 1
            curLayerCount = curLayerCount -buffPreCount
        end
    end
    return skillResultList
end