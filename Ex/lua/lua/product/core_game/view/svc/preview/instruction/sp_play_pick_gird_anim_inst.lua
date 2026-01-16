require("sp_base_inst")
_class("SkillPreviewPlayPickAnimInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayPickAnimInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayPickAnimInstruction = SkillPreviewPlayPickAnimInstruction

function SkillPreviewPlayPickAnimInstruction:Constructor(params)
	self._anim = params.Anim
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayPickAnimInstruction:DoInstruction(TT,casterEntity,previewContext)
	---@type MainWorld
	self._world = previewContext:GetWorld()
	---@type PreviewActiveSkillService
	local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
	local allPickUpPos = previewContext:GetPickUpPos()
	previewActiveSkillService:DoConvert({ allPickUpPos }, self._anim)
end