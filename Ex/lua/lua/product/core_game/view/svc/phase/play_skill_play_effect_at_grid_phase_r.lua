require "play_skill_phase_base_r"
---@class PlaySkillPhasePlayEffectAtGridPhase: PlaySkillPhaseBase
_class("PlaySkillPhasePlayEffectAtGridPhase", PlaySkillPhaseBase)
PlaySkillPhasePlayEffectAtGridPhase = PlaySkillPhasePlayEffectAtGridPhase

---@param casterEntity Entity
---@param phaseParam SkillPhasePlayEffectAtGridParam
function PlaySkillPhasePlayEffectAtGridPhase:PlayFlight(TT, casterEntity, phaseParam)
	local gridEffectList = phaseParam:GetGirdEffectList()
	for _,param in ipairs(gridEffectList) do
		local effectID = tonumber(param.effectID)
		local gridPos = Vector2(tonumber(param.gridPos.x),tonumber(param.gridPos.y))
		self._world:GetService("Effect"):CreateWorldPositionEffect(effectID, gridPos)
	end
end