require "play_skill_phase_base_r"
---@class PlaySkillAttackEffectAnimationPhase: PlaySkillPhaseBase
_class("PlaySkillAttackEffectAnimationPhase", PlaySkillPhaseBase)
PlaySkillAttackEffectAnimationPhase = PlaySkillAttackEffectAnimationPhase

--攻击单个目标的表现
function PlaySkillAttackEffectAnimationPhase:PlayFlight(TT, casterEntity, phaseParam)
    --Log.fatal("_PlayAttackAnimationPhase")
    ---@type SkillPhaseAttackAnimationParam
    local attackAnimParam = phaseParam
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local isFinalAttack = skillEffectResultContainer:IsFinalAttack()

    ---@type SkillDamageEffectResult

    --启动攻击者的动画
    local attackAnimName = attackAnimParam:GetAnimationName()
    if attackAnimName then
        casterEntity:SetAnimatorControllerTriggers({attackAnimName})
        casterEntity:SetAnimatorControllerBools({Move = false})
    end

    --启动攻击特效播放
    local attackEffectID = attackAnimParam:GetCastEffectID()
    if attackEffectID then
        local effectSvc = self._world:GetService("Effect")
        if "target" ~= effectSvc:GetEffectHolder(attackEffectID) then
            local e = casterEntity
            effectSvc:CreateEffect(attackEffectID, e)
        end
    end
    local skillID = skillEffectResultContainer:GetSkillID()
    --提取伤害值
    local taskidArray = {}
    local index = 1
    while true do
        local damageResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Damage, index)
        if not damageResult then
            break
        end
        local castDamage = damageResult:GetDamageInfo(1)
        local beAttackEntityID = damageResult:GetTargetID()
        local targetEntity = self._world:GetEntityByID(beAttackEntityID)

        local curDeadTaskID =
            GameGlobal.TaskManager():CoreGameStartTask(
            self.PlayOneAttack,
            self,
            casterEntity,
            targetEntity,
            attackAnimParam,
            castDamage,
            isFinalAttack,
            damageResult:GetGridPos(),
            skillID
        )
        table.insert(taskidArray, curDeadTaskID)
        index = index + 1
    end
    JOIN_TASK_ARRAY(TT, taskidArray)
end

function PlaySkillAttackEffectAnimationPhase:PlayOneAttack(
    TT,
    casterEntity,
    targetEntity,
    attackAnimParam,
    damage,
    isFinalAttack,
    damageTextPos,
    skillID)
    ---@type RenderEntityService
    local resvc = self._world:GetService("RenderEntity")
    --转向目标
    resvc:TurnToTarget(casterEntity, targetEntity)

    --等待爆点时刻
    local hitPointDelay = attackAnimParam:GetHitPointDelay()

    if hitPointDelay > 0 then
        YIELD(TT, hitPointDelay)
    end

    ---目标还在
    if targetEntity ~= nil then
        --提取被击者受击动画
        local hitAnimName = attackAnimParam:GetHitAnimation()
        --提取被击者受击特效
        local hitEffectID = attackAnimParam:GetHitEffectID()

        --伤害飘字的位置
        --local damageTextPos = Vector2(0, 0)
        -----@type GridLocationComponent
        --local gridCmpt = targetEntity:GridLocation()
        --if gridCmpt ~= nil then
        --    damageTextPos = targetEntity:GridLocation().Position
        --end

        ---调用统一处理被击的逻辑
        local beHitParam = HandleBeHitParam:New()
            :SetHandleBeHitParam_CasterEntity(casterEntity)
            :SetHandleBeHitParam_TargetEntity(targetEntity)
            :SetHandleBeHitParam_HitAnimName(hitAnimName)
            :SetHandleBeHitParam_HitEffectID(hitEffectID)
            :SetHandleBeHitParam_DamageInfo(damage)
            :SetHandleBeHitParam_DamagePos(damageTextPos)
            :SetHandleBeHitParam_HitTurnTarget(attackAnimParam:HitTurnToTarget())
            :SetHandleBeHitParam_DeathClear(false)
            :SetHandleBeHitParam_IsFinalHit(isFinalAttack)
            :SetHandleBeHitParam_SkillID(skillID)

        self:SkillService():HandleBeHit(TT, beHitParam)
    end

    --等待攻击者整体动画结束
    local castTotalTime = attackAnimParam:GetCastTotalTime()
    local remainTime = castTotalTime - hitPointDelay
    YIELD(TT, remainTime)
    if isFinalAttack == true then
        YIELD(TT, BattleConst.FreezeDuration)
    end
end
