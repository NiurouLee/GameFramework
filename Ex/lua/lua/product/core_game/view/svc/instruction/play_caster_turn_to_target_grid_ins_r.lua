require("base_ins_r")
---@class PlayCasterTurnToTargetGridInstruction: BaseInstruction
_class("PlayCasterTurnToTargetGridInstruction", BaseInstruction)
PlayCasterTurnToTargetGridInstruction = PlayCasterTurnToTargetGridInstruction

function PlayCasterTurnToTargetGridInstruction:Constructor(paramList)

end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCasterTurnToTargetGridInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local targetEntityID = phaseContext:GetCurTargetEntityID()
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    local targetEntity = world:GetEntityByID(targetEntityID)
    ---@type RenderEntityService
    local resvc = world:GetService("RenderEntity")
    resvc:TurnToTargetGrid(casterEntity, targetEntity)
end
