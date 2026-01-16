require "play_skill_phase_base_r"

---@class PlaySkillAttackAnimationPhase: PlaySkillPhaseBase
_class("PlaySkillAttackAnimationPhase", PlaySkillPhaseBase)
PlaySkillAttackAnimationPhase = PlaySkillAttackAnimationPhase

--普攻表现
--星灵和怪物通用，攻击多目标，斜向普攻，攻击一个目标多爆点。
--只有星灵会有普攻爆点等待（为了解决连线普攻，表现比逻辑快）
function PlaySkillAttackAnimationPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseAttackAnimationParam
    local attackAnimParam = phaseParam
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local isFinalAttack = skillEffectResultContainer:IsFinalAttack()

    ---@type SkillDamageEffectResult[]
    local damageResultAll = skillEffectResultContainer:GetEffectResultByArrayAll(SkillEffectType.Damage)

    if not damageResultAll then
        return
    end

    --普攻造成多个伤害
    local targetEntityList = {}
    local castDamageList = {}
    local damagePosList = {}

    self._normalAttackDoubleIndex = 0

    for i = 1, #damageResultAll do
        local damageResult = damageResultAll[i]
        --提取伤害值
        local castDamage = damageResult:GetDamageInfo(attackAnimParam:GetDamageIndex())
        local damagePos = damageResult:GetGridPos()
        local beAttackEntityID = damageResult:GetTargetID()
        local targetEntity = self._world:GetEntityByID(beAttackEntityID)
        if targetEntity then
            table.insert(targetEntityList, targetEntity)
            table.insert(castDamageList, castDamage)
            table.insert(damagePosList, damagePos)

            if damageResult:GetNormalAttackDouble() == true then
                self._normalAttackDoubleIndex = i
            end
        end
    end

    self:_PlayAttack(
        TT,
        casterEntity,
        targetEntityList,
        attackAnimParam,
        castDamageList,
        isFinalAttack,
        skillID,
        damagePosList,
        skillEffectResultContainer
    )
end

