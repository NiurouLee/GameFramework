---Break可以打断Wait
require("sp_base_inst")
_class("SkillPreviewBreakInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewBreakInstruction: SkillPreviewBaseInstruction
SkillPreviewBreakInstruction = SkillPreviewBreakInstruction

function SkillPreviewBreakInstruction:Constructor(params)
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewBreakInstruction:DoInstruction(TT, casterEntity, previewContext)
    previewContext:SetBreakState(true)
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = previewContext:GetWorld():GetService("PreviewActiveSkill")
    previewActiveSkillService:ResetPreview()
end
