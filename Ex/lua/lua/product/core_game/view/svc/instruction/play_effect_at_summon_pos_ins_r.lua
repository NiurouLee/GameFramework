require("base_ins_r")
---在召唤结果的位置播放特效
---@class PlayEffectAtSummonPosInstruction: BaseInstruction
_class("PlayEffectAtSummonPosInstruction", BaseInstruction)
PlayEffectAtSummonPosInstruction = PlayEffectAtSummonPosInstruction

function PlayEffectAtSummonPosInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayEffectAtSummonPosInstruction:DoInstruction(TT, casterEntity, phaseContext)
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

    local posSummon = summonRes:GetSummonPos()

    Log.error("PlayEffectAtSummonPos     ", posSummon)

    ---@type EffectService
    local sEffect = world:GetService("Effect")
    sEffect:CreateWorldPositionEffect(self._effectID, posSummon)
end

function PlayEffectAtSummonPosInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    return t
end
