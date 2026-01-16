require("base_ins_r")
---选择一个伤害结果
---@class DataSelectDamageInstruction: BaseInstruction
_class("DataSelectDamageInstruction", BaseInstruction)
DataSelectDamageInstruction = DataSelectDamageInstruction

function DataSelectDamageInstruction:Constructor(paramList)
    self._damageIndex = tonumber(paramList["damageIndex"])
    self._damageStageIndex = tonumber(paramList["damageStageIndex"]) or 1
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataSelectDamageInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    --local skillViewID = self:GetSkillViewID(casterEntity)

    if skillEffectResultContainer == nil then
        return InstructionConst.PhaseEnd
    end

    local damageResultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, self._damageStageIndex)
    if damageResultArray == nil then
        Log.fatal("[ins] caster has no damage:", tostring(casterEntity:GridLocation().Position))
        return InstructionConst.PhaseEnd
    end

    ---@type SkillDamageEffectResult
    local damageResult = damageResultArray[self._damageIndex]
    if damageResult == nil then
        phaseContext:SetCurDamageResultIndex(-1)
        phaseContext:SetCurDamageResultStageIndex(-1)
        phaseContext:SetCurTargetEntityID(-1)
        return
    end

    local targetEntityID = damageResult:GetTargetID()

    phaseContext:SetCurDamageResultIndex(self._damageIndex)
    phaseContext:SetCurDamageResultStageIndex(self._damageStageIndex)
    phaseContext:SetCurTargetEntityID(targetEntityID)
end
