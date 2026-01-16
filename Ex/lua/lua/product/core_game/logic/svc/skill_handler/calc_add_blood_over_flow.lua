--[[
    SkillEffectCalc_AddBloodOverFlow = 23
]]
require("calc_base")

---@class SkillEffectCalc_AddBloodOverFlow: SkillEffectCalc_Base
_class("SkillEffectCalc_AddBloodOverFlow", SkillEffectCalc_Base)
SkillEffectCalc_AddBloodOverFlow = SkillEffectCalc_AddBloodOverFlow

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_AddBloodOverFlow:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectCalcService
    local sSkillEffectCalc = self._world:GetService("SkillEffectCalc")
    ---@type BattleService
    local sBattle = self._world:GetService("Battle")
    local casterEntityId = skillEffectCalcParam:GetCasterEntityID()
    local caster = self._world:GetEntityByID(casterEntityId)
    local eTeam = caster:Pet():GetOwnerTeamEntity()
    local targetEntityIds = {eTeam:GetID()} --加血目标是队伍
    ---@type SkillEffectParam_AddBloodOverFlow
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
            local skillEffectParamSummonTrap = SkillSummonTrapEffectParam:New(skillEffectParam:GetSummonTrap())
            local targetIds = skillEffectCalcParam:GetTargetEntityIDs()
            local skillRange = skillEffectCalcParam:GetSkillRange()
            local attackPos = skillEffectCalcParam:GetAttackPos()
            ---@type SkillEffectCalcParam
            local param =
                SkillEffectCalcParam:New(
                casterEntityId,
                targetIds,
                skillEffectParamSummonTrap,
                skillId,
                skillRange,
                attackPos,
                casterPos
            )
            ---@type SkillSummonTrapEffectResult
            local resultSummonTrap = sSkillEffectCalc:CalcSkillEffectByType(param)
            skillEffectResultContainer:AddEffectResult(resultSummonTrap)
        end
    end
end
