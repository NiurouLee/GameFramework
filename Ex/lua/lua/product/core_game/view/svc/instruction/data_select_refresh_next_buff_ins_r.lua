require("base_ins_r")
---在当前伤害索引的基础上选择下一个伤害结果
---@class DataSelectRefreshNextBuffInstruction: BaseInstruction
_class("DataSelectRefreshNextBuffInstruction", BaseInstruction)
DataSelectRefreshNextBuffInstruction = DataSelectRefreshNextBuffInstruction

function DataSelectRefreshNextBuffInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataSelectRefreshNextBuffInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local refreshBuffResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.ModifyBuffValue)

    local buffIndex = phaseContext:GetCurBuffResultIndex()
    buffIndex = buffIndex + 1
    phaseContext:SetCurBuffResultIndex(buffIndex)

    if not refreshBuffResultArray then
        phaseContext:SetCurTargetEntityID(-1)
        return
    end
    ---索引无效，可以返回
    if buffIndex > #refreshBuffResultArray then
        phaseContext:SetCurTargetEntityID(-1)
        return
    end

    ---@type SkillModifyBuffValueResult
    local buffResult = refreshBuffResultArray[buffIndex]
    if buffResult == nil then
        phaseContext:SetCurTargetEntityID(-1)
        return
    end

    local targetEntityID = buffResult:GetEntityID()
    phaseContext:SetCurTargetEntityID(targetEntityID)
end
