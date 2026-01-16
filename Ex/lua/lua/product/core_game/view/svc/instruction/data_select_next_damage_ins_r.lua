require("base_ins_r")
---在当前伤害索引的基础上选择下一个伤害结果
---@class DataSelectNextDamageInstruction: BaseInstruction
_class("DataSelectNextDamageInstruction", BaseInstruction)
DataSelectNextDamageInstruction = DataSelectNextDamageInstruction

function DataSelectNextDamageInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataSelectNextDamageInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    --选取下一个伤害数据的时候  保持阶段不变
    local damageStageIndex = phaseContext:GetCurDamageResultStageIndex()
    local damageResultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, damageStageIndex)

    local damageIndex = phaseContext:GetCurDamageResultIndex()
    damageIndex = damageIndex + 1
    phaseContext:SetCurDamageResultIndex(damageIndex)

    ---伤害索引无效，可以返回/ 拾取点释放带有多段伤害的技能
    if damageIndex > #damageResultArray or #damageResultArray == 0 then
        phaseContext:SetCurTargetEntityID(-1)
        return
    end

    ---@type SkillDamageEffectResult
    local damageResult = damageResultArray[damageIndex]
    local targetEntityID = damageResult:GetTargetID()
    phaseContext:SetCurTargetEntityID(targetEntityID)
end
