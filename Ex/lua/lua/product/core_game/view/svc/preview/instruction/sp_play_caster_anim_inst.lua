
require("sp_base_inst")
_class("SkillPreviewPlayCasterAnimInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayCasterAnimInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayCasterAnimInstruction = SkillPreviewPlayCasterAnimInstruction

function SkillPreviewPlayCasterAnimInstruction:Constructor(params)
	self._anim = params["Anim"]
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayCasterAnimInstruction:DoInstruction(TT,casterEntity,previewContext)
	casterEntity:SetAnimatorControllerTriggers({self._anim})
end

