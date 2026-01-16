require "play_skill_phase_base_r"

---@class PlaySkillNormalAttackOnlyAnimationPhase: PlaySkillPhaseBase
_class("PlaySkillNormalAttackOnlyAnimationPhase", PlaySkillPhaseBase)
PlaySkillNormalAttackOnlyAnimationPhase = PlaySkillNormalAttackOnlyAnimationPhase

--普攻加血表现
function PlaySkillNormalAttackOnlyAnimationPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseNormalAttackOnlyAnimationParam
    local attackAnimParam = phaseParam
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()

    ---@type SkillEffectResultTransferTarget[]
    local targetResultAll = skillEffectResultContainer:GetEffectResultByArrayAll(SkillEffectType.TransferTarget)

    ---@type SkillEffectResultTransferTarget
    local targetResult = targetResultAll[1]
    local damagePos = targetResult:GetTargetGridPos()
    local beAttackEntityID = targetResult:GetTargetEntityID()
    local targetEntity = self._world:GetEntityByID(beAttackEntityID)

    --攻击朝向,怪物空放没有攻击目标
    if targetEntity then
        --施法者朝向被击者，指定第一个伤害坐标，否则会朝向目标的中点
        ---@type BoardServiceRender
        local boardServiceRender = self._world:GetService("BoardRender")
        local gridRenderPos = boardServiceRender:GridPos2RenderPos(damagePos)
        ---@type RenderEntityService
        local resvc = self._world:GetService("RenderEntity")
        resvc:TurnToTarget(casterEntity, targetEntity, nil, gridRenderPos)
    end

    --用来标记是不是一个星灵在一个格子上的最后一次普通攻击(长短普攻的动画不同，默认true长普攻)
    local isLastNormalAttack = skillEffectResultContainer:IsLastNormalAttackAtOnGrid()
    local attackAnimName = attackAnimParam:GetAnimationName(isLastNormalAttack)
    if attackAnimName then
        casterEntity:SetAnimatorControllerTriggers({attackAnimName})
    end

    --攻击特效
    local attackEffectID = attackAnimParam:GetCastEffectID()
    if attackEffectID and attackEffectID > 0 then
        local atkEffectDelay = attackAnimParam:GetHitEffectDelay(isLastNormalAttack)
        GameGlobal.TaskManager():CoreGameStartTask(
            function()
                if atkEffectDelay ~= 0 then
                    YIELD(TT, atkEffectDelay)
                end
                ---@type EffectService
                local effectSvc = self._world:GetService("Effect")
                local e = casterEntity
                if "target" == effectSvc:GetEffectHolder(attackEffectID) then
                    e = targetEntity
                end

                if e then
                    effectSvc:CreateEffect(attackEffectID, e)
                end
            end
        )
    end

    --等待爆点时刻
    local hitPointDelay = attackAnimParam:GetHitPointDelay(isLastNormalAttack) or 0
    if hitPointDelay > 0 then
        YIELD(TT, hitPointDelay)
    end

    ----------------------双击普攻，第二下是攻击的----------------------

    local isFinalAttack = skillEffectResultContainer:IsFinalAttack()
    ---@type SkillDamageEffectResult[]
    local damageResultAll = skillEffectResultContainer:GetEffectResultByArrayAll(SkillEffectType.Damage)

    if damageResultAll and table.count(damageResultAll) > 0 then
        ---@type SkillDamageEffectResult
        local normalDoubleDamageResult = damageResultAll[#damageResultAll]
        ---@type DamageInfo
        local normalDoubleDamageInfo = normalDoubleDamageResult:GetDamageInfo(1)
        if normalDoubleDamageInfo then
            --一次普攻可能造成多个伤害，但是输入一个combo
            ---@type RenderBattleService
            local renderBattleSvc = self._world:GetService("RenderBattle")
            local curComboNum = renderBattleSvc:GetComboNum()
            curComboNum = curComboNum + 1
            renderBattleSvc:SetComboNum(curComboNum)

            --被击者受击动画
            local normalDoubleHitAnimName = attackAnimParam:GetNormalDoubleHitAnimation()
            local normalDoubleHitEffect = attackAnimParam:GetNormalDoubleHitEffectID()
            --被击者 被击坐标 都采用原有普攻的数据

            ---调用统一处理被击的逻辑
            local beHitParam =
                HandleBeHitParam:New():SetHandleBeHitParam_CasterEntity(casterEntity):SetHandleBeHitParam_TargetEntity(
                targetEntity
            ):SetHandleBeHitParam_HitAnimName(normalDoubleHitAnimName):SetHandleBeHitParam_HitEffectID(
                normalDoubleHitEffect
            ):SetHandleBeHitParam_DamageInfo(normalDoubleDamageInfo):SetHandleBeHitParam_DamagePos(damagePos):SetHandleBeHitParam_HitTurnTarget(
                true
            ):SetHandleBeHitParam_DeathClear(false):SetHandleBeHitParam_IsFinalHit(isFinalAttack):SetHandleBeHitParam_SkillID(
                skillID
            )

            self:SkillService():HandleBeHit(TT, beHitParam)
        end
    end
    ----------------------双击普攻，第二下是攻击的----------------------

    --设置普攻表现顺序
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type L2R_NormalAttackResult
    local normalAtkResultCmpt = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.NormalAttack)
    local attackPos = casterEntity:GetRenderGridPosition()
    --连线普攻中，当前技能的爆点时间不能超过前一个技能的爆点
    local curNormalSkill = normalAtkResultCmpt:GetNormalSkillSequenceWithAttackGridData(skillID, damagePos, attackPos)
    --只有从队长身上找到普攻  才会等待
    if curNormalSkill then
        ---@type TimeService
        local timeService = self._world:GetService("Time")
        local afterWaitTime = timeService:GetCurrentTimeMs()
        normalAtkResultCmpt:SetCurPlayNormalSkillPlayStartTime(curNormalSkill.order, afterWaitTime)
    end

    --buff通知
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:_OnAttackStart(TT, skillID, casterEntity, targetEntity, attackPos, damagePos, nil)
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    --通知一次 计算普通结束
    local nt = NTNormalAttackCalcEnd:New(casterEntity, targetEntity, attackPos, damagePos)
    nt:SetSkillID(skillID)
    nt:SetSkillType(SkillType.Normal)
    self._world:GetService("PlayBuff"):PlayBuffView(TT, nt)

    local oriBeAttackPos = skillEffectResultContainer:GetNormalAttackBeAttackOriPos()
    if oriBeAttackPos then
        local nt1 = NTNormalAttackCalcEndUseOriPos:New(casterEntity, targetEntity, attackPos, oriBeAttackPos)
        nt1:SetSkillID(skillID)
        nt1:SetSkillType(SkillType.Normal)
        self._world:GetService("PlayBuff"):PlayBuffView(TT, nt1)
    end
    --buff通知
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:_OnAttackEnd(TT, skillID, casterEntity, targetEntity, attackPos, damagePos, nil)

    --等待攻击者整体动画结束
    local castTotalTime = attackAnimParam:GetCastTotalTime(isLastNormalAttack)
    local remainTime = castTotalTime - hitPointDelay

    YIELD(TT, remainTime)
end
