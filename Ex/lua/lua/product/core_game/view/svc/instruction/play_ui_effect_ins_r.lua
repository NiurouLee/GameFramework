require("base_ins_r")
---播放UI效果
---@class PlayUIEffectInstruction: BaseInstruction
_class("PlayUIEffectInstruction", BaseInstruction)
PlayUIEffectInstruction = PlayUIEffectInstruction

function PlayUIEffectInstruction:Constructor(paramList)
    self._prefabName = paramList["effectName"]
    self._duaration = paramList["duaration"]
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayUIEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    world:EventDispatcher():Dispatch(GameEventType.PlayBattleUIEffect, self._prefabName, self._duaration)
end
