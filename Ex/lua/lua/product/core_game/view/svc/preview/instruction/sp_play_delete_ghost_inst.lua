require("sp_base_inst")
_class("SkillPreviewPlayDeleteGhostInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayDeleteGhostInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayDeleteGhostInstruction = SkillPreviewPlayDeleteGhostInstruction

function SkillPreviewPlayDeleteGhostInstruction:Constructor(params)
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayDeleteGhostInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type RenderEntityService
    local svc = casterEntity:GetOwnerWorld():GetService("RenderEntity")
    svc:DestroyGhost()
end