---@param attackAnimParam SkillPhaseAttackAnimationParam
---@param skillEffectResultContainer SkillEffectResultContainer
function PlaySkillAttackAnimationPhase:_PlayAttack(
    TT,
    casterEntity,
    targetEntityList,
    attackAnimParam,
    damageList,
    isFinalAttack,
    skillID,
    damagePosList,
    skillEffectResultContainer)
    --取出目标列表的第一个 用做攻击朝向
    local targetEntity = targetEntityList[1]

    --攻击朝向,怪物空放没有攻击目标
    if targetEntity then
        local skillService = self:SkillService()
        --施法者朝向被击者，指定第一个伤害坐标，否则会朝向目标的中点
        ---@type BoardServiceRender
        local boardServiceRender = self._world:GetService("BoardRender")
        local gridRenderPos = boardServiceRender:GridPos2RenderPos(damagePosList[1])
        ---@type RenderEntityService
        local resvc = self._world:GetService("RenderEntity")
        resvc:TurnToTarget(casterEntity, targetEntity, nil, gridRenderPos)
    end

    --攻击动画
    --如果配置了斜向普攻的表现 and 本次攻击是斜向的(怪物也可能配置斜向普攻)
    local isSlantAttack
    local attackPos = casterEntity:GetRenderGridPosition()
    if
        damagePosList[1] and attackPos.x ~= damagePosList[1].x and attackPos.y ~= damagePosList[1].y and
            attackAnimParam:GetSlantCastEffectID()
     then
        isSlantAttack = true
    end
    --用来标记是不是一个星灵在一个格子上的最后一次普通攻击(长短普攻的动画不同，默认true长普攻)
    local isLastNormalAttack = skillEffectResultContainer:IsLastNormalAttackAtOnGrid()
    local attackAnimName = attackAnimParam:GetAnimationName(isLastNormalAttack, isSlantAttack)
    if attackAnimName then
        if attackAnimParam:IsUsePermanentEffectPlayAnim() then
            local rootName = attackAnimParam:GetPermanentEffSpecialAnimRoot()
            self:_PermanentEffectPlayAnim(casterEntity,attackAnimName,rootName)
        else
            casterEntity:SetAnimatorControllerTriggers({attackAnimName})
        end
    end

    --攻击特效
    local attackEffectID = attackAnimParam:GetCastEffectID(isSlantAttack)
    if attackEffectID and attackEffectID > 0 then
        local atkEffectDelay = attackAnimParam:GetHitEffectDelay(isLastNormalAttack, isSlantAttack)
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
    local hitPointDelay = attackAnimParam:GetHitPointDelay(isLastNormalAttack, isSlantAttack) or 0
    --第二爆点，星灵和怪都可能有
    local hitPointDelaySecond = attackAnimParam:GetHitPointDelaySecond(isLastNormalAttack) or 0
    if hitPointDelay > 0 then
        YIELD(TT, hitPointDelay)
    end

    --增加普攻combo的技能结果，星灵有 怪物没有,
    local resultAddComboNum = {}
    if casterEntity:HasPetPstID() then
        resultAddComboNum = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.AddComboNum) or {}
    end
    local oriBeAttackPos = skillEffectResultContainer:GetNormalAttackBeAttackOriPos()

    for i = 1, #targetEntityList do
        local targetEntity = targetEntityList[i]
        local damagePos = damagePosList[i]
        local damage = damageList[i]
        --本次普攻是否增加combo(怪物的在后面不会计算)
        local isAddCombo = false
        if i == 1 or table.count(resultAddComboNum) > 0 or self._normalAttackDoubleIndex == i then
            isAddCombo = true
        end

        --这个技能造成了最后一击，但是如果存在多个伤害并且有表现延迟，静帧应该是最后一下伤害播放(怪物的在后面不会计算)
        local curIsFinalAttack = isFinalAttack and i == #targetEntityList

        -- 伤害飘字等待上一个飘字完成 可能会比原来要慢
        local taskid =
            GameGlobal.TaskManager():CoreGameStartTask(
            function(TT)
                --如果配置了第二爆点并且有多个伤害，默认从第二个伤害开始使用第二爆点播放
				--如果配置了第二爆点并且有多个伤害，并且i=3，说明是普攻双击，有4个伤害，第3个伤害是第2次普攻第1爆点的
                if i ~= 1 and i ~= 3 and hitPointDelaySecond ~= 0 then
                    YIELD(TT, hitPointDelaySecond - hitPointDelay)
                end

                self:_WaitPlayHandleBeHit(
                    TT,
                    casterEntity,
                    targetEntity,
                    attackAnimParam,
                    isSlantAttack,
                    damage,
                    damagePos,
                    curIsFinalAttack,
                    skillID,
                    isAddCombo,
                    oriBeAttackPos
                )
            end
        )
    end

    --等待攻击者整体动画结束
    local castTotalTime = attackAnimParam:GetCastTotalTime(isLastNormalAttack)
    local remainTime = castTotalTime - hitPointDelay

    YIELD(TT, remainTime)

    if isFinalAttack == true then
        YIELD(TT, BattleConst.FreezeDuration)
    end
end

