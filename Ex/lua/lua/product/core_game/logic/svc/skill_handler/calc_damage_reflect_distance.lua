--[[
    DamageReflectDistance = 122, --根据反射距离计算伤害系数
]]
require("calc_base")

_class("DamageByReflectDistanceCalculator", SkillEffectCalc_Base)
---@class DamageByReflectDistanceCalculator: SkillEffectCalc_Base
DamageByReflectDistanceCalculator = DamageByReflectDistanceCalculator

function DamageByReflectDistanceCalculator:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param casterEntity Entity
---@param effectParam SkillEffectParam_DamageReflectDistance
function DamageByReflectDistanceCalculator:Calculate(casterEntity, effectParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    local attackRange = scopeResult:GetAttackRange()
    local distance = scopeResult:GetSpecialScopeResult()
    local attackPos = casterEntity:GetGridPosition()
    local boardLogicSvc = self._world:GetService("BoardLogic")
    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    ---@type SkillEffectCalcService
    local skillEffectService = self._world:GetService("SkillEffectCalc")

    local targetSelector = self._world:GetSkillScopeTargetSelector()
    local damageStageIndex = effectParam:GetSkillEffectDamageStageIndex()
    local modifySkillIncreaseType = effectParam:GetSkillIncreaseType()

    local tResults = {}
    for i = 1, #attackRange do
        local gridPos = attackRange[i]
        local damageParam = distance[i] * effectParam:GetDistanceDamageParam()
        --怪物有一个格子在范围内就攻击一次
        local targetID = scopeResult:GetTargetIDByPos(gridPos)
        if targetID then
            local target = self._world:GetEntityByID(targetID)
            buffLogicSvc:ChangeSkillIncrease(casterEntity, self, modifySkillIncreaseType, damageParam)
            local nTotalDamage, listDamageInfo =
                skillEffectService:ComputeSkillDamage(
                casterEntity,
                attackPos,
                target,
                gridPos,
                skillID,
                effectParam,
                SkillEffectType.Damage,
                damageStageIndex
            )
            buffLogicSvc:RemoveSkillIncrease(casterEntity, self, modifySkillIncreaseType)

            local skillResult =
                self._skillEffectService:NewSkillDamageEffectResult(
                gridPos,
                target:GetID(),
                nTotalDamage,
                listDamageInfo,
                damageStageIndex
            )
            skillEffectResultContainer:AddEffectResult(skillResult)
            table.insert(tResults, skillResult)

        end
    end
    return tResults
end
