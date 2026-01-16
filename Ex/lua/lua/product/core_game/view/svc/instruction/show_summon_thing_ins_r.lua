require("base_ins_r")
---显示召唤出来的东西
---@class ShowSummonThingInstruction: BaseInstruction
_class("ShowSummonThingInstruction", BaseInstruction)
ShowSummonThingInstruction = ShowSummonThingInstruction

function ShowSummonThingInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function ShowSummonThingInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    if skillEffectResultContainer == nil then 
        Log.fatal("ShowSummonThingInstruction has no skill effect result")
        return 
    end

    ---@type SkillEffectResult_SummonEverything[]
    local summonResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SummonEverything)
    if not summonResultArray then
        return
    end
    local idx = phaseContext:GetCurSummonInEverythingIndex()
    ---@type SkillEffectResult_SummonEverything
    local summonRes = summonResultArray[idx]
    if not summonRes then
        Log.fatal("### ShowSummonThingInstruction SkillEffectResult_SummonEverything nil")
        return
    end
    ---@type SkillEffectEnum_SummonType
    local summonType = summonRes:GetSummonType()
    local summonTrapID = summonRes:GetSummonID()
    local sPlaySkillInstruction = self:PlaySkillInstruction(casterEntity)
    if summonType == SkillEffectEnum_SummonType.Monster then
        sPlaySkillInstruction:ShowSummonAction(TT, world, summonRes)
    elseif summonType == SkillEffectEnum_SummonType.Trap then
        local inst = PlaySummonTrapInstruction:New({})
        inst:_ShowTrapFromSummonEverything(TT, world, summonRes)
    else
        Log.fatal("### ShowSummonThingInstruction summonType=", summonType)
    end
end
