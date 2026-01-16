require("sp_base_inst")
---范围内目标MaterialAnim
_class("SkillPreviewDeleteArrowInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewDeleteArrowInstruction: SkillPreviewBaseInstruction
SkillPreviewDeleteArrowInstruction = SkillPreviewDeleteArrowInstruction

function SkillPreviewDeleteArrowInstruction:Constructor(params)
    self._number = params["Number"]
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewDeleteArrowInstruction:DoInstruction(TT, casterEntity, previewContext)
    local world = previewContext:GetWorld()
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = world:GetService("PreviewActiveSkill")
    previewActiveSkillService:DestroyPickUpArrow()
end
