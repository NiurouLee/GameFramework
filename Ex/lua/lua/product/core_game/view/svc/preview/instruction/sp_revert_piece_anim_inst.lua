require("sp_base_inst")
---所有格子恢复Normal
_class("SkillPreviewRevertPieceAnimInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewRevertPieceAnimInstruction: SkillPreviewBaseInstruction
SkillPreviewRevertPieceAnimInstruction = SkillPreviewRevertPieceAnimInstruction

function SkillPreviewRevertPieceAnimInstruction:Constructor(params)

end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewRevertPieceAnimInstruction:DoInstruction(TT,casterEntity,previewContext)
	---@type MainWorld
	local world = previewContext:GetWorld()
	---@type PreviewActiveSkillService
	local previewActiveSkillService = world:GetService("PreviewActiveSkill")
	previewActiveSkillService:_RevertBright()
end