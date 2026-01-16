require "play_skill_phase_base_r"

---@class PlaySkillPetANaTuoLiTractionPhase: PlaySkillPhaseBase
_class("PlaySkillPetANaTuoLiTractionPhase", PlaySkillPhaseBase)
PlaySkillPetANaTuoLiTractionPhase = PlaySkillPetANaTuoLiTractionPhase

---@param phaseParam SkillPhasePetANaTuoLiTractionParam
---@param casterEntity Entity
function PlaySkillPetANaTuoLiTractionPhase:PlayFlight(TT, casterEntity, phaseParam, phaseIndex, phaseAdapter)
    local world = self._world
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectMultiTractionResult
    local tractionResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.MultiTraction)
    local taskIDs = {}
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    ---@type EffectService
    local effectService = world:GetService("Effect")
    ---@type RenderEntityService
    local entityRenderService = world:GetService("RenderEntity")
    ---@type PieceServiceRender
    local pieceService = world:GetService("Piece")


    --光灵 动作、特效
    local casterAction = phaseParam:GetCasterAction()
    local casterEffectID = phaseParam:GetCasterEffectID()
    if casterAction then
        casterEntity:SetAnimatorControllerTriggers({casterAction})
    end
    if casterEffectID then
        effectService:CreateEffect(casterEffectID, casterEntity)
    end
    local casterPos = casterEntity:GetRenderGridPosition()

    --有没有牵引 特效表现都一样，没有牵引时（只点了一个点，且不能以自身为另一个点）额外处理
    local scopeCenterPos
    local tractionCenterPos
    if tractionResult then--低练度时只点一个点，也会有牵引结果，只是没有牵引数据
        ---@type SkillScopeResult
        local tractionScopeResult = tractionResult:GetSkillEffectScopeResult()
        tractionCenterPos = tractionResult:GetTractionCenterPos()
        scopeCenterPos = tractionScopeResult:GetCenterPos()
        --牵引过程
        local taskID = GameGlobal.TaskManager():CoreGameStartTask(self._PlayTraction, self, casterEntity,tractionResult,phaseParam)
        table.insert(taskIDs, taskID)
    else
        --临时
        local targetPos = Vector2(5,6)
        scopeCenterPos = {casterPos,targetPos}
        tractionCenterPos = Vector2(5,5)
    end
    --牵引中心点特效
    casterEntity:SetDirection(tractionCenterPos - casterPos)
    
    local tractionCenterEffectDelayMs = phaseParam:GetTractionCenterEffectDelayMs()
    YIELD(TT,tractionCenterEffectDelayMs)
    local tractionCenterEffectID = phaseParam:GetTractionCenterEffectID()
    effectService:CreateWorldPositionEffect(tractionCenterEffectID, tractionCenterPos)
    --从牵引中心点到范围中心点（两个点选怪的位置，或怪和光灵的位置）
    local tractionChaseEffectID = phaseParam:GetTractionChaseEffectID()
    local tractionChaseEffectTimeMs = phaseParam:GetTractionChaseEffectTimeMs()
    local chaseEffectTaskIDs = {}
    for index, targetPos in ipairs(scopeCenterPos) do
        local effectEntity = effectService:CreatePositionEffect(tractionChaseEffectID, tractionCenterPos)
        local effectDir = targetPos - tractionCenterPos
        if effectEntity then
            effectEntity:SetDirection(effectDir)
        end
        local targetRenderPos = boardServiceRender:GridPos2RenderPos(targetPos)
        ---@class Internal_PlaySkillPetANaTuoLiTractionPhase_TrajectoryInfo
        local trajectoryInfo = {
            startHeight = 0,
            endHeight = 0,
            totalTime = tractionChaseEffectTimeMs * 0.001,
            totalTimeMs = tractionChaseEffectTimeMs,
            targetRenderPos = targetRenderPos,
            trajectoryEntity = effectEntity,
        }

        table.insert(chaseEffectTaskIDs, GameGlobal.TaskManager():CoreGameStartTask(self._DoFly, self, trajectoryInfo))
    end
    while not TaskHelper:GetInstance():IsAllTaskFinished(chaseEffectTaskIDs) do
        YIELD(TT)
    end

    local tractionPushEffectID = phaseParam:GetTractionPushEffectID()
    local tractionPushEffectMoveTimeMs = phaseParam:GetTractionPushEffectMoveTimeMs()
    local pushTrajectoryArray = {}
    --在范围中心点（怪脚下）播手特效（调整朝向）
    for index, targetPos in ipairs(scopeCenterPos) do
        local effectEntity = effectService:CreatePositionEffect(tractionPushEffectID, targetPos)
        local effectDir = tractionCenterPos - targetPos
        if effectEntity then
            effectEntity:SetDirection(effectDir)
        end
        local targetRenderPos = boardServiceRender:GridPos2RenderPos(tractionCenterPos)
        ---@class Internal_PlaySkillPetANaTuoLiTractionPhase_TrajectoryInfo
        local trajectoryInfo = {
            startHeight = 0,
            endHeight = 0,
            totalTime = tractionPushEffectMoveTimeMs * 0.001,
            totalTimeMs = tractionPushEffectMoveTimeMs,
            targetRenderPos = targetRenderPos,
            trajectoryEntity = effectEntity,
        }
        table.insert(pushTrajectoryArray,trajectoryInfo)
    end
    local tractionPushEffectHoldTimeMs = phaseParam:GetTractionPushEffectHoldTimeMs()
    YIELD(TT,tractionPushEffectHoldTimeMs)
    --手特效移动
    local pushTrajectoryTaskIDs = {}
    for index, trajectoryInfo in ipairs(pushTrajectoryArray) do
        table.insert(pushTrajectoryTaskIDs, GameGlobal.TaskManager():CoreGameStartTask(self._DoFly, self, trajectoryInfo))
    end
    while not TaskHelper:GetInstance():IsAllTaskFinished(chaseEffectTaskIDs) do
        YIELD(TT)
    end
    --牵引中心点爆炸
    local tractionBoomEffectID = phaseParam:GetTractionBoomEffectID()
    effectService:CreatePositionEffect(tractionBoomEffectID, tractionCenterPos)

    --伤害
    local damageIndex = 1
    local isFinalHit = false
    local skillID = skillEffectResultContainer:GetSkillID()
    self:_PlayDamageResult(TT,skillEffectResultContainer,damageIndex,casterEntity,phaseParam,isFinalHit,skillID)

    while (not TaskHelper:GetInstance():IsAllTaskFinished(taskIDs)) do
        YIELD(TT)
    end

    local finalWaitTimeMs = phaseParam:GetFinalWaitTimeMs()
    YIELD(TT,finalWaitTimeMs)    
    return
