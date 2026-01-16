---全部格子执行Anim
require("sp_base_inst")
_class("SkillPreviewPlayAllPieceAnimInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayAllPieceAnimInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayAllPieceAnimInstruction = SkillPreviewPlayAllPieceAnimInstruction

function SkillPreviewPlayAllPieceAnimInstruction:Constructor(params)
	self._anim = params["Anim"]
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayAllPieceAnimInstruction:DoInstruction(TT,casterEntity,previewContext)
	---@type MainWorld
	local world = previewContext:GetWorld()
	---@type PreviewActiveSkillService
	local previewActiveSkillService = world:GetService("PreviewActiveSkill")
	---@type Vector2[]
	local scopeGridList = {}
	previewActiveSkillService:DoConvert(scopeGridList,"Gray",self._anim)
end