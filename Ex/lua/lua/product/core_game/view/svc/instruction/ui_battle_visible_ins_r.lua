require("base_ins_r")
---@class UiBattleVisibleInstruction: BaseInstruction
_class("UiBattleVisibleInstruction", BaseInstruction)
UiBattleVisibleInstruction = UiBattleVisibleInstruction

function UiBattleVisibleInstruction:Constructor(paramList)
    self._visible = tonumber(paramList["visible"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function UiBattleVisibleInstruction:DoInstruction(TT, casterEntity, phaseContext)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UiBattleVisible, self._visible)
end
