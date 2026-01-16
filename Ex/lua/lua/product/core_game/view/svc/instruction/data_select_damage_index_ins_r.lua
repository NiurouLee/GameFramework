require("base_ins_r")
---选择一个伤害结果
---@class DataSelectDamageIndexInstruction: BaseInstruction
_class("DataSelectDamageIndexInstruction", BaseInstruction)
DataSelectDamageIndexInstruction = DataSelectDamageIndexInstruction

function DataSelectDamageIndexInstruction:Constructor(paramList)
    self._damageIndex = tonumber(paramList["damageIndex"])
    self._damageStageIndex = tonumber(paramList["damageStageIndex"]) or 1
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataSelectDamageIndexInstruction:DoInstruction(TT, casterEntity, phaseContext)
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

    local bFind = false
    ---@param damageResult SkillDamageEffectResult
    for i, damageResult in ipairs(damageResultArray) do
        if damageResult:GetDamageIndex() == self._damageIndex then
            bFind = true
            break
        end
    end
    if bFind == false then
        phaseContext:SetCurDamageResultIndex(-1)
        phaseContext:SetCurDamageResultStageIndex(-1)
        phaseContext:SetCurTargetEntityID(-1)
        return
    end

    phaseContext:SetCurDamageIndex(self._damageIndex)
    phaseContext:SetCurDamageResultStageIndex(self._damageStageIndex)
end
