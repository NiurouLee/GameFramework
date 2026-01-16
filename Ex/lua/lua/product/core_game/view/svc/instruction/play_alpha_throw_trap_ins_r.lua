require("base_ins_r")
---@class PlayAlphaThrowTrapInstruction : BaseInstruction
_class("PlayAlphaThrowTrapInstruction", BaseInstruction)
PlayAlphaThrowTrapInstruction = PlayAlphaThrowTrapInstruction

function PlayAlphaThrowTrapInstruction:Constructor(paramList)
    self._hitAnimName = paramList.hitAnim
    self._hitDelayTime = tonumber(paramList.hitDelayTime) or 0
    self._hitEffectID = tonumber(paramList.hitEffectID)
    self._eachDamageTime = tonumber(paramList.eachDamageTime) or 0

    self._delTrapDelay = tonumber(paramList.delTrapDelay) or 0

    --范围内机关相关
    self._trapStartDelay = tonumber(paramList.trapStartDelay) or 0
    self._trapTrajectoryID = tonumber(paramList.trapTrajectoryID)
    self._trapStartHeight = tonumber(paramList.trapStartHeight)
    self._trapEndHeight = tonumber(paramList.trapEndHeight)
    self._trapFlyTotalTime = tonumber(paramList.trapFlyTotalTime) or 0

    --骑乘的机关相关
    self._rideTrapStartHeight = tonumber(paramList.rideTrapStartHeight)
    self._rideTrapTrajectoryID = tonumber(paramList.rideTrapTrajectoryID)

    --最终设置施法者高度
    self._resetHeightDelay = tonumber(paramList.resetHeightDelay) or 0
end

function PlayAlphaThrowTrapInstruction:GetCacheResource()
    local t = {}
    if self._hitEffectID and self._hitEffectID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._hitEffectID].ResPath, 1 })
    end
    if self._trapTrajectoryID and self._trapTrajectoryID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._trapTrajectoryID].ResPath, 1 })
    end
    if self._rideTrapTrajectoryID and self._rideTrapTrajectoryID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._trapTrajectoryID].ResPath, 1 })
    end
    return t
end

