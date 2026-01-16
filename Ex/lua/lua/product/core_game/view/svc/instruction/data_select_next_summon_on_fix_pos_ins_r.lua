require("base_ins_r")
---选择在固定配置的位置上召唤N个机关的下一个召唤结果
---@class DataSelectNextSummonOnFixPosInstruction: BaseInstruction
_class("DataSelectNextSummonOnFixPosInstruction", BaseInstruction)
DataSelectNextSummonOnFixPosInstruction = DataSelectNextSummonOnFixPosInstruction

function DataSelectNextSummonOnFixPosInstruction:Constructor(paramList)
end

---@param TT TaskToken
---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataSelectNextSummonOnFixPosInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    if skillEffectResultContainer == nil then
        Log.fatal("DataSelectNextSummonOnFixPosInstruction  error: no data result container.")
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
    local summonIndex = phaseContext:GetCurSummonOnFixPosIndex()
    summonIndex = summonIndex + 1

    phaseContext:SetCurSummonOnFixPosIndex(-1)
    phaseContext:SetCurTargetEntityID(-1)
    ---索引无效，可以返回
    if summonIndex > #trapIDList then
        return
    end

    local trapID = trapIDList[summonIndex]
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type Entity
    local eTrap = world:GetEntityByID(trapID)
    if not eTrap then
        return
    end

    phaseContext:SetCurSummonOnFixPosIndex(summonIndex)
    if eTrap then
        phaseContext:SetCurTargetEntityID(trapID)
    end
end
