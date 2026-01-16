require "play_skill_phase_base_r"

---@class PlaySkillNightKingTeleportDamageWithPathPhase: PlaySkillPhaseBase
_class("PlaySkillNightKingTeleportDamageWithPathPhase", PlaySkillPhaseBase)
PlaySkillNightKingTeleportDamageWithPathPhase = PlaySkillNightKingTeleportDamageWithPathPhase

---@param phaseParam SkillPhaseNightKingTeleportDamageWithPathParam
---@param casterEntity Entity
function PlaySkillNightKingTeleportDamageWithPathPhase:PlayFlight(TT, casterEntity, phaseParam, phaseIndex, phaseAdapter)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---@type PlaySkillInstructionService
    local playSkillInstructionService = self._world:GetService("PlaySkillInstruction")
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_Teleport
    local skillResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Teleport)
    if not skillResult then
        return
    end
    local path = skillResult:GetRenderTeleportPath()--最后一步是冲到光灵附近
    if path and (#path > 0) then
    else
        return
    end
    local isFinalHit = false
    local skillID = skillEffectResultContainer:GetSkillID()
    local pathCount = #path
    local hasTrap = false
    if pathCount > 1 then
        hasTrap = true
    end
    local hasMultiTrap = false
    if pathCount > 2 then
        hasMultiTrap = true
    end
    --前摇 动作 特效
    --500ms后隐藏模型
    --如果有多个机关
        --从开始500ms后开始播第一个爪击，从开始900ms后第二个爪击，后每隔100ms播一个
        --最后一个爪击后400ms，播出现特效，100ms后出现，播动作

    --前摇
    local startAction = phaseParam:GetStartAction()
    if startAction then
        casterEntity:SetAnimatorControllerTriggers({startAction})
    end
    local startEffectID = phaseParam:GetStartEffectID()
    if startEffectID and (startEffectID ~= 0) then
        effectService:CreateEffect(startEffectID, casterEntity)
    end
    local firstTarPos = path[1]
    local startGridPos = casterEntity:GetRenderGridPosition()
    local startDir = firstTarPos - startGridPos
    casterEntity:SetDirection(startDir)
    local hideDelay = phaseParam:GetHideDelay()
    YIELD(TT,hideDelay)
    casterEntity:SetViewVisible(false)

    local lastPos = casterEntity:GetRenderGridPosition()
    
    
    if hasTrap then
        local firstDashPos = path[1]
        --第一个爪击
        self:_PlayDashToPos(TT,casterEntity,phaseParam,lastPos,firstDashPos)
        local damageIndex = 1
        local isMonsterFinalAttack = false
        self:_PlayDamageResult(TT,skillEffectResultContainer,damageIndex,casterEntity,phaseParam,isFinalHit,skillID,isMonsterFinalAttack)
        lastPos = firstDashPos
    end
    if hasMultiTrap then
        local secondDashDelay = phaseParam:GetSecondDashDelay()
        YIELD(TT,secondDashDelay)
        local dashInterval = phaseParam:GetDashInterval()
        local dashPathFinal = pathCount - 1
        for i = 2, dashPathFinal do
            local toPos = path[i]
            self:_PlayDashToPos(TT,casterEntity,phaseParam,lastPos,toPos)
            local damageIndex = i
            local isMonsterFinalAttack = false
            self:_PlayDamageResult(TT,skillEffectResultContainer,damageIndex,casterEntity,phaseParam,isFinalHit,skillID,isMonsterFinalAttack)
            lastPos = toPos
            if i ~= dashPathFinal then
                YIELD(TT,dashInterval)
            end
        end
    else
    end
    self:_PlayDestroyTraps(TT,skillEffectResultContainer)
    local showEffectDelay = phaseParam:GetShowEffectDelay()
    YIELD(TT,showEffectDelay)
    local finalDashPos = path[pathCount]
    local finalDir
    local showEffectID = phaseParam:GetShowEffectID()
    if showEffectID and (showEffectID ~= 0) then
        local teamEntity = self._world:Player():GetCurrentTeamEntity()
        local playerPos = teamEntity:GetGridPosition()
        local playerRenderPos = boardServiceRender:GridPos2RenderPos(playerPos)
        finalDir = playerPos - finalDashPos
        self:_PlayDashToPos(TT,casterEntity,phaseParam,lastPos,finalDashPos)
        local effectEntity = effectService:CreateWorldPositionDirectionEffect(showEffectID,finalDashPos,finalDir)
    end
    local showDelay = phaseParam:GetShowDelay()
    YIELD(TT,showDelay)
    ---瞬移
    playSkillInstructionService:Teleport(TT, casterEntity, RoleShowType.TeleportMove, false, skillResult)
    ---出现
    playSkillInstructionService:Teleport(TT, casterEntity, RoleShowType.TeleportShow, false, skillResult)
    ---buff
    playSkillInstructionService:Teleport(TT, casterEntity, RoleShowType.BuffNotify, false, skillResult)
    casterEntity:SetDirection(finalDir)
    casterEntity:SetViewVisible(true)
    local endAction = phaseParam:GetEndAction()
    if endAction then
        casterEntity:SetAnimatorControllerTriggers({endAction})
    end
    local damageIndex = pathCount
    local isMonsterFinalAttack = true
    self:_PlayDamageResult(TT,skillEffectResultContainer,damageIndex,casterEntity,phaseParam,isFinalHit,skillID,isMonsterFinalAttack)
    local finalDelay = phaseParam:GetFinalDelay()
    YIELD(TT,finalDelay)
end
---@param phaseParam SkillPhaseNightKingTeleportDamageWithPathParam
---@param damageResults SkillDamageEffectResult[]
---@param casterEntity Entity
function PlaySkillNightKingTeleportDamageWithPathPhase:_PlayDashToPos(TT, casterEntity, phaseParam,lastPos,toPos)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    local dir = toPos - lastPos
    local dis = Vector2.Distance(lastPos, toPos)
    local attackEffectID = phaseParam:GetAttackEffectID()
    if attackEffectID and attackEffectID ~= 0 then
        local effectEntity = effectService:CreateWorldPositionDirectionEffect(attackEffectID,lastPos,dir)
        -- if effectEntity then
        --     if dis <= 2 then
        --         effectEntity:SetScale(Vector3(1,1,0.6))
        --     else
        --         effectEntity:SetScale(Vector3(1,1,1))
        --     end
        -- end
    end
    ---摄像机特效
    local cameraEffID = phaseParam:GetAttackCameraEffectID()
    if cameraEffID and cameraEffID > 0 then
        ---@type Entity
        local cameraEffectEntity = effectService:CreateScreenEffPointEffect(cameraEffID)
    end
    local dashAudioID = phaseParam:GetDashAudioID()
    if dashAudioID then
        AudioHelperController.PlayInnerGameSfx(dashAudioID)
    end
    self:_SacrificeTrap(TT,casterEntity,toPos)
end

function PlaySkillNightKingTeleportDamageWithPathPhase:_SacrificeTrap(TT,casterEntity,pos)
    --吸收强化格子
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local destroyTrapResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.DestroyTrap)
    if destroyTrapResultArray and #destroyTrapResultArray > 0 then
        for index, destroyTrapResult in ipairs(destroyTrapResultArray) do
            local trapEntityID=  destroyTrapResult:GetEntityID()
            local trapEntity = self._world:GetEntityByID(trapEntityID)
            if trapEntity then
                local trapPos = trapEntity:GetGridPosition()
                if trapPos == pos then
                    trapEntity:SetViewVisible(false)
                    break
                end
            end
        end
    end
