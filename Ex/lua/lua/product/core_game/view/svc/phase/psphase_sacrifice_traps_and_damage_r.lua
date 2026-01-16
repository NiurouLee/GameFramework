require "play_skill_phase_base_r"
---@class PlaySkillSacrificeTrapsAndDamagePhase: PlaySkillPhaseBase
_class("PlaySkillSacrificeTrapsAndDamagePhase", PlaySkillPhaseBase)
PlaySkillSacrificeTrapsAndDamagePhase = PlaySkillSacrificeTrapsAndDamagePhase

---@param phaseParam SkillPhaseSacrificeTrapsAndDamageParam
function PlaySkillSacrificeTrapsAndDamagePhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillEffectResultContainer
    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectSacrificeTrapsAndDamageResult
    local result = routineComponent:GetEffectResultByArray(SkillEffectType.SacrificeTrapsAndDamage)

    if not result then
        return
    end

    local trapTrajectoryInfoArray = {}
    local removeTrapEntityArray = {}

    local trapStartHeight = phaseParam:GetTrapStartHeight()
    local trapEndHeight = phaseParam:GetTrapEndHeight()
    local trapFlyTime = phaseParam:GetTrapFlyTotalTime()
    local trapTrajectoryID = phaseParam:GetTrapTrajectoryID()

    local trapIDArray = result:GetTrapIDArray()

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    local casterPos = casterEntity:GetGridPosition()
    local trapTargetPos = Vector2.New(casterPos.x, casterPos.y)
    trapTargetPos = boardServiceRender:GridPos2RenderPos(Vector2.New(casterPos.x + 0.5, casterPos.y + 0.5))
    trapTargetPos.y = trapTargetPos.y + phaseParam:GetTrapEndHeight()

    ---@type EffectService
    local effectService = self._world:GetService("Effect")

    casterEntity:SetAnimatorControllerTriggers({phaseParam:GetCasterAnimName()})
    local effectID =
        (#trapIDArray > 0) and (phaseParam:GetSuccessCasterEffectID()) or (phaseParam:GetNoTrapCasterEffectID())
    effectService:CreateEffect(effectID, casterEntity)
    effectService:CreateEffect(phaseParam:GetCastEffectID(), casterEntity)

    YIELD(TT, phaseParam:GetTrapStartDelay())

    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")

    local trapCount = #trapIDArray
    for _, trapEntityID in ipairs(trapIDArray) do
        local trapEntity = self._world:GetEntityByID(trapEntityID)
        local trapEntityPos = trapEntity:GetGridPosition()
        local trapBeginPos = boardServiceRender:GridPos2RenderPos(Vector2.New(trapEntityPos.x, trapEntityPos.y))
        trapBeginPos.y = trapBeginPos.y + phaseParam:GetTrapStartHeight()
        local effectEntity = effectService:CreatePositionEffect(trapTrajectoryID, trapBeginPos)
        ---@class Internal_PlaySkillSacrificeTrapsAndDamagePhase_TrajectoryInfo
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

    for _, trapEntityID in ipairs(trapIDArray) do
        table.insert(removeTrapEntityArray, self._world:GetEntityByID(trapEntityID))
    end
    trapServiceRender:DestroyTrapList(TT,removeTrapEntityArray)
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

    YIELD(TT, phaseParam:GetBowlderStartDelay())

    local bowlderBeginRenderPos =
        boardServiceRender:GridPos2RenderPos(Vector2.New(casterPos.x + 0.5, casterPos.y + 0.5))
    bowlderBeginRenderPos.y = bowlderBeginRenderPos.y + phaseParam:GetBowlderStartHeight()

    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local playerPos = teamEntity:GetGridPosition()
    local bowlderTargetPos = boardServiceRender:GridPos2RenderPos(Vector2.New(playerPos.x, playerPos.y))
    bowlderTargetPos.y = bowlderTargetPos.y + phaseParam:GetBowlderEndHeight()

    local bowlderTime = phaseParam:GetBowlderFlyTotalTime()
    local bowlderID = phaseParam:GetBowlderTrajectoryID()
    local bowlderEffectEntity = effectService:CreatePositionEffect(bowlderID, bowlderBeginRenderPos)

    YIELD(TT)

    ---@type Internal_PlaySkillSacrificeTrapsAndDamagePhase_TrajectoryInfo
    local bowlderTrajectoryInfo = {
        startHeight = phaseParam:GetBowlderStartHeight(),
        endHeight = phaseParam:GetBowlderEndHeight(),
        totalTime = bowlderTime * 0.001,
        totalTimeMs = bowlderTime,
        targetRenderPos = bowlderTargetPos,
        currentTime = 0,
        trajectoryID = bowlderID,
        trajectoryEntity = bowlderEffectEntity
    }

    GameGlobal.TaskManager():CoreGameStartTask(self._DoFly, self, bowlderTrajectoryInfo)

    local hitAnimName = phaseParam:GetHitAnimationName()
    local hitFxID = phaseParam:GetHitEffectId()
    local delayTime = phaseParam:GetHitDelayTime()
    ---@type PlaySkillService
    local skillService = self:SkillService()

    local isFinalHit = routineComponent:IsFinalAttack()
    local skillID = routineComponent:GetSkillID()
    ---@type table<number, SkillDamageEffectResult>
    local damageResultArray = result:GetDamageResultArray()
    for _, damageResult in ipairs(damageResultArray) do
        local targetEntityID = damageResult:GetTargetID()
        local targetEntity = self._world:GetEntityByID(targetEntityID)
        local damageInfoArray = damageResult:GetDamageInfoArray()
        local posCast = self:_GetEntityBasePos(casterEntity)
        local posTarget = self:_GetEntityBasePos(targetEntity)
        for __, damageInfo in ipairs(damageInfoArray) do
            self:_PlayEffect(TT, posCast, posTarget, hitFxID, delayTime)

            ---调用统一处理被击的逻辑
            local beHitParam = HandleBeHitParam:New()
                :SetHandleBeHitParam_CasterEntity(casterEntity)
                :SetHandleBeHitParam_TargetEntity(targetEntity)
                :SetHandleBeHitParam_HitAnimName(hitAnimName)
                :SetHandleBeHitParam_HitEffectID(hitFxID)
                :SetHandleBeHitParam_DamageInfo(damageInfo)
                :SetHandleBeHitParam_DamagePos(posTarget)
                :SetHandleBeHitParam_DeathClear(false)
                :SetHandleBeHitParam_IsFinalHit(isFinalHit)
                :SetHandleBeHitParam_SkillID(skillID)

            skillService:HandleBeHit(TT, beHitParam)
        end
    end
end

---@param trajectoryInfo Internal_PlaySkillSacrificeTrapsAndDamagePhase_TrajectoryInfo
function PlaySkillSacrificeTrapsAndDamagePhase:_DoFly(TT, trajectoryInfo)
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
