require("base_ins_r")
---通知ui显示Boss释放技能提示
---@class PlayShowUIBossCastSkillTipInstruction: BaseInstruction
_class("PlayShowUIBossCastSkillTipInstruction", BaseInstruction)
PlayShowUIBossCastSkillTipInstruction = PlayShowUIBossCastSkillTipInstruction

function PlayShowUIBossCastSkillTipInstruction:Constructor(paramList)
    self._maxNum = tonumber(paramList["maxNum"]) or 30
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayShowUIBossCastSkillTipInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    world:EventDispatcher():Dispatch(GameEventType.UIInitBossCastSkillTipInfo, self._maxNum)
end
