require("base_ins_r")
---在当前伤害索引的基础上选择下一个伤害结果
---@class DataSelectNextDamageIndexInstruction: BaseInstruction
_class("DataSelectNextDamageIndexInstruction", BaseInstruction)
DataSelectNextDamageIndexInstruction = DataSelectNextDamageIndexInstruction

function DataSelectNextDamageIndexInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataSelectNextDamageIndexInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    --选取下一个伤害数据的时候  保持阶段不变
    local damageStageIndex = phaseContext:GetCurDamageResultStageIndex()
    local damageResultArray =  skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, damageStageIndex)

    local damageIndex = phaseContext:GetCurDamageIndex()
    damageIndex = damageIndex + 1
    phaseContext:SetCurDamageIndex(damageIndex)
end
