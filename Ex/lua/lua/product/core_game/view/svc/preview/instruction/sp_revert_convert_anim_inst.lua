require("sp_base_inst")

_class("SkillPreviewRevertConvertAnimInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewRevertConvertAnimInstruction: SkillPreviewBaseInstruction
SkillPreviewRevertConvertAnimInstruction = SkillPreviewRevertConvertAnimInstruction

function SkillPreviewRevertConvertAnimInstruction:Constructor(params)

end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewRevertConvertAnimInstruction:DoInstruction(TT,casterEntity,previewContext)
	---@type MainWorld
	local world = previewContext:GetWorld()
	---@type PreviewActiveSkillService
	local previewActiveSkillService = world:GetService("PreviewActiveSkill")
	previewActiveSkillService:_RevertAllConvertElement()
end