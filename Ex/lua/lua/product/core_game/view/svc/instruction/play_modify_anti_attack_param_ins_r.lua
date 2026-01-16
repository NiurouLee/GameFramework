require("base_ins_r")
---@class PlayModifyAntiAttackParamInstruction: BaseInstruction
_class("PlayModifyAntiAttackParamInstruction", BaseInstruction)
PlayModifyAntiAttackParamInstruction = PlayModifyAntiAttackParamInstruction

function PlayModifyAntiAttackParamInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayModifyAntiAttackParamInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateAntiActiveSkill, casterEntity:GetID())
end
