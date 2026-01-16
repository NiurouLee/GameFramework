
---@class SkillEffectCalc_DamageByConvertGridCount: Object
_class("SkillEffectCalc_DamageByConvertGridCount", Object)
SkillEffectCalc_DamageByConvertGridCount = SkillEffectCalc_DamageByConvertGridCount

function SkillEffectCalc_DamageByConvertGridCount:Constructor(world)
    ---@type MainWorld
    self._world = world
    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_DamageByConvertGridCount:DoSkillEffectCalculator(skillEffectCalcParam)
    local casterEntityID = skillEffectCalcParam.casterEntityID
    local casterEntity = self._world:GetEntityByID(casterEntityID)
    local attackPos = casterEntity:GetGridPosition()
    ---@type SkillEffectParamByConvertGridCount
    local skillDamageParam = skillEffectCalcParam:GetSkillEffectParam()
    local gridType = skillDamageParam:GetGridType()
    local targetEntityIDs = skillEffectCalcParam:GetTargetEntityIDs()
    local targetEntityID =targetEntityIDs[1]
    local targetEntity = self._world:GetEntityByID(targetEntityID)
    local damagePos = targetEntity:GetGridPosition()
    local damageTimes = self:_CalcDamageTimes(casterEntity,gridType)
    skillDamageParam:SetN33DamageMul(1)
    if damageTimes== 0 then
        return
    end
    skillDamageParam:SetN33DamageMul(damageTimes)

    ---@type SkillEffectCalcService
    local effectCalcSvc = self._skillEffectService
    local skillResultList = {}

    local damageStageIndex = skillDamageParam:GetSkillEffectDamageStageIndex()
    local nTotalDamage, listDamageInfo = effectCalcSvc:ComputeSkillDamage(
            casterEntity,
            attackPos,
            targetEntity,
            damagePos,
            skillEffectCalcParam.skillID,
            skillDamageParam,
            SkillEffectType.Damage,
            damageStageIndex
    )

    local skillResult = effectCalcSvc:NewSkillDamageEffectResult(
            damagePos,
            targetEntityID,
            nTotalDamage,
            listDamageInfo,
            damageStageIndex
    )
    table.insert(skillResultList, skillResult)
    return skillResultList
end

---@param casterEntity Entity
---@param gridType PieceType
function SkillEffectCalc_DamageByConvertGridCount:_CalcDamageTimes(casterEntity,gridType)
    ---@type Entity
    local entity = casterEntity
    if casterEntity:HasSuperEntity() then
        entity = casterEntity:GetSuperEntity()
    end
    local retCount = 0
    ---@type BuffComponent
    local buffCmpt = entity:BuffComponent()
    ---@type NTGridConvert_ConvertInfo[]
    local resetConvertInfoList = buffCmpt:GetBuffValue("SaveResetConvertInfo")
    if resetConvertInfoList then
        ---@param NTGridConvert_ConvertInfo
        for i, v in ipairs(resetConvertInfoList) do
            local oldColor = v:GetBeforePieceType()
            local newColor = v:GetAfterPieceType()
            if oldColor ~= newColor and newColor == gridType then
                retCount = retCount+ 1
            end
        end
    end
    ---@type NTGridConvert_ConvertInfo[]
    local convertInfoList = buffCmpt:GetBuffValue("SaveConvertInfo")
    if convertInfoList then
        ---@param NTGridConvert_ConvertInfo
        for i, v in ipairs(convertInfoList) do
            local newColor = v:GetAfterPieceType()
            if newColor == gridType then
                retCount = retCount+ 1
            end
        end
    end
    return retCount
end