end
---@param phaseParam SkillPhasePetANaTuoLiTractionParam
function PlaySkillPetANaTuoLiTractionPhase:_PlayTraction(TT, casterEntity, tractionResult, phaseParam)
    if tractionResult then
        local taskIDs = {}
        local world = self._world
        ---@type BoardServiceRender
        local boardServiceRender = world:GetService("BoardRender")
        ---@type EffectService
        local effectService = world:GetService("Effect")
        ---@type RenderEntityService
        local entityRenderService = world:GetService("RenderEntity")
        ---@type PieceServiceRender
        local pieceService = world:GetService("Piece")
        local playTractionDelayMs = phaseParam:GetPlayTractionDelayMs()
        YIELD(TT,playTractionDelayMs)

        local tractionTargetEffectID = phaseParam:GetTractionTargetEffectID()
        local tractionMoveTimeMs = phaseParam:GetTractionMoveTimeMs()
        local tractionMoveAction = phaseParam:GetTractionMoveAction()
        --牵引过程
        ---@type SkillEffectCalc_MultiTraction_SingleTargetResult[]
        local singleTractionArray = tractionResult:GetResultArray()

        local teamTractionData
        local teamEntity

        for _, info in ipairs(singleTractionArray) do
            local entity = world:GetEntityByID(info.entityID)
            if entity then
                local currentPos = boardServiceRender:GetRealEntityGridPos(entity)
                if tractionTargetEffectID and tractionTargetEffectID > 0 and (info.beginPos ~= info.finalPos) then
                    effectService:CreateEffect(tractionTargetEffectID, entity)
                end
                if info.beginPos ~= info.finalPos then
                    entity:SetDirection(info.finalPos - currentPos)
                    --entity:SetAnimatorControllerBools({[BattleConst.DefaultMovementAnimatorBool] = true})
                    if tractionMoveAction then
                        entity:SetAnimatorControllerBools({[tractionMoveAction] = true})
                    end
                end
                local moveDis = Vector2.Distance(info.finalPos,info.beginPos)
                local tractionMoveSpeed = moveDis / (tractionMoveTimeMs*0.001)
                local gridPos = boardServiceRender:GetRealEntityGridPos(entity)
                entity:AddGridMove(tractionMoveSpeed, info.finalPos, gridPos)

                entityRenderService:DestroyMonsterAreaOutLineEntity(entity)
                pieceService:RefreshMonsterPiece(entity, true)
                local taskID = GameGlobal.TaskManager():CoreGameStartTask(self._CheckMoveFinish, self, entity,tractionMoveAction)
                table.insert(taskIDs, taskID)

                -- 队长出发瞬间把原点格刷新
                if entity:HasTeam() then
                    teamTractionData = info
                    teamEntity = entity
                    local supply = tractionResult:GetSupplyPlayerPiece()
                    if supply then
                        boardServiceRender:ReCreateGridEntity(supply.color, info.beginPos)
                        ---@type PlaySkillService
                        local playSkillSvc = world:GetService("PlaySkill")
                        ---@type PlayBuffService
                        local svcPlayBuff = world:GetService("PlayBuff")
                        svcPlayBuff:_SendNTGridConvertRender(TT, info.beginPos, supply.color, SkillEffectType.MultiTraction)
                        local colorNew = tractionResult:GetColorNew()
                        boardServiceRender:ReCreateGridEntity(colorNew, info.finalPos)
                    end
                end
                ---@type PlayBuffService
                local svcPlayBuff = self._world:GetService("PlayBuff")
                svcPlayBuff:PlayBuffView(TT, NTTractionEnd:New(casterEntity, entity, info.beginPos, info.finalPos))
            end
        end

        while (not TaskHelper:GetInstance():IsAllTaskFinished(taskIDs)) do
            YIELD(TT)
        end

        -- 队长被移到位置之后，将新的脚下置灰
        if teamTractionData then
            local posOld = teamTractionData.beginPos
            local posNew = teamTractionData.finalPos

            local pets = teamEntity:Team():GetTeamPetEntities()
            ---@param petEntity Entity
            for i, petEntity in ipairs(pets) do
                petEntity:SetLocation(posNew)
            end

            teamEntity:SetLocation(posNew)
            boardServiceRender:ReCreateGridEntity(PieceType.None, posNew)
        end

        if tractionTargetEffectID > 0 then
            effectService:DestroyEffectByID(tractionTargetEffectID)
        end

        -- 触发型机关的触发
        ---@type TrapServiceRender
        local trapServiceRender = world:GetService("TrapRender")
        for _, info in ipairs(singleTractionArray) do
            local entity = world:GetEntityByID(info.entityID)
            if entity and (info.beginPos ~= info.finalPos) then -- 没能移动的目标不会重复触发机关
                local listTrapTrigger = info:GetTriggerTraps()
                trapServiceRender:PlayTrapTriggerSkillTasks(TT, listTrapTrigger, false, entity)
            end
        end
    end
