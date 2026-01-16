require("base_ins_r")
---选择在固定配置的位置上召唤N个机关的召唤结果，一个技能内只能配置一个此技能效果类型，每次召唤配置的M个机关
---@class DataSelectSummonOnFixPosInstruction: BaseInstruction
_class("DataSelectSummonOnFixPosInstruction", BaseInstruction)
DataSelectSummonOnFixPosInstruction = DataSelectSummonOnFixPosInstruction

function DataSelectSummonOnFixPosInstruction:Constructor(paramList)
    ---此处的index为召唤结果中的序号，并非技能配置中技能效果的序号
    self._summonIndex = tonumber(paramList.index)
    assert(self._summonIndex, "DataSelectSummonOnFixPos需要配置index")
end

---@param TT TaskToken
---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataSelectSummonOnFixPosInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    if not skillEffectResultContainer then
        Log.fatal("DataSelectSummonOnFixPosInstruction error: no data result container.")
        return
    end

    ---@type SkillEffectResultSummonOnFixPosLimit[]
    local summonResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SummonOnFixPosLimit)
    if not summonResultArray then
        Log.error("Get SummonOnFixPosLimit result failed.")
        return
    end

    --固定位置召唤的结果只存放在一个结果内，而非数组，所以此处取第一个即可。
    ---@type SkillEffectResultSummonOnFixPosLimit
    local result = summonResultArray[1]
    local trapIDList = result:GetTrapIDList()
    if not trapIDList then
        Log.error("GetTrapIDList trap list is null.")
        return
    end
    local trapID = trapIDList[self._summonIndex]

    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type Entity
    local eTrap = world:GetEntityByID(trapID)
    if not eTrap then
        phaseContext:SetCurSummonOnFixPosIndex(-1)
        phaseContext:SetCurTargetEntityID(-1)
        return
    end

    phaseContext:SetCurSummonInEverythingIndex(self._summonIndex)
    if eTrap then
        phaseContext:SetCurTargetEntityID(trapID)
    end
end
