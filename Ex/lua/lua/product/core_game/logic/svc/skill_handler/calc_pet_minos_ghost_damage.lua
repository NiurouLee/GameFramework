--[[
    PetMinosGhostDamage = 175, ---光灵米洛斯 幻影造成伤害 （伤害结果+幻影位置）
]]

_class("SkillEffectCalc_PetMinosGhostDamage", Object)
---@class SkillEffectCalc_PetMinosGhostDamage: Object
SkillEffectCalc_PetMinosGhostDamage = SkillEffectCalc_PetMinosGhostDamage

function SkillEffectCalc_PetMinosGhostDamage:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")

end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_PetMinosGhostDamage:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectPetMinosGhostDamageParam
    local param = skillEffectCalcParam.skillEffectParam
    ---@type Entity
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    local logicPath = logicChainPathCmpt:GetLogicChainPath()
    local casterEntityID = skillEffectCalcParam:GetCasterEntityID()
    local casterEntity = self._world:GetEntityByID(casterEntityID)
    self.skillID = skillEffectCalcParam.skillID
    local damageResults = {}
    local centerPos = skillEffectCalcParam:GetCenterPos()
    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    for _, targetID in ipairs(targets) do
        local dmgResult = self:_CalculateSingleTarget(skillEffectCalcParam,casterEntity, targetID)
        if dmgResult then
            table.insert(damageResults, dmgResult)
        end
    end
    local result = SkillEffectResultPetMinosGhostDamage:New(centerPos,damageResults,logicPath)
    return {result}
end
---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_PetMinosGhostDamage:_CalculateSingleTarget(skillEffectCalcParam, casterEntity,defenderEntityID)
    local targetEntity = self._world:GetEntityByID(defenderEntityID)
    if targetEntity then
        ---@type SkillDamageEffectResult
        local dmgResult = self:_Attack(casterEntity,targetEntity,skillEffectCalcParam.skillEffectParam)
        if dmgResult then
            return dmgResult
        end
    end
end
---@param  casterEntity Entity
---@param  targetEntity Entity
---@param param SkillEffectPetMinosGhostDamageParam
---@return SkillDamageEffectResult
function SkillEffectCalc_PetMinosGhostDamage:_Attack(casterEntity,targetEntity,param)
    ---@type SkillEffectCalcService
    local effectCalcSvc = self._skillEffectService
    local damageStageIndex = param:GetSkillEffectDamageStageIndex()
    local attackPos = casterEntity:GetGridPosition()
    local targetPos = targetEntity:GetGridPosition()
    local percent = param:GetDamagePercent()
    ---@type SkillDamageEffectParam
    local tmpParam =  SkillDamageEffectParam:New(
            {
                percent = percent,
                formulaID = param:GetDamageFormulaID(),
                damageStageIndex = damageStageIndex
            }
    )
    local nTotalDamage, listDamageInfo = effectCalcSvc:ComputeSkillDamage(
            casterEntity,
            attackPos,
            targetEntity,
            targetPos,
            self.skillID,
            tmpParam,
            SkillEffectType.PetMinosGhostDamage,
            damageStageIndex
    )

    local skillResult = effectCalcSvc:NewSkillDamageEffectResult(
            targetPos,
            targetEntity:GetID(),
            nTotalDamage,
            listDamageInfo,
            damageStageIndex
    )
    return skillResult
end