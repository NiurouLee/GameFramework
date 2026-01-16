require("base_ins_r")
---怪物逃脱 通知ui
---@class PlayUIAddEscapeCountInstruction: BaseInstruction
_class("PlayUIAddEscapeCountInstruction", BaseInstruction)
PlayUIAddEscapeCountInstruction = PlayUIAddEscapeCountInstruction

function PlayUIAddEscapeCountInstruction:Constructor(paramList)
    self._addNum = tonumber(paramList["addNum"]) or 1
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayUIAddEscapeCountInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    world:EventDispatcher():Dispatch(GameEventType.UIUpdateEscapeMonsterCount, self._addNum)
end
