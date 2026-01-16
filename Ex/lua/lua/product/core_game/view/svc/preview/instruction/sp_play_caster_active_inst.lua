
require("sp_base_inst")
_class("SkillPreviewPlayCasterActiveInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayCasterActiveInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayCasterActiveInstruction = SkillPreviewPlayCasterActiveInstruction

function SkillPreviewPlayCasterActiveInstruction:Constructor(params)
	self._enable = params["Enable"]
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayCasterActiveInstruction:DoInstruction(TT,casterEntity,previewContext)
	if  self._enable == "false" then
		casterEntity:View():GetGameObject():SetActive(false)
	end

	if  self._enable == "true" then
		casterEntity:View():GetGameObject():SetActive(true)
	end
end

