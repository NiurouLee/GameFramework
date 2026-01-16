require "play_skill_phase_base_r"
--@class PlaySkillPhase_Trajectory: PlaySkillPhaseBase
_class("PlaySkillPhase_Trajectory", PlaySkillPhaseBase)
PlaySkillPhase_Trajectory = PlaySkillPhase_Trajectory

---@param casterEntity Entity
function PlaySkillPhase_Trajectory:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseParam_Trajectory
    local paramWork = phaseParam

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local isFinalHit = skillEffectResultContainer:IsFinalAttack()
    ---@type Vector2
    local posCaster = casterEntity:GetGridPosition()
    ---@type Vector2
    local posTarget = Vector2.New(0, 0)
    ---@type Vector2
    local posStart = self:_PhaseWorkPos(paramWork:GetCasterType(), paramWork:GetCasterParam(), posCaster, posTarget)
    ---@type Vector2
    local posEnd = self:_PhaseWorkPos(paramWork:GetTargetType(), paramWork:GetTargetParam(), posCaster, posTarget)

    local bHaveBit = self:_TrajectoryAction(TT, skillID, paramWork, casterEntity, posStart, posEnd, isFinalHit)

    local finishDelayTime = paramWork:GetFinishDelayTime()
    YIELD(TT, finishDelayTime)
end

function PlaySkillPhase_Trajectory:_PhaseWorkPos(posType, posParam, posCaster, posTarget)
    local posReturn = Vector2.New(0, 0)
    if SkillPhaseParam_PointType.CasterPos == posType then
        posReturn = posCaster
    elseif SkillPhaseParam_PointType.CasterX == posType then
        posReturn.x = posCaster.x
        posReturn.y = posParam.y
    elseif SkillPhaseParam_PointType.CasterY == posType then
        posReturn.x = posParam.x
        posReturn.y = posCaster.y
    elseif SkillPhaseParam_PointType.TargetPos == posType then
        posReturn = posTarget
    elseif SkillPhaseParam_PointType.TargetX == posType then
        posReturn.x = posTarget.x
        posReturn.y = posParam.y
    elseif SkillPhaseParam_PointType.TargetY == posType then
        posReturn.x = posParam.x
        posReturn.y = posTarget.y
    elseif SkillPhaseParam_PointType.UserParam == posType then
        posReturn = posParam
    end
    return posReturn
end

---@param phaseParam SkillPhaseParam_Trajectory
---@param damageData DamageInfo
function PlaySkillPhase_Trajectory:_TrajectoryAction(
    TT,
    nSkillID,
    phaseParam,
    entityCaster,
    posStart,
    posEnd,
    isFinalHit)
    local nTrajectoryType = phaseParam:GetTrajectoryType()
    if nil == nTrajectoryType then
        return false
    end
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---@type EffectService
    local effectService = self._world:GetService("Effect")

    ---创建抛射体
    ---@type Entity
    local entityEffect = nil
    ---@type Vector2
    local posDirectory = posEnd - posStart
    local nEffectOffset = phaseParam:GetTrajectoryEffectOffset()
    local posCreate = posStart
    if nEffectOffset and nEffectOffset ~= 0 then
        local nDirectoryLen = math.max(math.abs(posDirectory.x), math.abs(posDirectory.y), 1)
        local effectDirector = Vector2(posDirectory.x / nDirectoryLen, posDirectory.y / nDirectoryLen)
        posCreate = posStart + nEffectOffset * effectDirector
    end
    local nTrajectoryEffectID = phaseParam:GetTrajectoryEffectID()
    entityEffect = effectService:CreateWorldPositionDirectionEffect(nTrajectoryEffectID, posCreate, posDirectory)
    YIELD(TT)
    ---飞行时长
    local disx = math.abs(posEnd.x - posStart.x)
    local disy = math.abs(posEnd.y - posStart.y)
    local dis = math.sqrt(disx * disx + disy * disy)
    local nTotalTime = phaseParam:GetTotalTime()
    if nil == nTotalTime then
        local nTrajectoryTime = phaseParam:GetTrajectoryTime()
        nTotalTime = dis * nTrajectoryTime
    end
    local nFlyTime = nTotalTime / 1000.0

    local nEndTime = GameGlobal:GetInstance():GetCurrentTime() + nTotalTime
    ---開始彈道
    ---@type UnityEngine.Transform
    local trajectoryObject = entityEffect:View():GetGameObject()
    local transWork = trajectoryObject.transform
    local gridWorldpos = boardServiceRender:GridPos2RenderPos(posEnd)
    local easeWork = nil
    if SkillPhaseParam_TrajectoryType.Line == nTrajectoryType then ---直线
        easeWork = transWork:DOMove(gridWorldpos, nFlyTime, false):SetEase(DG.Tweening.Ease.InOutSine)
    elseif SkillPhaseParam_TrajectoryType.Parabola == nTrajectoryType then ---抛物线
        transWork.position = transWork.position + Vector3.up * 1 --抛射起点高度偏移
        local jumpPower = math.sqrt(disx + disy)
        ---@type DG.Tweening.Sequence
        local sequence = transWork:DOJump(gridWorldpos, jumpPower, 1, nFlyTime, false)
        easeWork = sequence:SetEase(DG.Tweening.Ease.InOutSine)
    elseif SkillPhaseParam_TrajectoryType.Laser == nTrajectoryType then ---直线激光表现
        ---@type DG.Tweening.Sequence
        local sequence = transWork:DOScaleZ(dis, nFlyTime)
        easeWork = sequence:SetEase(DG.Tweening.Ease.InOutSine)
    end
    if SkillPhaseParam_TrajectoryType.Line == nTrajectoryType then ---直线
        self:_CheckFlyAttack(
            TT,
            nSkillID,
            phaseParam,
            entityCaster,
            entityEffect,
            nEndTime,
            posStart,
            posEnd,
            isFinalHit
        )
        self:_DelEffectEntity(TT, trajectoryObject, entityEffect)
    else
        if easeWork then
            easeWork:OnComplete(
                function()
                    self:_OnTrajectoryEnd(TT, nSkillID, phaseParam, entityCaster, posStart, posEnd, isFinalHit)
                    self:_DelEffectEntity(TT, trajectoryObject, entityEffect)
                end
            )
        end
        ---等待飞行结束
        while GameGlobal:GetInstance():GetCurrentTime() < nEndTime do
            YIELD(TT)
        end
    end
    return true
