require("base_ins_r")
---@class PlayTargetTurnToCasterInstruction: BaseInstruction
_class("PlayTargetTurnToCasterInstruction", BaseInstruction)
PlayTargetTurnToCasterInstruction = PlayTargetTurnToCasterInstruction

function PlayTargetTurnToCasterInstruction:Constructor(paramList)

end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTargetTurnToCasterInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local targetEntityID = phaseContext:GetCurTargetEntityID()
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    local targetEntity = world:GetEntityByID(targetEntityID)
    ---@type RenderEntityService
    local resvc = world:GetService("RenderEntity")
    resvc:TurnToTarget(targetEntity, casterEntity)
end