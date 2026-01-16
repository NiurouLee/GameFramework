require "play_skill_phase_base_r"
--@class PlaySkillAOEDamagePhase: PlaySkillPhaseBase
_class("PlaySkillAOEDamagePhase", PlaySkillPhaseBase)
PlaySkillAOEDamagePhase = PlaySkillAOEDamagePhase

function PlaySkillAOEDamagePhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseAOEDamageParam
    local aoeDamageParam = phaseParam

    local castEffectID = aoeDamageParam:GetSkillCastEffectID()
    local intervalTime = aoeDamageParam:GetSkillAOEInterval()
    local hitPointDelay = aoeDamageParam:GetSkillHitPointDelay()
    local hitEffectID = aoeDamageParam:GetSkillHitEffectID()
    local hitAnimName = aoeDamageParam:GetSkillHitAnimName()

    local hitTurn2Target = true

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local isFinalAttack = skillEffectResultContainer:IsFinalAttack()

    ---当前施法索引
    local castIndex = 1
    local damageArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)

    if damageArray == nil then
        return
    end

    ---@type RenderEntityService
    local resvc = self._world:GetService("RenderEntity")

    ---攻击目标的总数
    local castCount = #damageArray
    for k, v in pairs(damageArray) do
        ---@type SkillDamageEffectResult
        local damageResult = v
        local damageTargetID = damageResult:GetTargetID()
        local damageTargetEntity = self._world:GetEntityByID(damageTargetID)
        ---单体伤害只有一个
        local damage = damageResult:GetDamageInfo(1)
        local damagePos = damageResult:GetGridPos()

        ---施法者转向被攻击的目标
        resvc:TurnToTarget(casterEntity, damageTargetEntity)

        ---在目标位置播放的特效
        --self._effectService:CreateEffect(castEffectID, damageTargetEntity)

        ---等待爆点
        YIELD(TT, hitPointDelay)

        local curHitIsFinalAttack = false
        if isFinalAttack == true and castIndex == castCount then
            curHitIsFinalAttack = true
        end

        ---调用统一处理被击的逻辑
        local beHitParam = HandleBeHitParam:New()
            :SetHandleBeHitParam_CasterEntity(casterEntity)
            :SetHandleBeHitParam_TargetEntity(damageTargetEntity)
            :SetHandleBeHitParam_HitAnimName(hitAnimName)
            :SetHandleBeHitParam_HitEffectID(hitEffectID)
            :SetHandleBeHitParam_DamageInfo(damage)
            :SetHandleBeHitParam_DamagePos(damagePos)
            :SetHandleBeHitParam_HitTurnTarget(hitTurn2Target)
            :SetHandleBeHitParam_DeathClear(false)
            :SetHandleBeHitParam_IsFinalHit(curHitIsFinalAttack)
            :SetHandleBeHitParam_SkillID(skillID)
    
        self:SkillService():HandleBeHit(TT, beHitParam)

        YIELD(TT, intervalTime)
    end
end
