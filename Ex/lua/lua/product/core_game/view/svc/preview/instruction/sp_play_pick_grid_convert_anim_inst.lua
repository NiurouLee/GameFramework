require("sp_base_inst")
_class("SkillPreviewPlayPickGridConvertAnimInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayPickGridConvertAnimInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayPickGridConvertAnimInstruction = SkillPreviewPlayPickGridConvertAnimInstruction

function SkillPreviewPlayPickGridConvertAnimInstruction:Constructor(params)
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayPickGridConvertAnimInstruction:DoInstruction(TT,casterEntity,previewContext)
	---@type PreviewPickUpComponent
	local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
	---@type MainWorld
	self._world = previewContext:GetWorld()
	---@type PreviewActiveSkillService
	local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
	---@type Vector2[]
	local scopeGridList = previewPickUpComponent:GetAllValidPickUpGridPos()
	---@type SkillPreviewEffectCalcService
	local previewEffectCalcService =  self._world:GetService("PreviewCalcEffect")
	local effectList = previewContext:GetEffect(SkillEffectType.ConvertGridElement)
	local effectParam =previewEffectCalcService:CreateSkillEffectParam(SkillEffectType.ConvertGridElement,effectList)
	local result = previewEffectCalcService:CalcConvertGridElement(casterEntity,scopeGridList,effectParam)
	previewActiveSkillService:DoConvertElement(TT,result:GetTargetGridArray(),result:GetTargetElementType(),casterEntity, result:GetBlockGridArray())
end