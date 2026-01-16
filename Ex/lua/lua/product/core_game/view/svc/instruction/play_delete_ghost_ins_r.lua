require("base_ins_r")
---删除虚影
---@class PlayDeleteGhostInstruction: BaseInstruction
_class("PlayDeleteGhostInstruction", BaseInstruction)
PlayDeleteGhostInstruction = PlayDeleteGhostInstruction

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayDeleteGhostInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type RenderEntityService
    local svc = casterEntity:GetOwnerWorld():GetService("RenderEntity")
    svc:DestroyGhost()
end