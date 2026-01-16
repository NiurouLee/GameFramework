require("base_ins_r")
---在当前伤害索引的基础上选择下一个伤害结果
---@class DataSelectNextBuffInstruction: BaseInstruction
_class("DataSelectNextBuffInstruction", BaseInstruction)
DataSelectNextBuffInstruction = DataSelectNextBuffInstruction

function DataSelectNextBuffInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataSelectNextBuffInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local addBuffResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.AddBuff)

    local buffIndex = phaseContext:GetCurBuffResultIndex()
    buffIndex = buffIndex + 1
    phaseContext:SetCurBuffResultIndex(buffIndex)

    if not addBuffResultArray then
        phaseContext:SetCurTargetEntityID(-1)
        return
    end
    ---伤害索引无效，可以返回
    if buffIndex > #addBuffResultArray then
        phaseContext:SetCurTargetEntityID(-1)
        return
    end

    ---@type SkillDamageEffectResult
    local buffResult = addBuffResultArray[buffIndex]
    if buffResult == nil or next(buffResult._newBuffArray) == nil then
        phaseContext:SetCurTargetEntityID(-1)
        return
    end

    local targetEntityID = buffResult:GetEntityID()
    phaseContext:SetCurTargetEntityID(targetEntityID)
end
