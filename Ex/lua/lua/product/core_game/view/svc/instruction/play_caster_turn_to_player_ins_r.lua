require("base_ins_r")
---@class PlayCasterTurnToPlayerInstruction: BaseInstruction
_class("PlayCasterTurnToPlayerInstruction", BaseInstruction)
PlayCasterTurnToPlayerInstruction = PlayCasterTurnToPlayerInstruction

function PlayCasterTurnToPlayerInstruction:Constructor(paramList)
    self._force = tonumber(paramList["force"]) or 0
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCasterTurnToPlayerInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    local teamEntity = world:Player():GetLocalTeamEntity()
    local teamLeaderEntity = teamEntity:GetTeamLeaderPetEntity()
    ---@type RenderEntityService
    local resvc = world:GetService("RenderEntity")
    resvc:TurnToTarget(casterEntity, teamLeaderEntity, self._force)
end
