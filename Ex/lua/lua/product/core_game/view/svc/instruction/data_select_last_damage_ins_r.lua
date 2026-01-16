require("base_ins_r")
---选择一个伤害结果
---@class DataSelectLastDamageInstruction: BaseInstruction
_class("DataSelectLastDamageInstruction", BaseInstruction)
DataSelectLastDamageInstruction = DataSelectLastDamageInstruction

function DataSelectLastDamageInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataSelectLastDamageInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    --local skillViewID = self:GetSkillViewID(casterEntity)

    local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
    if damageResultArray == nil then
        Log.fatal("[ins] caster has no damage")
        return InstructionConst.PhaseEnd
    end
    local damageIndex = #damageResultArray
    ---@type SkillDamageEffectResult
    local damageResult = damageResultArray[damageIndex]
    if damageResult == nil then
        phaseContext:SetCurDamageResultIndex(-1)
        phaseContext:SetCurTargetEntityID(-1)
        return
    end
    local targetEntityID = damageResult:GetTargetID()
    phaseContext:SetCurDamageResultIndex(damageIndex)
    phaseContext:SetCurTargetEntityID(targetEntityID)
end
