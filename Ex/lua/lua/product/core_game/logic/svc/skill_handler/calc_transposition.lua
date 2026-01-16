--[[
Transposition = 183, --互换位置
]]
---@class SkillEffectCalc_Transposition: Object
_class("SkillEffectCalc_Transposition", Object)
SkillEffectCalc_Transposition = SkillEffectCalc_Transposition

function SkillEffectCalc_Transposition:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_Transposition:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    ---@type SkillEffectParamTransposition
    local skillEffectParam = skillEffectCalcParam.skillEffectParam
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
    ---[KZY:SkillHolder去Self]
    if skillEffectParam:IsUseSuper() and casterEntity:HasSuperEntity() then
        casterEntity = casterEntity:GetSuperEntity()
    end

    local targetMonsterClassID = skillEffectParam:GetMonsterClassID()
    local targetEntity = nil
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local monsterList, monsterPosList = utilScopeSvc:SelectAllMonster()
    for i, e in ipairs(monsterList) do
        local monsterClassID = e:MonsterID():GetMonsterClassID()
        if monsterClassID == targetMonsterClassID then
            targetEntity = e
            break
        end
    end

    if not targetEntity then
        return {}
    end

    ---@type SkillEffectResult_Teleport
    local resultCaster = self:_CalcTeleportResult(casterEntity, targetEntity, skillEffectCalcParam)
    table.insert(results, resultCaster)

    ---@type SkillEffectResult_Teleport
    local resultTarget = self:_CalcTeleportResult(targetEntity, casterEntity, skillEffectCalcParam)
    table.insert(results, resultTarget)

    return results
end

function SkillEffectCalc_Transposition:_CalcTeleportResult(entity, targetEntity, skillEffectCalcParam)
    local posOld = entity:GetGridPosition()
    local posNew = targetEntity:GetGridPosition()

    ---@type UtilDataServiceSharePlayRoleTeleport
    local utilData = self._world:GetService("UtilData")
    local colorOld = utilData:FindPieceElement(posOld)
    local dirNew = posNew - posOld
    local stageIndex = skillEffectCalcParam.skillEffectParam:GetSkillEffectDamageStageIndex()
    ---@type SkillEffectResult_Teleport
    local result = SkillEffectResult_Teleport:New(entity:GetID(), posOld, colorOld, posNew, dirNew, stageIndex)

    return result
end
