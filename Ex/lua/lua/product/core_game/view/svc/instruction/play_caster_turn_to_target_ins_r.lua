require("base_ins_r")
---@class PlayCasterTurnToTargetInstruction: BaseInstruction
_class("PlayCasterTurnToTargetInstruction", BaseInstruction)
PlayCasterTurnToTargetInstruction = PlayCasterTurnToTargetInstruction

function PlayCasterTurnToTargetInstruction:Constructor(paramList)
    self._force = tonumber(paramList["force"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCasterTurnToTargetInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local targetEntityID = phaseContext:GetCurTargetEntityID()
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    local targetEntity = world:GetEntityByID(targetEntityID)
    ---@type RenderEntityService
    local resvc = world:GetService("RenderEntity")
    resvc:TurnToTarget(casterEntity, targetEntity, self._force)
end
