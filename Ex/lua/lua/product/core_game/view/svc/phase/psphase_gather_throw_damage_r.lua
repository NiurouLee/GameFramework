require "play_skill_phase_base_r"
---@class PlaySkillGatherThrowDamagePhase: PlaySkillPhaseBase
_class("PlaySkillGatherThrowDamagePhase", PlaySkillPhaseBase)
PlaySkillGatherThrowDamagePhase = PlaySkillGatherThrowDamagePhase

---@param phaseParam SkillPhaseGatherThrowDamageParam
function PlaySkillGatherThrowDamagePhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillEffectResultContainer
    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectGatherThrowDamageResult
    local result = routineComponent:GetEffectResultByArray(SkillEffectType.GatherThrowDamage)
    if not result then
        return
    end
    local monsterTrajectoryInfoArray = {}
    local removeMonsterEntityArray = {}

    local monsterFlyTime = phaseParam:GetMonsterFlyTotalTime()

    local monsterIDArray = result:GetMonsterIDArray()
    local targetPetId = result:GetTargetID()
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local teamLeaderEntityID = teamEntity:Team():GetTeamLeaderEntityID()
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    local casterPos = casterEntity:GetGridPosition()
    local monsterFlyToPos = phaseParam:GetMonsterFlyToPos()
    if monsterFlyToPos then
        casterPos = monsterFlyToPos
    end
    local monsterTargetPos = Vector2.New(casterPos.x, casterPos.y)
    --monsterTargetPos = boardServiceRender:GridPos2RenderPos(Vector2.New(casterPos.x + 0.5, casterPos.y + 0.5))
    monsterTargetPos = boardServiceRender:GridPos2RenderPos(monsterTargetPos)
    monsterTargetPos.y = monsterTargetPos.y + phaseParam:GetMonsterEndHeight()

    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    --施法表现
    --施法动作
    casterEntity:SetAnimatorControllerTriggers({phaseParam:GetCasterAnimName()})
    --施法特效
    effectService:CreateEffect(phaseParam:GetCastEffectID(), casterEntity)

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    playSkillService:ShowPlayerEntity(teamEntity)

    --YIELD(TT, phaseParam:GetMonsterStartDelay())
    --吸入
    for _, monsterEntityID in ipairs(monsterIDArray) do
        local trajectoryInfo = self:_GenEntityFlyInfo(monsterEntityID,phaseParam,monsterTargetPos)
        table.insert(monsterTrajectoryInfoArray, trajectoryInfo)
    end
    local trajectoryInfo = self:_GenEntityFlyInfo(teamLeaderEntityID,phaseParam,monsterTargetPos)
    table.insert(monsterTrajectoryInfoArray, trajectoryInfo)
    YIELD(TT)

    local monsterTaskIDs = {}
    for _, trajectoryInfo in ipairs(monsterTrajectoryInfoArray) do
        table.insert(monsterTaskIDs, GameGlobal.TaskManager():CoreGameStartTask(self._DoFly, self, trajectoryInfo))
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(monsterTaskIDs) do
        YIELD(TT)
    end

    --执行怪物死亡
    for _, monsterEntityID in ipairs(monsterIDArray) do
        table.insert(removeMonsterEntityArray, self._world:GetEntityByID(monsterEntityID))
    end
    local msrSvc = self._world:GetService("MonsterShowRender")
    for _, eMonster in ipairs(removeMonsterEntityArray) do
        ---@type MonsterShowRenderService
        GameGlobal.TaskManager():CoreGameStartTask(function(TT)
            msrSvc:_DoOneMonsterDead(TT, eMonster)
        end)
    end

    YIELD(TT, phaseParam:GetBowlderStartDelay())


    ---@type PlaySkillService
    -- local playSkillService = self._world:GetService("PlaySkill")
    -- playSkillService:ShowPlayerEntity(teamEntity)
    --吐出
    local playerPos = teamEntity:GetGridPosition()
    local bowlderTargetPos = boardServiceRender:GridPos2RenderPos(Vector2.New(playerPos.x, playerPos.y))
    bowlderTargetPos.y = bowlderTargetPos.y + phaseParam:GetBowlderEndHeight()

    local bowlderTime = phaseParam:GetBowlderFlyTotalTime()
    local bowlderID = phaseParam:GetBowlderTrajectoryID()
    local bowlderBeginRenderPos = phaseParam:GetBowlderStartPos()
    local bowlderJumpHeight = phaseParam:GetBowlderJumpHeight()
    --local bowlderBeginRenderPos = Vector3(0,0.4,1.37)
    local bowlderEffectEntity = effectService:CreatePositionEffect(bowlderID, bowlderBeginRenderPos)
    YIELD(TT)
    ---@type Internal_PlaySkillGatherThrowDamagePhase_TrajectoryInfo
    local bowlderTrajectoryInfo = {
        totalTime = bowlderTime * 0.001,
        totalTimeMs = bowlderTime,
        targetRenderPos = bowlderTargetPos,
        currentTime = 0,
        trajectoryID = bowlderID,
        trajectoryEntity = bowlderEffectEntity,
        jumpHeight = bowlderJumpHeight
    }
    GameGlobal.TaskManager():CoreGameStartTask(self._DoJump, self, bowlderTrajectoryInfo)

    --光灵瞬移
    do
        
        local teleResults = result:GetTeleportResultArray()
        for index, skillResult in ipairs(teleResults) do
            local targetID = skillResult:GetTargetID()
            local targetEntity = self._world:GetEntityByID(targetID)
            self:_ResetScale(targetEntity)
            ---@type PlaySkillInstructionService
            local playSkillInstructionService = self._world:GetService("PlaySkillInstruction")
            --消失
            playSkillInstructionService:Teleport(TT, targetEntity, RoleShowType.TeleportHide, false, skillResult)
            ---瞬移
            playSkillInstructionService:Teleport(TT, targetEntity, RoleShowType.TeleportMove, false, skillResult)
            ---延时
            YIELD(TT, phaseParam.stealthDuration)
            ---出现
            playSkillInstructionService:Teleport(TT, targetEntity, RoleShowType.TeleportShow, false, skillResult)
            ---buff
            playSkillInstructionService:Teleport(TT, targetEntity, RoleShowType.BuffNotify, false, skillResult)
            ---显示动作和特效
            if phaseParam.appearAnimation then
                targetEntity:SetAnimatorControllerTriggers({phaseParam.appearAnimation})
            end
            if (phaseParam.appearEffectID) and (phaseParam.appearEffectID ~= 0) then
                effectService:CreateEffect(phaseParam.appearEffectID, targetEntity)
            end

            YIELD(TT, phaseParam.appearDuration)

            ---@type PieceServiceRender
            local pieceService = self._world:GetService("Piece")
            pieceService:RemovePrismAt(skillResult:GetPosNew())
        end
    end

    local teleportKillMonster = result:GetTeleportKillMonster()
    if #teleportKillMonster > 0 then--瞬移位置有怪 需要杀死
        local teleportKillMonsterEntitys = {}
        for _, monsterEntityID in ipairs(teleportKillMonster) do
            table.insert(teleportKillMonsterEntitys, self._world:GetEntityByID(monsterEntityID))
        end
        for _, eMonster in ipairs(teleportKillMonsterEntitys) do
            ---@type MonsterShowRenderService
            GameGlobal.TaskManager():CoreGameStartTask(function(TT)
                msrSvc:_DoOneMonsterDead(TT, eMonster)
            end)
        end
    end

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    playSkillService:ShowPlayerEntity(teamEntity)
    --伤害

    local hitAnimName = phaseParam:GetHitAnimationName()
    local hitFxID = phaseParam:GetHitEffectId()
    --local delayTime = phaseParam:GetHitDelayTime()
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
            --self:_PlayEffect(TT, posCast, posTarget, hitFxID, delayTime)

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
--实体移动、缩放、做动作 数据
function PlaySkillGatherThrowDamagePhase:_GenEntityFlyInfo(entityID,phaseParam,monsterTargetPos)
    local monsterFlyTime = phaseParam:GetMonsterFlyTotalTime()
    local minScale = phaseParam:GetMonsterMinScale()
    local monsterEntity = self._world:GetEntityByID(entityID)
    ---@class Internal_PlaySkillGatherThrowDamagePhase_TrajectoryInfo
    local trajectoryInfo = {
        totalTime = monsterFlyTime * 0.001,
        totalTimeMs = monsterFlyTime,
        targetRenderPos = monsterTargetPos,
        currentTime = 0,
        trajectoryID = entityID,
        trajectoryEntity = monsterEntity,
        minScale = minScale
    }
    return trajectoryInfo
