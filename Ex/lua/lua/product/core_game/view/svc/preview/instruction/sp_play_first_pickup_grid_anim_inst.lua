require("sp_base_inst")
_class("SkillPreviewPlayFirstPickGridAnimInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayFirstPickGridAnimInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayFirstPickGridAnimInstruction = SkillPreviewPlayFirstPickGridAnimInstruction

function SkillPreviewPlayFirstPickGridAnimInstruction:Constructor(params)
	self._anim = params.Anim
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayFirstPickGridAnimInstruction:DoInstruction(TT,casterEntity,previewContext)
	---@type PreviewPickUpComponent
	local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
	---@type MainWorld
	self._world = previewContext:GetWorld()
	---@type PreviewActiveSkillService
	local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
	---@type Vector2
	local pickUpGridPos = previewPickUpComponent:GetFirstValidPickUpGridPos()
	previewActiveSkillService:DoConvert({ pickUpGridPos }, self._anim)
end