end
function PlaySkillPhase_Trajectory:_OnTrajectoryEnd(TT, nSkillID, phaseParam, entityCaster, posStart, posEnd, isFinalHit)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = entityCaster:SkillRoutine():GetResultContainer()
    ---@type SkillDamageEffectResult
    local damageResult = skillEffectResultContainer:GetEffectResultByPos(SkillEffectType.Damage, posEnd)
    if damageResult then
        ---@type DamageInfo
        local damageData = damageResult:GetDamageInfo(phaseParam:GetDamageIndex())
        if damageData then
            local entityTarget = self._world:GetEntityByID(damageResult:GetTargetID())
            self:_OnFlyAttack(
                TT,
                nSkillID,
                phaseParam,
                entityCaster,
                entityTarget,
                damageData,
                posStart,
                posEnd,
                isFinalHit
            )
        end
    end
end
function PlaySkillPhase_Trajectory:_DelEffectEntity(TT, trajectoryObject, entityEffect)
    trajectoryObject:SetActive(false)
    self._world:DestroyEntity(entityEffect)
end
---获取弹道的逻辑坐标
function PlaySkillPhase_Trajectory:_GetEntityPosByView(entityWork)
    ---@type ViewComponent
    local effectViewCmpt = entityWork:View()
    if nil == effectViewCmpt then
        return nil
    end
    ---@type UnityEngine.GameObject
    local effectObject = effectViewCmpt:GetGameObject()
    if nil == effectObject then
        return nil
    end
    ---@type UnityEngine.Transform
    local effectTrans = effectObject.transform
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local posReturn = boardServiceRender:BoardRenderPos2GridPos(effectTrans.position)
    return posReturn
end
---检查弹道路径上是否有攻击目标
---@param phaseParam SkillPhaseParam_Trajectory
function PlaySkillPhase_Trajectory:_CheckFlyAttack(
    TT,
    nSkillID,
    phaseParam,
    entityCaster,
    entityEffect,
    nEndTime,
    posStart,
    posEnd,
    isFinalHit)
    if nil == entityEffect then
        return
    end
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    local hitAnimName = phaseParam:GetHitAnimation()
    local hitEffectID = phaseParam:GetHitEffectID()
    local hitEffectTime = phaseParam:GetHitEffectTime()
    local nWaitTime = phaseParam:GetTargetWaitTime() or 0

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = entityCaster:SkillRoutine():GetResultContainer()
    self:_InitFlyPosList()
    local bFirstAttack = true
    while GameGlobal:GetInstance():GetCurrentTime() < nEndTime do
        local posFly = self:_GetEntityPosByView(entityEffect)
        if posFly then
            ---Log.debug("飞行弹道：路过坐标(" .. posFly.x .. "," .. posFly.y .. ")" );
            local listDamageData = self:_FindFlyDamageResult(skillEffectResultContainer, posFly, posStart, posEnd, 2)
            for posDamage, damageResult in pairs(listDamageData) do
                ---@type DamageInfo
                local damageData = damageResult:GetDamageInfo(phaseParam:GetDamageIndex())
                if damageData then
                    ---@type Entity
                    local entityTarget = self._world:GetEntityByID(damageResult:GetTargetID())
                    if bFirstAttack then
                        bFirstAttack = false
                        self:_DelayTime(TT, nWaitTime)
                    end
                    local nTaskID =
                        GameGlobal.TaskManager():CoreGameStartTask(
                        self._OnFlyAttack,
                        self,
                        nSkillID,
                        phaseParam,
                        entityCaster,
                        entityTarget,
                        damageData,
                        posStart,
                        posDamage,
                        isFinalHit
                    )
                    playSkillService:AddWaitFreeTask(nTaskID)
                end
            end
        end
        YIELD(TT)
    end
