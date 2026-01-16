--[[
    附身 跟脱离对应使用
]]
require("calc_base")

---@class SkillEffectCalcAttachMonster: SkillEffectCalc_Base
_class("SkillEffectCalcAttachMonster", SkillEffectCalc_Base)
SkillEffectCalcAttachMonster = SkillEffectCalcAttachMonster

function SkillEffectCalcAttachMonster:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalcAttachMonster:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    for _, targetID in ipairs(targets) do
        local result = self:_CalculateSingleTarget(skillEffectCalcParam, targetID)
        if result then
            table.insert(results, result)
        end
    end

    return results
end

---@param skillEffectCalcParam SkillEffectCalcParam
---@param targetID number
function SkillEffectCalcAttachMonster:_CalculateSingleTarget(skillEffectCalcParam, targetID)
    local casterID = skillEffectCalcParam:GetCasterEntityID()
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(casterID)
    ---@type Entity
    local targetEntity = self._world:GetEntityByID(targetID)

    ---@type AIComponentNew
    local aiComponent = casterEntity:AI()
    aiComponent:SetRuntimeData("AttachMonsterID", targetID)

    self._world:GetService("Trigger"):Notify(NTAttachMonster:New(casterEntity, targetEntity))

    local eliteIDArray = self:_CalculateAddEliteIDArray(skillEffectCalcParam, casterEntity, targetEntity) or {}

    return SkillEffectAttachMonsterResult:New(targetID, eliteIDArray)
end

---@param skillEffectCalcParam SkillEffectCalcParam
---@param casterEntity Entity
---@param targetEntity Entity
function SkillEffectCalcAttachMonster:_CalculateAddEliteIDArray(skillEffectCalcParam, casterEntity, targetEntity)
    local addEliteIDArray = {}

    ---@type SkillEffectAttachMonsterParam
    local skillParam = skillEffectCalcParam:GetSkillEffectParam()
    if not skillParam:IsAddElite() then
        return
    end

    ---@type MonsterIDComponent
    local casterMonsterIDCmpt = casterEntity:MonsterID()
    if not casterMonsterIDCmpt then
        return
    end
    local casterEliteIDArray = casterMonsterIDCmpt:GetEliteIDArray()
    if #casterEliteIDArray == 0 then
        return
    end

    ---@type MonsterIDComponent
    local targetMonsterIDCmpt = targetEntity:MonsterID()
    if not targetMonsterIDCmpt then
        return
    end
    local targetEliteIDArray = targetMonsterIDCmpt:GetEliteIDArray()
    

    for _, id in ipairs(casterEliteIDArray) do
        if not table.icontains(targetEliteIDArray, id) then
            table.insert(addEliteIDArray, id)
        end
    end

    return addEliteIDArray
end