---@param casterEntity Entity
function PlayAlphaThrowTrapInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local resultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectAlphaThrowTrapResult
    local result = resultContainer:GetEffectResultByArray(SkillEffectType.AlphaThrowTrap)
    if not result then
        return
    end

    local trapTrajectoryInfoArray = {}
    local removeTrapEntityArray = {}
    ---@type EffectService
    local effectService = world:GetService("Effect")
    ---@type TrapServiceRender
    local trapRenderSvc = world:GetService("TrapRender")

    local trapMountID = result:GetTrapMountID()
    local trapMountPos = nil
    if trapMountID then
        --坐骑基座先碎
        local trapEntity = world:GetEntityByID(trapMountID)
        trapMountPos = trapEntity:GetGridPosition()
        trapRenderSvc:PlayTrapDieSkill(TT, { trapEntity })
    end
    ---@type RideServiceRender
    local rideRenderSvc = world:GetService("RideRender")
    local monsterMountID = result:GetMonsterMountID()
    if monsterMountID then
        rideRenderSvc:RemoveRideRender(casterEntity:GetID(), monsterMountID)
    end

    YIELD(TT, self._delTrapDelay)

    --删除所有基座
    local trapIDArray = result:GetTrapEntityIDs()
    for _, trapEntityID in ipairs(trapIDArray) do
        local trapEntity = world:GetEntityByID(trapEntityID)
        if trapEntityID ~= trapMountID then
            table.insert(removeTrapEntityArray, trapEntity)
        end
    end
    trapRenderSvc:PlayTrapDieSkill(TT, removeTrapEntityArray)

    --取目标位置
    ---@type SkillDamageEffectResult
    local damageResult = result:GetDamageResult()
    local damagePos = damageResult:GetGridPos()
    local trapTargetPos = Vector2.New(damagePos.x, damagePos.y)
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    trapTargetPos = boardServiceRender:GridPos2RenderPos(Vector2.New(trapTargetPos.x + 0.5, trapTargetPos.y + 0.5))
    trapTargetPos.y = trapTargetPos.y + self._trapEndHeight

    YIELD(TT, self._trapStartDelay)

    --飞行特效及格子特效
    for _, trapEntityID in ipairs(trapIDArray) do
        local trapEntity = world:GetEntityByID(trapEntityID)
        local trapEntityPos = trapEntity:GetGridPosition()
        local trapStartHeight = self._rideTrapStartHeight
        local trapTrajectoryID = self._rideTrapTrajectoryID
        local effectDir = damagePos - trapEntityPos

        if trapEntityID ~= trapMountID then
            trapStartHeight = self._trapStartHeight
            trapTrajectoryID = self._trapTrajectoryID
        end

        local trapBeginPos = boardServiceRender:GridPos2RenderPos(trapEntityPos)
        trapBeginPos.y = trapBeginPos.y + trapStartHeight
        local effectEntity = effectService:CreatePositionEffect(trapTrajectoryID, trapBeginPos)
        if effectEntity then
            effectEntity:SetDirection(effectDir)
        end
        ---@class Internal_PlayAlphaThrowTrapInstruction_TrajectoryInfo
        local trajectoryInfo = {
            startHeight = trapStartHeight,
            endHeight = self._trapEndHeight,
            totalTime = self._trapFlyTotalTime * 0.001,
            totalTimeMs = self._trapFlyTotalTime,
            targetRenderPos = trapTargetPos,
            currentTime = 0,
            trajectoryID = trapTrajectoryID,
            trajectoryEntity = effectEntity
        }
        table.insert(trapTrajectoryInfoArray, trajectoryInfo)
    end

    YIELD(TT)

    local trapTaskIDs = {}
    for _, trajectoryInfo in ipairs(trapTrajectoryInfoArray) do
        table.insert(trapTaskIDs, GameGlobal.TaskManager():CoreGameStartTask(self._DoFly, self, trajectoryInfo))
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(trapTaskIDs) do
        YIELD(TT)
    end

    YIELD(TT, self._hitDelayTime)

    local hitAnimName = self._hitAnimName
    local hitFxID = self._hitEffectID
    ---@type PlaySkillService
    local playSkillSvc = world:GetService("PlaySkill")
    local skillID = resultContainer:GetSkillID()
    local targetEntityID = damageResult:GetTargetID()
    local targetEntity = world:GetEntityByID(targetEntityID)
    local damageInfoArray = damageResult:GetDamageInfoArray()
    for __, damageInfo in ipairs(damageInfoArray) do
        local beHitParam = HandleBeHitParam:New()
            :SetHandleBeHitParam_CasterEntity(casterEntity)
            :SetHandleBeHitParam_TargetEntity(targetEntity)
            :SetHandleBeHitParam_HitAnimName(hitAnimName)
            :SetHandleBeHitParam_HitEffectID(hitFxID)
            :SetHandleBeHitParam_DamageInfo(damageInfo)
            :SetHandleBeHitParam_DamagePos(damagePos)
            :SetHandleBeHitParam_DeathClear(false)
            :SetHandleBeHitParam_IsFinalHit(false)
            :SetHandleBeHitParam_SkillID(skillID)
            :SetHandleBeHitParam_PlayHitBack(false)

        playSkillSvc:HandleBeHit(TT, beHitParam)

        if self._eachDamageTime > 0 then
            YIELD(TT, self._eachDamageTime)
        end
    end

    --落地表现
    if trapMountID then
        rideRenderSvc:RemoveRideRender(casterEntity:GetID(), trapMountID)
        local curPos = casterEntity:Location():GetPosition()
        local tarPos = Vector3(curPos.x, 0, curPos.z)
        ---@type ViewComponent
        local effectViewCmpt = casterEntity:View()
        ---@type UnityEngine.GameObject
        local effectObject = effectViewCmpt:GetGameObject()
        local transWork = effectObject.transform

        local easeWork = transWork:DOMove(tarPos, self._resetHeightDelay * 0.001, false):SetEase(
            DG.Tweening.Ease.InOutSine
        )
    end

    YIELD(TT, self._resetHeightDelay)

    if trapMountID then
        casterEntity:SetLocationHeight(0)
    end

end

---@param trajectoryInfo Internal_PlayAlphaThrowTrapInstruction_TrajectoryInfo
function PlayAlphaThrowTrapInstruction:_DoFly(TT, trajectoryInfo)
    ---@type Entity
    local entity = trajectoryInfo.trajectoryEntity
    ---@type ViewComponent
    local effectViewCmpt = entity:View()
    ---@type UnityEngine.GameObject
    local effectObject = effectViewCmpt:GetGameObject()
    local posEffect = effectObject.transform.position
    local transWork = effectObject.transform

    local easeWork = transWork:DOMove(trajectoryInfo.targetRenderPos, trajectoryInfo.totalTime, false):SetEase(
        DG.Tweening.Ease.InOutSine
    )

    YIELD(TT, trajectoryInfo.totalTimeMs)
    ---@type MainWorld
    local world = entity:GetOwnerWorld()
    world:DestroyEntity(entity)
end
