require("base_ins_r")
---@class PlayCasterRefreshAntiAttackInstruction: BaseInstruction
_class("PlayCasterRefreshAntiAttackInstruction", BaseInstruction)
PlayCasterRefreshAntiAttackInstruction = PlayCasterRefreshAntiAttackInstruction

function PlayCasterRefreshAntiAttackInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCasterRefreshAntiAttackInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateAntiActiveSkill, casterEntity:GetID())
end