---只有星灵会有普攻爆点等待（为了解决连线普攻，表现比逻辑快）
function PlaySkillAttackAnimationPhase:_WaitPlayHandleBeHit(
    TT,
    casterEntity,
    targetEntity,
    attackAnimParam,
    isSlantAttack,
    damage,
    damagePos,
    isFinalAttack,
    skillID,
    isAddCombo,
    oriBeAttackPos)
    --只有星灵会有普攻爆点等待（为了解决连线普攻，表现比逻辑快）
    if casterEntity:HasPetPstID() then
        ---@type Entity
        local renderBoardEntity = self._world:GetRenderBoardEntity()
        ---@type L2R_NormalAttackResult
        local normalAtkResultCmpt = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.NormalAttack)
        local attackPos = casterEntity:GetRenderGridPosition()
        --连线普攻中，当前技能的爆点时间不能超过前一个技能的爆点
        local curNormalSkill =
            normalAtkResultCmpt:GetNormalSkillSequenceWithAttackGridData(skillID, damagePos, attackPos)
        --只有从队长身上找到普攻  才会等待
        if curNormalSkill then
            ---@type TimeService
            local timeService = self._world:GetService("Time")
            --上一个技能的爆点时间
            local preNormalSkill = normalAtkResultCmpt:GetNormalSkillSequenceWithOrder(curNormalSkill.order - 1)
            local beforeWaitTime = timeService:GetCurrentTimeMs()
            local preDamageValue = 0
            local preDamageResult
            if preNormalSkill then
                ---@type SkillDamageEffectResult[]
                preDamageResult = preNormalSkill.attackGridData:GetEffectResultByArrayAll(SkillEffectType.Damage)
                if preDamageResult then
                    local preDamageResultLast = preDamageResult[#preDamageResult]
                    local preDamageInfo = preDamageResultLast:GetDamageInfo(attackAnimParam:GetDamageIndex())
                    preDamageValue = preDamageInfo:GetDamageValue()
                else
                    --上一个普攻是加血
                    ---@type SkillEffectResult_AddBlood[]
                    preDamageResult = preNormalSkill.attackGridData:GetEffectResultByArrayAll(SkillEffectType.AddBlood)
                    if preDamageResult then
                        local preDamageResultLast = preDamageResult[#preDamageResult]
                        local preDamageInfo = preDamageResultLast:GetDamageInfo(attackAnimParam:GetDamageIndex())
                        preDamageValue = preDamageInfo:GetDamageValue()
                    end
                end
            end

            while curNormalSkill.order > 1 and preNormalSkill.playStartTime == 0 and preDamageValue == 0 and
                preDamageResult do
                YIELD(TT)
                preNormalSkill = normalAtkResultCmpt:GetNormalSkillSequenceWithOrder(curNormalSkill.order - 1)
            end

            local afterWaitTime = timeService:GetCurrentTimeMs()
            normalAtkResultCmpt:SetCurPlayNormalSkillPlayStartTime(curNormalSkill.order, afterWaitTime)
        end
        if isAddCombo then
            --一次普攻可能造成多个伤害，但是输入一个combo
            ---@type RenderBattleService
            local renderBattleSvc = self._world:GetService("RenderBattle")
            local curComboNum = renderBattleSvc:GetComboNum()
            curComboNum = curComboNum + 1
            renderBattleSvc:SetComboNum(curComboNum)

            --通知一次 计算普通结束
            local nt = NTNormalAttackCalcEnd:New(casterEntity, targetEntity, attackPos, damagePos)
            nt:SetSkillID(skillID)
            nt:SetSkillType(SkillType.Normal)
            self._world:GetService("PlayBuff"):PlayBuffView(TT, nt)
            if oriBeAttackPos then
                local nt1 = NTNormalAttackCalcEndUseOriPos:New(casterEntity, targetEntity, attackPos, oriBeAttackPos)
                nt1:SetSkillID(skillID)
                nt1:SetSkillType(SkillType.Normal)
                self._world:GetService("PlayBuff"):PlayBuffView(TT, nt1)
            end
        end
    else
        --怪物不静帧
        isFinalAttack = false
    end

    --提取被击者受击动画
    local hitAnimName = attackAnimParam:GetHitAnimation()
    --提取被击者受击特效
    local hitEffectID = attackAnimParam:GetHitEffectID(isSlantAttack)
    local hitTurn2Target = attackAnimParam:HitTurnToTarget()

    ---调用统一处理被击的逻辑
    local beHitParam = HandleBeHitParam:New()
        :SetHandleBeHitParam_CasterEntity(casterEntity)
        :SetHandleBeHitParam_TargetEntity(targetEntity)
        :SetHandleBeHitParam_HitAnimName(hitAnimName)
        :SetHandleBeHitParam_HitEffectID(hitEffectID)
        :SetHandleBeHitParam_DamageInfo(damage)
        :SetHandleBeHitParam_DamagePos(damagePos)
        :SetHandleBeHitParam_HitTurnTarget(hitTurn2Target)
        :SetHandleBeHitParam_DeathClear(false)
        :SetHandleBeHitParam_IsFinalHit(isFinalAttack)
        :SetHandleBeHitParam_SkillID(skillID)
    
    self:SkillService():HandleBeHit(TT, beHitParam)
end
function PlaySkillAttackAnimationPhase:_PermanentEffectPlayAnim(casterEntity,animName,rootName)
    ---@type EffectHolderComponent
    local effectHolderCmpt = casterEntity:EffectHolder()
    if effectHolderCmpt then
        ---@type RenderBattleService
        local renderBattle = self._world:GetService("RenderBattle")
        local permanentEffectList = effectHolderCmpt:GetPermanentEffect()
        for index, effectID in ipairs(permanentEffectList) do
            local effectEntity = self._world:GetEntityByID(effectID)
            if effectEntity then
                if rootName then
                    effectEntity:SetSpecialAnimRoot(rootName)
                end
                effectEntity:SetAnimatorControllerTriggers({animName})
                --renderBattle:PlayAnimation(effectEntity, { animName })
            end
        end
    end
end