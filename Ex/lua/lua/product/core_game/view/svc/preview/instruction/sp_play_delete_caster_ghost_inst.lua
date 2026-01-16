require("sp_base_inst")
_class("SkillPreviewPlayDeleteCasterGhostInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayDeleteCasterGhostInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayDeleteCasterGhostInstruction = SkillPreviewPlayDeleteCasterGhostInstruction

function SkillPreviewPlayDeleteCasterGhostInstruction:Constructor(params)
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayDeleteCasterGhostInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type RenderEntityService
    local svc = casterEntity:GetOwnerWorld():GetService("RenderEntity")
    svc:DestroyGhost()
end
