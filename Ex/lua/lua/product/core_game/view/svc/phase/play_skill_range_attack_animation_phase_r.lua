require "play_skill_phase_base_r"
_class("PlaySkillRangeAttackAnimationPhase", PlaySkillPhaseBase)
---@class PlaySkillRangeAttackAnimationPhase:PlaySkillPhaseBase
PlaySkillRangeAttackAnimationPhase = PlaySkillRangeAttackAnimationPhase

---@param casterEntity Entity
function PlaySkillRangeAttackAnimationPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseRangeAttackAnimationParam
    local param = phaseParam
    --施法者动作
    local castAnimationName = param:GetCastAnimation()
    --施法者特效
    local castEffectID = param:GetCastEffectID()
    local hitDelayTime = param:GetHitDelayTime()
    local animatedEntity = casterEntity
    if param:IsPlayOnSuperEntity() and casterEntity:HasSuperEntity() then
        animatedEntity = casterEntity:GetSuperEntity()
    end
    self:_PlayAnimationEffect(TT, animatedEntity, castAnimationName, castEffectID, hitDelayTime)

    GameGlobal.TaskManager():CoreGameStartTask(
        self._skillService.PlayCastAudio,
        self._skillService,
        param:GetAudioID(),
        param:GetAudioWaitTime()
    )

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local isFinalHit = skillEffectResultContainer:IsFinalAttack()
    ---伤害数组
    local results = skillEffectResultContainer:GetEffectResultByArrayAll(SkillEffectType.Damage)
    --韩玉信增加弹道
    local bHaveBit = self:_TrajectoryAction(TT, casterEntity, param, results, isFinalHit, skillID)

    ---2019-12-30 韩玉信修改：如果有弹道，会在弹道结束后启动被击特效，所以这个执行分支不用特意去播放被击特效了
    local taskIDs = {}
    if false == bHaveBit then
        if not results then
            return
        end
        local hitAnimationName = param:GetHitAnimation()
        local hitEffectID = param:GetHitEffectID()
        local hpDelayTime = param:GetHpDelay()
        local targetEffectID = param:GetTargetEffectID()
        --开始给目标每一个挂被击动作和特效
        for _, res in pairs(results) do
            local targetEntity = self._world:GetEntityByID(res:GetTargetID())
            if targetEntity then 
                local pos = targetEntity:GridLocation().Position
                local targetDamage = res:GetDamageInfo(1)
                local damagePos = res:GetGridPos()
                local nTaskID =
                    GameGlobal.TaskManager():CoreGameStartTask(
                    self._HandleBeHit,
                    self,
                    casterEntity,
                    targetEntity,
                    hitAnimationName,
                    hitEffectID,
                    targetDamage,
                    targetEffectID,
                    hpDelayTime,
                    isFinalHit,
                    param,
                    damagePos,
                    skillID
                )
                if nTaskID > 0 then
                    taskIDs[#taskIDs + 1] = nTaskID
                end
            end
        end
    end
    local nWaitStart = GameGlobal:GetInstance():GetCurrentTime()
    self:_WaitSonTask(taskIDs)
    local nWaitEnd = GameGlobal:GetInstance():GetCurrentTime()

    local finishDelayTime = math.max(0, param:GetFinishDelayTime() - (nWaitEnd - nWaitStart))
    YIELD(TT, finishDelayTime)
end

function PlaySkillRangeAttackAnimationPhase:_HandleBeHit(
    TT,
    casterEntity,
    targetEntity,
    hitAnimationName,
    hitEffectID,
    targetDamage,
    targetEffectID,
    hpDelayTime,
    isFinalHit,
    param,
    damagePos,
    skillID)
    if targetEffectID then
        self._world:GetService("Effect"):CreateEffect(targetEffectID, targetEntity)
    end
    YIELD(TT, hpDelayTime)
    ---@type PlaySkillService
    local playSkillService = self:SkillService()
    ---调用统一处理被击的逻辑
    local beHitParam = HandleBeHitParam:New()
        :SetHandleBeHitParam_CasterEntity(casterEntity)
        :SetHandleBeHitParam_TargetEntity(targetEntity)
        :SetHandleBeHitParam_HitAnimName(hitAnimationName)
        :SetHandleBeHitParam_HitEffectID(hitEffectID)
        :SetHandleBeHitParam_DamageInfo(targetDamage)
        :SetHandleBeHitParam_DamagePos(damagePos)
        :SetHandleBeHitParam_DeathClear(param:IsClearBodyNow())
        :SetHandleBeHitParam_IsFinalHit(isFinalHit)
        :SetHandleBeHitParam_SkillID(skillID)

    playSkillService:HandleBeHit(TT, beHitParam)
end

---@param phaseParam SkillPhaseRangeAttackAnimationParam
function PlaySkillRangeAttackAnimationPhase:_TrajectoryAction(
    TT,
    casterEntity,
    phaseParam,
    results,
    isFinalHit,
    nSkillID)
    local nTrajectoryType = phaseParam:GetTrajectoryType()
    if nil == nTrajectoryType then
        return false
    end
    if nil == results or table.count(results) <= 0 then
        return false
    end
    local nTrajectoryEffectID = phaseParam:GetTrajectoryEffectID()
    local nTrajectoryTime = phaseParam:GetTrajectoryTime()
    local castPos = casterEntity:GridLocation().Position
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---@type EffectService
    local effectService = self._world:GetService("Effect")

    ---创建抛射体
    local effectEntities = {}
    for _, res in pairs(results) do
        local targetEntity = self._world:GetEntityByID(res:GetTargetID())
        local posDamage = res:GetGridPos() --- targetEntity:GetDamageCenter()  --GridLocation().Position
        local posDirectory = posDamage - castPos
        local nEffectOffset = phaseParam:GetTrajectoryEffectOffset()
        local posCreate = castPos
        if nEffectOffset then
            local nDirectoryLen = math.max(math.abs(posDirectory.x), math.abs(posDirectory.y), 1)
            local effectDirector = Vector2(posDirectory.x / nDirectoryLen, posDirectory.y / nDirectoryLen)
            posCreate = castPos + nEffectOffset * effectDirector
        end
        local effectEntity =
            effectService:CreateWorldPositionDirectionEffect(nTrajectoryEffectID, posCreate, posDirectory)
        effectEntities[posDamage] = effectEntity
    end
    YIELD(TT)
    local nMaxTime = nTrajectoryTime
    local needWaitTaskIds = {}
    ---@param res SkillDamageEffectResult
    for _, res in pairs(results) do
        local targetEntity = self._world:GetEntityByID(res:GetTargetID())
        local posDamage = res:GetGridPos() --- targetEntity:GetDamageCenter()  --GridLocation().Position
        local attachPos = posDamage
        local disx = math.abs(attachPos.x - castPos.x)
        local disy = math.abs(attachPos.y - castPos.y)
        local dis = math.sqrt(disx * disx + disy * disy)

        -- Log.debug( "[skill] 远程攻击: 坐标 (" .. castPos.x .. "." .. castPos.y, ") >===> (", attachPos.x .. "." .. attachPos.y, ")" )
        local entityEffect = effectEntities[posDamage]
        ---@type UnityEngine.Transform
        local trajectoryObject = entityEffect:View():GetGameObject()
        local transWork = trajectoryObject.transform
        local gridWorldpos = boardServiceRender:GridPos2RenderPos(attachPos)
        local nFlayTime = dis * nTrajectoryTime / 1000.0
        local easeWork = nil
        if SkillPhaseParam_RangeAttack_TrajectoryType.Line == nTrajectoryType then ---直线
            easeWork = transWork:DOMove(gridWorldpos, nFlayTime, false):SetEase(DG.Tweening.Ease.InOutSine)
        elseif SkillPhaseParam_RangeAttack_TrajectoryType.Parabola == nTrajectoryType then ---抛物线
            transWork.position = transWork.position + Vector3.up * 1 --抛射起点高度偏移
            local jumpPower = math.sqrt(disx + disy)
            ---@type DG.Tweening.Sequence
            local sequence = transWork:DOJump(gridWorldpos, jumpPower, 1, nFlayTime, false)
            easeWork = sequence:SetEase(DG.Tweening.Ease.InOutSine)
        elseif SkillPhaseParam_RangeAttack_TrajectoryType.Laser == nTrajectoryType then ---直线激光表现
            ---@type DG.Tweening.Sequence
            local sequence = transWork:DOScaleZ(dis, nFlayTime)
            easeWork = sequence:SetEase(DG.Tweening.Ease.InOutSine)
        end
        if easeWork then
            local taskId =
                GameGlobal.TaskManager():CoreGameStartTask(
                self._DoTweenCompleteCall,
                self,
                casterEntity,
                targetEntity,
                phaseParam,
                castPos,
                attachPos,
                res,
                isFinalHit,
                nSkillID,
                nFlayTime,
                entityEffect
            )
            needWaitTaskIds[#needWaitTaskIds + 1] = taskId
        end

        if nMaxTime < nFlayTime then
            nMaxTime = nFlayTime
        end
    end
    local endtime = GameGlobal:GetInstance():GetCurrentTime() + nMaxTime

    while GameGlobal:GetInstance():GetCurrentTime() < endtime do
        YIELD(TT)
    end

    YIELD(TT)

    self:_WaitSonTask(needWaitTaskIds)

    return true
end

function PlaySkillRangeAttackAnimationPhase:_DoTweenCompleteCall(
    TT,
    casterEntity,
    targetEntity,
    phaseParam,
    castPos,
    attachPos,
    res,
    isFinalHit,
    nSkillID,
    nFlayTime,
    entityEffect)
    YIELD(TT, nFlayTime * 1000)
    self._world:DestroyEntity(entityEffect)
    self:_PlayTrajectoryOverEffect(TT, phaseParam:GetTargetEffectID(), phaseParam:GetHpDelay(), castPos, attachPos)
    self:_PlayHitEffect(TT, casterEntity, targetEntity, phaseParam, res, isFinalHit, nSkillID)
end

function PlaySkillRangeAttackAnimationPhase:_PlayTrajectoryOverEffect(TT, nEffectID, nShowTime, posCast, posGrid)
    if nil == nEffectID or nEffectID <= 0 then
        return
    end
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    local posDirectory = posGrid - posCast
    local entityEffect = effectService:CreateWorldPositionDirectionEffect(nEffectID, posGrid, posDirectory)
    YIELD(TT, nShowTime)
    -- local targetEffectID = phaseParam:GetTargetEffectID()
    -- if targetEffectID then
    -- 	self._world:GetService("Effect"):CreateEffect(targetEffectID, entityTarget)
    -- end
    -- --延迟
    -- local hpDelayTime = phaseParam:GetHpDelay()
    -- YIELD(TT, hpDelayTime)
end

---@param phaseParam SkillPhaseRangeAttackAnimationParam
function PlaySkillRangeAttackAnimationPhase:_PlayHitEffect(
    TT,
    entityCast,
    entityTarget,
    phaseParam,
    result,
    isFinalHit,
    nSkillID)
    local hitAnimationName = phaseParam:GetHitAnimation()
    local hitEffectID = phaseParam:GetHitEffectID()
    local targetDamage = result:GetDamageInfo(1)
    local damagePos = result:GetGridPos()
    ---@type PlaySkillService
    local skillService = self:SkillService()
    ---调用统一处理被击的逻辑
    local beHitParam = HandleBeHitParam:New()
        :SetHandleBeHitParam_CasterEntity(entityCast)
        :SetHandleBeHitParam_TargetEntity(entityTarget)
        :SetHandleBeHitParam_HitAnimName(hitAnimationName)
        :SetHandleBeHitParam_HitEffectID(hitEffectID)
        :SetHandleBeHitParam_DamageInfo(targetDamage)
        :SetHandleBeHitParam_DamagePos(damagePos)
        :SetHandleBeHitParam_DeathClear(phaseParam:IsClearBodyNow())
        :SetHandleBeHitParam_IsFinalHit(isFinalHit)
        :SetHandleBeHitParam_SkillID(nSkillID)

    skillService:HandleBeHit(TT, beHitParam)
end
