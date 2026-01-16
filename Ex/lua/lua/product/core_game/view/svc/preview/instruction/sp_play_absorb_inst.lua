require("sp_base_inst")
_class("SkillPreviewPlayAbsorbInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayAbsorbInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayAbsorbInstruction = SkillPreviewPlayAbsorbInstruction

function SkillPreviewPlayAbsorbInstruction:Constructor(params)
	self._waitTime = params["WaitTimeMs"] or 500
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayAbsorbInstruction:DoInstruction(TT,casterEntity,previewContext)
	-----@type MainWorld
	--self._world                     = previewContext:GetWorld()
	-----@type PreviewActiveSkillService
	--local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
	--local targetIDList              = previewContext:GetTargetEntityIDList()
	-----@type SkillPreviewEffectCalcService
	--local previewEffectCalcService  = self._world:GetService("PreviewCalcEffect")
	-----@type Vector2[]
	--local scopeGridList             = previewContext:GetScopeResult()
	--local effectList                = previewContext:GetEffect(SkillEffectType.AbsorbPiece)
	--local effectParam               = previewEffectCalcService:CreateSkillEffectParam(SkillEffectType.AbsorbPiece, effectList)
	-----@type SkillAbsorbPieceEffectResult
	--local result                    = previewEffectCalcService:CalcAbsorbPiece(casterEntity:GetID(), effectParam, scopeGridList)
	--local posList                   = result:GetAbsorbPieceList()
	--previewActiveSkillService:DoConvert(posList, "Add", "Dark")
	--YIELD(TT, tonumber(self._waitTime))
	--local needBreak = previewContext:IsNeedBreak()
	--if needBreak then
	--	return
	--end
	--previewActiveSkillService:DoConvert(posList, "Reflash", "Dark")
end