end
function PlaySkillNightKingTeleportDamageWithPathPhase:_PlayDamageResult(
    TT,
    skillEffectResultContainer,
    damageStageIndex,
    casterEntity,
    phaseParam,
    isFinalHit,
    nSkillID,
    isMonsterFinalAttack)
    ---@type SkillDamageEffectResult[]
    local damageResults = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage,damageStageIndex)
    if damageResults then
        for index, damageResult in ipairs(damageResults) do
            ---@type Entity
            local targetEntity = self._world:GetEntityByID(damageResult:GetTargetID())
            self:_PlayHitEffect(TT,casterEntity,targetEntity,phaseParam,damageResult,isFinalHit,nSkillID,isMonsterFinalAttack)
        end
    end
end
---@param phaseParam SkillPhaseNightKingTeleportDamageWithPathParam
function PlaySkillNightKingTeleportDamageWithPathPhase:_PlayHitEffect(
    TT,
    entityCast,
    entityTarget,
    phaseParam,
    result,
    isFinalHit,
    nSkillID,
    isMonsterFinalAttack)
    local hitAnimationName = phaseParam:GetBeHitAnimation()
    local hitEffectID = phaseParam:GetBeHitEffectID()
    if isMonsterFinalAttack then
        hitEffectID = phaseParam:GetFinalBeHitEffectID()
    end
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

    skillService:HandleBeHit(TT, beHitParam)
end
function PlaySkillNightKingTeleportDamageWithPathPhase:_PlayDestroyTraps(TT,skillEffectResultContainer)
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    ---@type SkillEffectDestroyTrapResult[]
    local destroyTrapResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.DestroyTrap)
    if destroyTrapResultArray and #destroyTrapResultArray > 0 then
        for index, destroyTrapResult in ipairs(destroyTrapResultArray) do
            local trapEntityID=  destroyTrapResult:GetEntityID()
            local eTrap = self._world:GetEntityByID(trapEntityID)
            local donotPlayDie = false
            trapServiceRender:PlayTrapDieSkill(TT, {eTrap},donotPlayDie)
        end
    end
end