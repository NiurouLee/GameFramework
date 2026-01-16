require "play_skill_phase_base_r"
---@class PlaySkillChargePhase: PlaySkillPhaseBase
_class("PlaySkillChargePhase", PlaySkillPhaseBase)
PlaySkillChargePhase = PlaySkillChargePhase

---@param casterEntity Entity
---@param phaseParam SkillPhaseChargeParam
---蓄力表现
function PlaySkillChargePhase:PlayFlight(TT, casterEntity, phaseParam)
    --播放蓄力动画
    local chargeAnim = phaseParam:GetAnim()
    casterEntity:SetAnimatorControllerTriggers({chargeAnim})
    --延时
    local delay = phaseParam:GetDelay()
    if delay > 0 then
        YIELD(TT, delay)
    end
    --蓄力特效
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    local effIds = phaseParam:GetEffIds()
    if effIds then
        for i, v in ipairs(effIds) do
            effectService:CreateEffect(v, casterEntity)
        end
    end
end
