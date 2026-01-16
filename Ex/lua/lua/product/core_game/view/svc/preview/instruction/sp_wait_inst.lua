
require("sp_base_inst")
---用来在预览中实现wait
_class("SkillPreviewWaitInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewWaitInstruction: SkillPreviewBaseInstruction
SkillPreviewWaitInstruction = SkillPreviewWaitInstruction

function SkillPreviewWaitInstruction:Constructor(params)
	self._timeLen = params["TimeMs"]
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewWaitInstruction:DoInstruction(TT,casterEntity,previewContext)
	if self._timeLen then
		YIELD(TT, tonumber(self._timeLen))
	else
		YIELD(TT)
	end
	local needBreak = previewContext:IsNeedBreak()
	return needBreak
end

