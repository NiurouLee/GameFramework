require("base_ins_r")
---@class DataSelectNextSummonThingInstruction: BaseInstruction
_class("DataSelectNextSummonThingInstruction", BaseInstruction)
DataSelectNextSummonThingInstruction = DataSelectNextSummonThingInstruction

function DataSelectNextSummonThingInstruction:Constructor(paramList)
end

---@param TT TaskToken
---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataSelectNextSummonThingInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    if skillEffectResultContainer == nil then 
        Log.fatal("DataSelectNextSummonThingInstruction has no result")
        return 
    end

    ---@type SkillEffectResult_SummonEverything[]
    local summonEverythingResultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SummonEverything)
    ---@type SkillEffectResult_SummonEverything
    -- local summonEverythingResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.SummonEverything)
    if not summonEverythingResultArray then
        return
    end

    assert(#summonEverythingResultArray > 0, "DataSelectNextSummonThing目前只对SummonEverything有效")

    local summonIndex = phaseContext:GetCurSummonInEverythingIndex()
    summonIndex = summonIndex + 1

    phaseContext:SetCurSummonInEverythingIndex(-1)
    phaseContext:SetCurTargetEntityID(-1)
    ---索引无效，可以返回
    if summonIndex > #summonEverythingResultArray then
        return
    end

    ---@type SkillEffectResult_SummonEverything
    local result = summonEverythingResultArray[summonIndex]
    local tmpData = result:GetMonsterData()
    local entityWorkID = tmpData.m_entityWorkID
    if not entityWorkID then
        tmpData = result:GetTrapData()
        entityWorkID = tmpData.m_entityWorkID
    end

    -- 结果数据里硬带着entity引用？万一中间实体销毁了呢？？
    local world = casterEntity:GetOwnerWorld()
    ---@type Entity
    local entityWork = world:GetEntityByID(entityWorkID)

    if not entityWork then
        phaseContext:SetCurSummonInEverythingIndex(-1)
        phaseContext:SetCurTargetEntityID(-1)
        return
    end

    phaseContext:SetCurSummonInEverythingIndex(summonIndex)
    if entityWork then
        phaseContext:SetCurTargetEntityID(entityWorkID)
    end
end
