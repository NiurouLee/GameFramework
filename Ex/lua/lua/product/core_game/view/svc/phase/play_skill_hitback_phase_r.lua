require "play_skill_phase_base_r"

---@class PlaySkillHitBackPhase:PlaySkillPhaseBase
_class("PlaySkillHitBackPhase", PlaySkillPhaseBase)
PlaySkillHitBackPhase = PlaySkillHitBackPhase

---@param phaseParam SkillPhaseHitBackParam
function PlaySkillHitBackPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local result = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.HitBack)
    if not result then
        return
    end
    local beHitbackEntityID = result:GetTargetID()
    local targetEntity = self._world:GetEntityByID(beHitbackEntityID)

    local hitEffectID = phaseParam:GetHitEffectID()
    if hitEffectID > 0 then
        self._world:GetService("Effect"):CreateBeHitEffect(hitEffectID, targetEntity)
    end

    local hitTurnTarget = phaseParam:GetTurnToTarget()
    if hitTurnTarget == TurnToTargetType.Caster then
        ---@type RenderEntityService
        local resvc = self._world:GetService("RenderEntity")
        resvc:TurnToTarget(targetEntity, casterEntity, nil, nil, hitTurnTarget)
    end

    ---处理受击及击退效果
    local processHitTaskID = nil
    if result and not targetEntity:HasHitback() and not result:GetHadPlay() then
        result:SetHadPlay(true)
        processHitTaskID = self:SkillService():ProcessHit(casterEntity, targetEntity, result)
    end

    ---等待击退/撞墙等处理
    if processHitTaskID then
        while not TaskHelper:GetInstance():IsTaskFinished(processHitTaskID) do
            YIELD(TT)
        end
    end
end
