require("sp_base_inst")
---范围内目标MaterialAnim
_class("SkillPreviewDataSetHitBackDirInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewDataSetHitBackDirInstruction: SkillPreviewBaseInstruction
SkillPreviewDataSetHitBackDirInstruction = SkillPreviewDataSetHitBackDirInstruction

function SkillPreviewDataSetHitBackDirInstruction:Constructor(params)

end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewDataSetHitBackDirInstruction:DoInstruction(TT,casterEntity,previewContext)
	local world = previewContext:GetWorld()
	---@type PreviewActiveSkillService
	local previewActiveSkillService = world:GetService("PreviewActiveSkill")
	---@type PreviewPickUpComponent
	local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
	local dir= previewPickUpComponent:GetLastPickUpDirection()
	previewContext:SetHitBackDirType(dir)
end