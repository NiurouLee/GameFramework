require("base_ins_r")
---在当前索引的基础上选择下一个死亡的目标
---@class DataSelectNextDeadTargetInstruction: BaseInstruction
_class("DataSelectNextDeadTargetInstruction", BaseInstruction)
DataSelectNextDeadTargetInstruction = DataSelectNextDeadTargetInstruction

function DataSelectNextDeadTargetInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataSelectNextDeadTargetInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    --选取下一个伤害数据的时候  保持阶段不变
    local damageStageIndex = phaseContext:GetCurDamageResultStageIndex()
    local damageResultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, damageStageIndex)
    ---伤害索引无效，可以返回/ 拾取点释放带有多段伤害的技能
    if not damageResultArray or #damageResultArray == 0 then
        return false
    end

    local targetEntityList = {}

    for _, v in ipairs(damageResultArray) do
        ---@type SkillDamageEffectResult
        local damageResult = v
        local targetEntityID = damageResult:GetTargetID()
        local targetEntity = world:GetEntityByID(targetEntityID)
        --技能没有造成伤害 也会返回一个 targetID -1 的技能结果
        if targetEntity and not table.intable(targetEntityList, targetEntity) then
            table.insert(targetEntityList, targetEntity)
        end
    end

    local deadMonsterIDList = {}
    for _, entity in ipairs(targetEntityList) do
        local view = entity:View()
        local renderCurHP = entity:HP():GetRedHP()

        if view and renderCurHP == 0 then
            table.insert(deadMonsterIDList, entity:GetID())
        end
    end

    local damageIndex = phaseContext:GetCurDamageResultIndex()
    damageIndex = damageIndex + 1
    phaseContext:SetCurDamageResultIndex(damageIndex)

    ---伤害索引无效，可以返回/ 拾取点释放带有多段伤害的技能
    if damageIndex > #deadMonsterIDList or #deadMonsterIDList == 0 then
        phaseContext:SetCurTargetEntityID(-1)
        return
    end

    local targetEntityID = deadMonsterIDList[damageIndex]
    phaseContext:SetCurTargetEntityID(targetEntityID)
end