end
---@param phaseParam SkillPhaseParam_Trajectory
function PlaySkillPhase_Trajectory:_PlayTargetEffect(TT, phaseParam, posStart, posEnd)
    local nEffectID = phaseParam:GetTargetEffectID()
    local nShowTime = phaseParam:GetTargetDelayTime()
    if nil == nEffectID or nEffectID <= 0 then
        return
    end
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    local posDirectory = posEnd - posStart
    local entityEffect = effectService:CreateWorldPositionDirectionEffect(nEffectID, posEnd, posDirectory)
    YIELD(TT, nShowTime)
end

---@param phaseParam SkillPhaseParam_Trajectory
---@param damageData DamageInfo
function PlaySkillPhase_Trajectory:_PlayHitEffect(
    TT,
    phaseParam,
    entityCast,
    entityTarget,
    damageData,
    damagePos,
    isFinalHit,
    nSkillID)
    local hitAnimationName = phaseParam:GetHitAnimation()
    local hitEffectID = phaseParam:GetHitEffectID()
    ---@type PlaySkillService
    local skillService = self:SkillService()
    ---调用统一处理被击的逻辑
    local beHitParam = HandleBeHitParam:New()
        :SetHandleBeHitParam_CasterEntity(entityCast)
        :SetHandleBeHitParam_TargetEntity(entityTarget)
        :SetHandleBeHitParam_HitAnimName(hitAnimationName)
        :SetHandleBeHitParam_HitEffectID(hitEffectID)
        :SetHandleBeHitParam_DamageInfo(damageData)
        :SetHandleBeHitParam_DamagePos(damagePos)
        :SetHandleBeHitParam_DeathClear(phaseParam:IsClearBodyNow())
        :SetHandleBeHitParam_IsFinalHit(isFinalHit)
        :SetHandleBeHitParam_SkillID(nSkillID)

    skillService:HandleBeHit(TT, beHitParam)
end
---弹道飞行命中目标
function PlaySkillPhase_Trajectory:_OnFlyAttack(
    TT,
    nSkillID,
    phaseParam,
    entityCaster,
    entityTarget,
    damageData,
    posStart,
    posEnd,
    isFinalHit)
    self:_PlayTargetEffect(TT, phaseParam, posStart, posEnd)
    if damageData then
        self:_PlayHitEffect(TT, phaseParam, entityCaster, entityTarget, damageData, posEnd, isFinalHit, nSkillID)
    end
end
---已经命中的列表
function PlaySkillPhase_Trajectory:_InitFlyPosList()
    self.m_listFlyPos = {}
end
---检查是否命中，否则加入
function PlaySkillPhase_Trajectory:_IsHaveFlyPosList(pos)
    if table.icontains(self.m_listFlyPos, pos) then
        return true
    end
    self.m_listFlyPos[#self.m_listFlyPos + 1] = pos
    return false
end
---直线范围校验是否命中： 防止弹道飞行过快
function PlaySkillPhase_Trajectory:_FindFlyDamageResult(
    skillEffectResultContainer,
    posFly,
    posStart,
    posEnd,
    nCheckRange)
    local dir = posStart - posEnd
    local dirTemp = Vector2.New(math.abs(dir.x), math.abs(dir.y))
    if dirTemp.x > 0 then
        dir.x = dir.x / dirTemp.x
    end
    if dirTemp.y > 0 then
        dir.y = dir.y / dirTemp.y
    end
    local listDamageData = {}
    for i = 0, nCheckRange do
        local posNew = posFly + dir * (nCheckRange - i)
        if posNew.x > 0 and posNew.y > 0 then ---简单的数据有效性校验
            ---@type SkillDamageEffectResult
            local damageResult = skillEffectResultContainer:GetEffectResultByPos(SkillEffectType.Damage, posNew)
            if damageResult then
                if false == self:_IsHaveFlyPosList(posNew) then
                    listDamageData[posNew] = damageResult
                end
            end
        end
    end
    return listDamageData
end
