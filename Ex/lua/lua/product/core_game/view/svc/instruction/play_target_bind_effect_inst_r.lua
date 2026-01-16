require("base_ins_r")
---@class PlayTargetBindEffectInstruction: BaseInstruction
_class("PlayTargetBindEffectInstruction", BaseInstruction)
PlayTargetBindEffectInstruction = PlayTargetBindEffectInstruction

function PlayTargetBindEffectInstruction:Constructor(paramList)
	self._effectID = tonumber(paramList["effectID"])
	self._scale = tonumber(paramList["scale"]) or 1
end

---@param casterEntity Entity
------@param phaseContext SkillPhaseContext
function PlayTargetBindEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
	---@type MainWorld
	local world = casterEntity:GetOwnerWorld()
	local targetID = phaseContext:GetCurTargetEntityID()
	local targetEntity = world:GetEntityByID(targetID)
	if not targetEntity then
		Log.fatal("")
		return
	end
	local e = targetEntity
	local effect = world:GetService("Effect"):CreateEffect(self._effectID, e)

	if effect and self._scale ~= 1 then
		YIELD(TT)
		---@type UnityEngine.Transform
		local trajectoryObject = effect:View():GetGameObject()
		local transWork = trajectoryObject.transform
		local scaleData = Vector3.New(self._scale, self._scale, self._scale)
		---@type DG.Tweening.Sequence
		local sequence = transWork:DOScale(scaleData, 0)
	end
end

function PlayTargetBindEffectInstruction:GetCacheResource()
	local t = {}
	if self._effectID and self._effectID > 0 then
		table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
	end
	return t
end