end
---@param entity Entity
function PlaySkillPetANaTuoLiTractionPhase:_CheckMoveFinish(TT, entity, tractionMoveAction)
    while (entity:HasGridMove()) do
        YIELD(TT)
    end

    ---@type MainWorld
    local world = entity:GetOwnerWorld()
    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")

    ---@type PieceServiceRender
    local pieceService = world:GetService("Piece")

    local realPos = boardServiceRender:GetRealEntityGridPos(entity)

    ---@type RenderEntityService
    local entityRenderService = world:GetService("RenderEntity")
    pieceService:RefreshMonsterPiece(entity, false)
    entityRenderService:CreateMonsterAreaOutlineEntity(entity)
    trapServiceRender:ShowHideTrapAtPos(realPos, false)
    --entity:SetAnimatorControllerBools({[BattleConst.DefaultMovementAnimatorBool] = false})
    if tractionMoveAction then
        entity:SetAnimatorControllerBools({[tractionMoveAction] = false})
    end
end
---@param trajectoryInfo Internal_PlaySkillPetANaTuoLiTractionPhase_TrajectoryInfo
function PlaySkillPetANaTuoLiTractionPhase:_DoFly(TT, trajectoryInfo)
    ---@type Entity
    local entity = trajectoryInfo.trajectoryEntity
    ---@type ViewComponent
    local effectViewCmpt = entity:View()
    ---@type UnityEngine.GameObject
    local effectObject = effectViewCmpt:GetGameObject()
    local transWork = effectObject.transform

    local easeWork = transWork:DOMove(trajectoryInfo.targetRenderPos, trajectoryInfo.totalTime, false):SetEase(
        DG.Tweening.Ease.InOutSine
    )

    YIELD(TT, trajectoryInfo.totalTimeMs)
    ---@type MainWorld
    --local world = entity:GetOwnerWorld()
    --world:DestroyEntity(entity)
end
---@param phaseParam SkillPhasePetANaTuoLiTractionParam
function PlaySkillPetANaTuoLiTractionPhase:_PlayDamageResult(
    TT,
    skillEffectResultContainer,
    damageStageIndex,
    casterEntity,
    phaseParam,
    isFinalHit,
    nSkillID)
    ---@type SkillDamageEffectResult[]
    local damageResults = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage,damageStageIndex)
    for index, damageResult in ipairs(damageResults) do
        ---@type Entity
        local targetEntity = self._world:GetEntityByID(damageResult:GetTargetID())
        self:_PlayHitEffect(TT,casterEntity,targetEntity,phaseParam,damageResult,isFinalHit,nSkillID)
    end
end
---@param phaseParam SkillPhasePetANaTuoLiTractionParam
function PlaySkillPetANaTuoLiTractionPhase:_PlayHitEffect(
    TT,
    entityCast,
    entityTarget,
    phaseParam,
    result,
    isFinalHit,
    nSkillID)
    local hitAnimationName = phaseParam:GetBeHitAnimation()
    local hitEffectID = phaseParam:GetBeHitEffectID()
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
        :SetHandleBeHitParam_DeathClear(false)
        :SetHandleBeHitParam_IsFinalHit(isFinalHit)
        :SetHandleBeHitParam_SkillID(nSkillID)
    local hitTaskID = TaskManager:GetInstance():CoreGameStartTask(skillService.HandleBeHit,skillService,beHitParam)
    --skillService:HandleBeHit(TT, beHitParam)
end