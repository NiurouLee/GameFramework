--[[
    AddBloodOverFlowForDamage = 127, ---恢复生命，如果溢出则将溢出的治疗量，给范围内的所有敌人造成伤害
]]
require("calc_base")

---@class SkillEffectCalc_AddBloodOverFlowForDamage: SkillEffectCalc_Base
_class("SkillEffectCalc_AddBloodOverFlowForDamage", SkillEffectCalc_Base)
SkillEffectCalc_AddBloodOverFlowForDamage = SkillEffectCalc_AddBloodOverFlowForDamage

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_AddBloodOverFlowForDamage:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectCalcService
    local sSkillEffectCalc = self._world:GetService("SkillEffectCalc")
    ---@type BattleService
    local sBattle = self._world:GetService("Battle")
    local casterEntityId = skillEffectCalcParam:GetCasterEntityID()
    local caster = self._world:GetEntityByID(casterEntityId)
    local eTeam = caster:Pet():GetOwnerTeamEntity()
    local targetEntityIds = {eTeam:GetID()} --加血目标是队伍
    ---@type SkillEffectParam_AddBloodOverFlowForDamage
    local skillEffectParam = skillEffectCalcParam.skillEffectParam

    local skillEffectParamAddBlood = SkillEffectParam_AddBlood:New(skillEffectParam:GetAddBlood())
    local skillId = skillEffectCalcParam:GetSkillID()
    local casterPos = caster:GridLocation():GetGridPos()
    local range = {casterPos} --施法者位置数组
    ---@type SkillEffectCalcParam
    local param =
        SkillEffectCalcParam:New(
        casterEntityId,
        targetEntityIds,
        skillEffectParamAddBlood,
        skillId,
        range,
        casterPos,
        casterPos
    )
    ---@type SkillEffectResult_AddBlood[]
    local resultList = sSkillEffectCalc:CalcSkillEffectByType(param)
    --加血结果入SkillRoutine
    local skillEffectResultContainer = caster:SkillContext():GetResultContainer()
    for index, result in ipairs(resultList) do
        skillEffectResultContainer:AddEffectResult(result)
        --如果给队伍加血溢出
        local addValue = result:GetAddValue()
        local maxHP = eTeam:Attributes():CalcMaxHp()
        local curHP = eTeam:Attributes():GetCurrentHP()
        local spilled = addValue + curHP - maxHP
        if spilled > 0 then
            local damageParam = skillEffectParam:GetDamage()

            ---@type SkillDamageEffectParam
            local skillDamageParam = SkillDamageEffectParam:New(skillEffectParam:GetDamage())
            if skillDamageParam then
                ---@type SkillEffectCalcService
                local effectCalcSvc = self._skillEffectService
                skillDamageParam.damageValue = spilled
                local skillRange = skillEffectCalcParam:GetSkillRange()
                local attackPos = skillEffectCalcParam:GetAttackPos()
                local damageStageIndex = skillDamageParam:GetSkillEffectDamageStageIndex()

                -- local targets = skillEffectCalcParam:GetTargetEntityIDs()

                --重新计算技能目标
                local curBodyArea = caster:BodyArea():GetArea()
                ---@type UtilScopeCalcServiceShare
                local utilScopeSvc = self._world:GetService("UtilScopeCalc")
                ---@type SkillScopeCalculator
                local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
                ---@type SkillScopeResult
                local scopeResult =
                    scopeCalculator:ComputeScopeRange(
                    damageParam.scopeType,
                    damageParam.scopeParam,
                    casterPos,
                    curBodyArea
                )

                --计算范围内目标
                ---@type SkillScopeTargetSelector
                local targetSelector = self._world:GetSkillScopeTargetSelector()
                local targetEntityIDArray =
                    targetSelector:DoSelectSkillTarget(caster, damageParam.scopeTargetType, scopeResult)

                --打单体 排重
                local targetIDs = {}
                for _, targetID in ipairs(targetEntityIDArray) do
                    if not table.intable(targetIDs, targetID) then
                        table.insert(targetIDs, targetID)
                    end
                end

                --按照目标  每个目标计算一次效果  赋值grid
                for _, targetID in ipairs(targetIDs) do
                    ---@type Entity
                    local defender = self._world:GetEntityByID(targetID)
                    --范围内没有目标  targetID 可能是-1
                    if defender then
                        local gridPos = defender:GetGridPosition()

                        local nTotalDamage, listDamageInfo =
                            effectCalcSvc:ComputeSkillDamage(
                            caster,
                            attackPos,
                            defender,
                            gridPos,
                            skillEffectCalcParam.skillID,
                            skillDamageParam,
                            SkillEffectType.Damage,
                            damageStageIndex
                        )

                        local skillResult =
                            effectCalcSvc:NewSkillDamageEffectResult(
                            gridPos,
                            targetID,
                            nTotalDamage,
                            listDamageInfo,
                            damageStageIndex
                        )

                        skillEffectResultContainer:AddEffectResult(skillResult)
                    end
                end
            end
        end
    end
end