end
---@param trajectoryInfo Internal_PlaySkillGatherThrowDamagePhase_TrajectoryInfo
function PlaySkillGatherThrowDamagePhase:_DoFly(TT, trajectoryInfo)
    local entity = trajectoryInfo.trajectoryEntity
    ---@type ViewComponent
    local effectViewCmpt = entity:View()
    ---@type UnityEngine.GameObject
    local effectObject = effectViewCmpt:GetGameObject()
    local posEffect = effectObject.transform.position
    local transWork = effectObject.transform

    ---隐藏血条
    local hpCmpt = entity:HP()
    if hpCmpt then
        local sliderEntityID = entity:HP():GetHPSliderEntityID()
        local sliderEntity = self._world:GetEntityByID(sliderEntityID)
        if sliderEntity then
            sliderEntity:SetViewVisible(false)
        end
    end
    local _easeWork =
        transWork:DOMove(trajectoryInfo.targetRenderPos, trajectoryInfo.totalTime, false):SetEase(
        DG.Tweening.Ease.InOutSine
    )
    transWork:DOScale(Vector3(trajectoryInfo.minScale, trajectoryInfo.minScale, trajectoryInfo.minScale), trajectoryInfo.totalTime)
    YIELD(TT, trajectoryInfo.totalTimeMs)
end
function PlaySkillGatherThrowDamagePhase:_ResetScale(entity)
    if entity then
        ---@type ViewComponent
        local effectViewCmpt = entity:View()
        ---@type UnityEngine.GameObject
        local effectObject = effectViewCmpt:GetGameObject()
        local transWork = effectObject.transform
        transWork.localScale = Vector3(1, 1, 1)
    end
end
function PlaySkillGatherThrowDamagePhase:_DoJump(TT, trajectoryInfo)
    local entity = trajectoryInfo.trajectoryEntity
    ---@type ViewComponent
    local effectViewCmpt = entity:View()
    ---@type UnityEngine.GameObject
    local effectObject = effectViewCmpt:GetGameObject()
    local posEffect = effectObject.transform.position
    local transWork = effectObject.transform
    local _easeWork =
        transWork:DOJump(trajectoryInfo.targetRenderPos, trajectoryInfo.jumpHeight, 1, trajectoryInfo.totalTime, false):SetEase(
        DG.Tweening.Ease.Linear
    )
    YIELD(TT, trajectoryInfo.totalTimeMs)
    --self._world:DestroyEntity(trajectoryInfo.trajectoryEntity)
end
