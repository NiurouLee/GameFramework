require "play_skill_phase_base_r"
_class("PlaySkillRoundGridPhase", PlaySkillPhaseBase)
PlaySkillRoundGridPhase = PlaySkillRoundGridPhase

--两极战队周围格子攻击
function PlaySkillRoundGridPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseRoundGridParam
    local RoundGridParam = phaseParam
    local gridEffectDelayTime = RoundGridParam:GetGridEffectDelayTime()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local scope = skillEffectResultContainer:GetScopeResult()
    local results = skillEffectResultContainer:GetEffectResultsAsPosDic(SkillEffectType.Damage)

    local gridRange = scope:GetAttackRange()

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    --启动攻击者的动画
    local attackAnimName = RoundGridParam:GetAnimationName()
    casterEntity:SetAnimatorControllerTriggers({attackAnimName})

    --启动攻击特效播放
    local attackEffectID = RoundGridParam:GetCastEffectID()
    self._world:GetService("Effect"):CreateEffect(attackEffectID, casterEntity)

    local casterPos = casterEntity:GridLocation().Position

    YIELD(TT, gridEffectDelayTime)

    local hitAnimName = RoundGridParam:GetHitAnimationName()
    local hitEffectID = RoundGridParam:GetHitEffectID()

    local isFinalAttack = skillEffectResultContainer:IsFinalAttack()
    if isFinalAttack then
        self:SkillService():FreezeFrame(true)
    end

    --格子特效
    for i, gridPos in ipairs(gridRange) do
        local gridEffectID = RoundGridParam:GetGridEffectID(casterPos, gridPos)
        if gridEffectID then
            self._world:GetService("Effect"):CreateWorldPositionEffect(gridEffectID, gridPos)
        end
        local res = results[Vector2.Pos2Index(gridPos)]
        if res then
            local targetEntityID = res:GetTargetID()
            if targetEntityID ~= -1 then
                local targetEntity = self._world:GetEntityByID(targetEntityID)
                local targetDamage = res:GetDamageInfo(1)

                ---调用统一处理被击的逻辑
                local beHitParam = HandleBeHitParam:New()
                    :SetHandleBeHitParam_CasterEntity(casterEntity)
                    :SetHandleBeHitParam_TargetEntity(targetEntity)
                    :SetHandleBeHitParam_HitAnimName(hitAnimName)
                    :SetHandleBeHitParam_HitEffectID(hitEffectID)
                    :SetHandleBeHitParam_DamageInfo(targetDamage)
                    :SetHandleBeHitParam_DamagePos(gridPos)
                    :SetHandleBeHitParam_HitTurnTarget(phaseParam:HitTurnToTarget())
                    :SetHandleBeHitParam_DeathClear(false)
                    :SetHandleBeHitParam_IsFinalHit(false)
                    :SetHandleBeHitParam_SkillID(skillID)

                playSkillService:HandleBeHit(TT, beHitParam)
            end
        end
    end

    --等待结束时间
    local finishDelayTime = RoundGridParam:GetFinishDelayTime()
    YIELD(TT, finishDelayTime)
end
