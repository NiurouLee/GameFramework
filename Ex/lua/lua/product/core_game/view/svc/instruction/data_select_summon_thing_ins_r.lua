require("base_ins_r")
---@class DataSelectSummonThingInstruction: BaseInstruction
_class("DataSelectSummonThingInstruction", BaseInstruction)
DataSelectSummonThingInstruction = DataSelectSummonThingInstruction

function DataSelectSummonThingInstruction:Constructor(paramList)
    self._summonIndex = tonumber(paramList.index)
    assert(self._summonIndex, "DataSelectSummonThing需要配置index")
end

---@param TT TaskToken
---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataSelectSummonThingInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    if not skillEffectResultContainer then 
        Log.fatal("DataSelectSummonThingInstruction error,has no data result container")
        return 
    end


    ---@type SkillEffectResult_SummonEverything[]
    local summonEverythingResultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SummonEverything)
    if not summonEverythingResultArray then
        Log.fatal("### Get SummonEverything result failed.")
        return
    end

    assert(#summonEverythingResultArray > 0, "DataSelectNextSummonThing目前只对SummonEverything有效")

    ---@type SkillEffectResult_SummonEverything
    local result = summonEverythingResultArray[self._summonIndex]
    if not result then
        Log.fatal("### Get SummonEverything invalid index: ", tostring(self._summonIndex))
        return
    end
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

    phaseContext:SetCurSummonInEverythingIndex(self._summonIndex)
    if entityWork then
        phaseContext:SetCurTargetEntityID(entityWorkID)
    end
end
