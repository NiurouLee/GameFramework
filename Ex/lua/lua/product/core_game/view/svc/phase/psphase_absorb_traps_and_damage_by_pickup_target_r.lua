require "play_skill_phase_base_r"
---@class PlaySkillAbsorbTrapsAndDamageByPickupTargetPhase: PlaySkillPhaseBase
_class("PlaySkillAbsorbTrapsAndDamageByPickupTargetPhase", PlaySkillPhaseBase)
PlaySkillAbsorbTrapsAndDamageByPickupTargetPhase = PlaySkillAbsorbTrapsAndDamageByPickupTargetPhase

---@param phaseParam SkillPhaseAbsorbTrapsAndDamageByPickupTargetParam
function PlaySkillAbsorbTrapsAndDamageByPickupTargetPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillEffectResultContainer
    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectAbsorbTrapsAndDamageByPickupTargetResult
    local result = routineComponent:GetEffectResultByArray(SkillEffectType.AbsorbTrapsAndDamageByPickupTarget)
    if not result then
        return
    end

    local trapTrajectoryInfoArray = {}
    local removeTrapEntityArray = {}

    local trapStartHeight = phaseParam:GetTrapStartHeight()
    local trapEndHeight = phaseParam:GetTrapEndHeight()
    local trapFlyTime = phaseParam:GetTrapFlyTotalTime()
    local trapTrajectoryID = phaseParam:GetTrapTrajectoryID()

    local trapIDArray = result:GetTrapEntityIDs()

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    local casterPos = casterEntity:GetGridPosition()
    local trapTargetPos = Vector2.New(casterPos.x, casterPos.y)
    trapTargetPos = boardServiceRender:GridPos2RenderPos(Vector2.New(casterPos.x + 0.5, casterPos.y + 0.5))
    trapTargetPos.y = trapTargetPos.y + phaseParam:GetTrapEndHeight()

    ---@type EffectService
    local effectService = self._world:GetService("Effect")

    YIELD(TT, phaseParam:GetTrapStartDelay())

    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")

    local trapCount = #trapIDArray
    for _, trapEntityID in ipairs(trapIDArray) do
        local trapEntity = self._world:GetEntityByID(trapEntityID)
        table.insert(removeTrapEntityArray, trapEntity)

        local trapEntityPos = trapEntity:GetGridPosition()
        effectService:CreateWorldPositionEffect(phaseParam:GetTrapGridEffID(), trapEntityPos)

        local trapBeginPos = boardServiceRender:GridPos2RenderPos(trapEntityPos)
        trapBeginPos.y = trapBeginPos.y + phaseParam:GetTrapStartHeight()
        local effectEntity = effectService:CreatePositionEffect(trapTrajectoryID, trapBeginPos)
        ---@class Internal_PlaySkillAbsorbTrapsAndDamageByPickupTargetPhase_TrajectoryInfo
        local trajectoryInfo = {
            startHeight = trapStartHeight,
            endHeight = trapEndHeight,
            totalTime = trapFlyTime * 0.001,
            totalTimeMs = trapFlyTime,
            targetRenderPos = trapTargetPos,
            currentTime = 0,
            trajectoryID = trapTrajectoryID,
            trajectoryEntity = effectEntity
        }
        table.insert(trapTrajectoryInfoArray, trajectoryInfo)
    end

    YIELD(TT)

    trapServiceRender:DestroyTrapList(TT, removeTrapEntityArray)
    for _, e in ipairs(removeTrapEntityArray) do
        ---@type TrapRenderComponent
        local trapRenderCmpt = e:TrapRender()
        if trapRenderCmpt then
            trapRenderCmpt:SetHadPlayDead()
        end
    end

    local trapTaskIDs = {}
    for _, trajectoryInfo in ipairs(trapTrajectoryInfoArray) do
        table.insert(trapTaskIDs, GameGlobal.TaskManager():CoreGameStartTask(self._DoFly, self, trajectoryInfo))
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(trapTaskIDs) do
        YIELD(TT)
    end

    YIELD(TT, phaseParam:GetHitDelayTime())

    local hitAnimName = phaseParam:GetHitAnimationName()
    local hitFxID = phaseParam:GetHitEffectId()
    ---@type PlaySkillService
    local skillService = self:SkillService()

    local finalAttackIndex = result:GetFinalAttackIndex()
    local skillID = routineComponent:GetSkillID()
    ---@type table<number, SkillDamageEffectResult>
    local damageResultArray = result:GetDamageResultArray()
    for index, damageResult in ipairs(damageResultArray) do
        local targetEntityID = damageResult:GetTargetID()
        local targetEntity = self._world:GetEntityByID(targetEntityID)
        local damageInfoArray = damageResult:GetDamageInfoArray()
        local damageGridPos = damageResult:GetGridPos()
        for __, damageInfo in ipairs(damageInfoArray) do
            local beHitParam = HandleBeHitParam:New()
                :SetHandleBeHitParam_CasterEntity(casterEntity)
                :SetHandleBeHitParam_TargetEntity(targetEntity)
                :SetHandleBeHitParam_HitAnimName(hitAnimName)
                :SetHandleBeHitParam_HitEffectID(hitFxID)
                :SetHandleBeHitParam_DamageInfo(damageInfo)
                :SetHandleBeHitParam_DamagePos(damageGridPos)
                :SetHandleBeHitParam_DeathClear(false)
                :SetHandleBeHitParam_IsFinalHit(index == finalAttackIndex)
                :SetHandleBeHitParam_SkillID(skillID)

            skillService:HandleBeHit(TT, beHitParam)

            if phaseParam:GetEachDamageTime() > 0 then
                YIELD(TT, phaseParam:GetEachDamageTime())
            end
        end
    end
end

---@param trajectoryInfo Internal_PlaySkillAbsorbTrapsAndDamageByPickupTargetPhase_TrajectoryInfo
function PlaySkillAbsorbTrapsAndDamageByPickupTargetPhase:_DoFly(TT, trajectoryInfo)
    local entity = trajectoryInfo.trajectoryEntity
    ---@type ViewComponent
    local effectViewCmpt = entity:View()
    ---@type UnityEngine.GameObject
    local effectObject = effectViewCmpt:GetGameObject()
    local posEffect = effectObject.transform.position
    local transWork = effectObject.transform

    local _easeWork =
        transWork:DOMove(trajectoryInfo.targetRenderPos, trajectoryInfo.totalTime, false):SetEase(
        DG.Tweening.Ease.InOutSine
    )

    YIELD(TT, trajectoryInfo.totalTimeMs)
    self._world:DestroyEntity(trajectoryInfo.trajectoryEntity)
end
