require "play_skill_phase_base_r"
---
_class("PlaySkillControlMonsterMoveAttackSummonPhase", PlaySkillPhaseBase)
---@class PlaySkillControlMonsterMoveAttackSummonPhase: PlaySkillPhaseBase
PlaySkillControlMonsterMoveAttackSummonPhase = PlaySkillControlMonsterMoveAttackSummonPhase

function PlaySkillControlMonsterMoveAttackSummonPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillPhaseControlMonsterMoveAttackSummonParam
    local effectParam = phaseParam

    local stageIndex = effectParam:GetStageIndex()
    local moveSpeed = effectParam:GetMoveSpeed()
    local flyOneTime = effectParam:GetFlyOneTime()
    local teleportStartWaitTime = effectParam:GetTeleportStartWaitTime()
    local teleportAnim = effectParam:GetTeleportAnim()
    local teleportTime = effectParam:GetTeleportTime()
    local teleportFinishAnim = effectParam:GetTeleportFinishAnim()
    local teleportFinishWaitTime = effectParam:GetTeleportFinishWaitTime()
    local jumpEffectID = effectParam:GetJumpEffectID()
    local moveAnim = effectParam:GetMoveAnim()
    local moveEffectID = effectParam:GetMoveEffectID()

    self._turnToTarget = effectParam:GetTurnToTarget()
    self._hitAnimName = effectParam:GetHitAnimName()
    self._hitEffectID = effectParam:GetHitEffectID()
    self._casterEntity = casterEntity

    ---@type PlaySkillInstructionService
    local playSkillInstructionSvc = self._world:GetService("PlaySkillInstruction")
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    ---@type EffectService
    local effectService = self._world:GetService("Effect")

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    ---@type SkillEffectResultControlMonsterMove[]
    local skillEffectResultControlMonsterMove =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.ControlMonsterMove)

    if not skillEffectResultContainer then
        return
    end

    self._resultCount = table.count(skillEffectResultControlMonsterMove)

    ---@type SkillEffectResult_Teleport[]
    local skillEffectResult_Teleport =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Teleport, stageIndex)

    local summonTrapResultDic = {}
    ---@type SkillSummonTrapEffectResult[]
    local skillSummonTrapEffectResult =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SummonTrap, stageIndex)
    for _, result in pairs(skillSummonTrapEffectResult) do
        ---@type SkillSummonTrapEffectResult
        local summonTrapResult = result
        local summonPos = summonTrapResult:GetPos()
        local posIndex = Vector2.Pos2Index(summonPos)
        summonTrapResultDic[posIndex] = summonTrapResult
    end

    local damageResultDic = {}
    ---@type SkillDamageEffectResult[]
    local SkillDamageEffectResult = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
    if SkillDamageEffectResult and table.count(SkillDamageEffectResult) > 0 then
        for _, result in pairs(SkillDamageEffectResult) do
            ---@type SkillDamageEffectResult
            local damageResult = result
            local damageGridPos = damageResult:GetGridPos()
            local casterID = damageResult:GetCasterID()
            local posIndex = Vector2.Pos2Index(damageGridPos)

            table.insert(damageResultDic, {casterID = casterID, posIndex = posIndex, damageResult = damageResult})
        end
    end

    YIELD(TT, teleportStartWaitTime)

    --用于表现的假的技能结果
    local fakeTeleportSkillResult = {}

    local jumpEffectList = {}

    for _, v in ipairs(skillEffectResultControlMonsterMove) do
        ---@type SkillEffectResultControlMonsterMove
        local skillEffectResult = v

        local entityID = skillEffectResult:GetCasterEntityID()
        local posStart = skillEffectResult:GetPosStart()
        local posMiddle = skillEffectResult:GetPosMiddle()
        local posEnd = skillEffectResult:GetPosEnd()

        --需要中转坐标的怪物
        if posStart ~= posMiddle then
            local targetEntity = self._world:GetEntityByID(entityID)
            targetEntity:SetAnimatorControllerTriggers({teleportAnim})

            renderEntityService:DestroyMonsterAreaOutLineEntity(targetEntity)
            self:_PlayCasterControlGridDown(targetEntity, 0)

            local distance = Vector2.Distance(posStart, posMiddle)
            local speed = distance / teleportTime * 1000

            targetEntity:AddGridMove(speed, posMiddle, posStart)

            ---@type Entity
            local effect = effectService:CreateEffect(jumpEffectID, targetEntity)
            table.insert(jumpEffectList, effect)
        end
    end

    YIELD(TT, teleportTime + teleportFinishWaitTime)

    for _, effectEntity in ipairs(jumpEffectList) do
        self._world:DestroyEntity(effectEntity)
    end

    local moveEffectList = {}
    --统一朝向新目标
    for _, v in ipairs(skillEffectResultControlMonsterMove) do
        ---@type SkillEffectResultControlMonsterMove
        local skillEffectResult = v

        local entityID = skillEffectResult:GetCasterEntityID()
        local posStart = skillEffectResult:GetPosStart()
        local posMiddle = skillEffectResult:GetPosMiddle()
        local posEnd = skillEffectResult:GetPosEnd()
        local dirNew = skillEffectResult:GetDir()

        local dis = tonumber(Vector2.Distance(posMiddle, posEnd))

        local targetEntity = self._world:GetEntityByID(entityID)
        targetEntity:SetDirection(dirNew)
        targetEntity:AddGridMove(moveSpeed, posEnd, posMiddle)
        targetEntity:SetAnimatorControllerTriggers({moveAnim})

        renderEntityService:DestroyMonsterAreaOutLineEntity(targetEntity)
        self:_PlayCasterControlGridDown(targetEntity, 0)

        ---@type Entity
        local effect = effectService:CreateEffect(moveEffectID, targetEntity)
        table.insert(moveEffectList, effect)

        GameGlobal.TaskManager():CoreGameStartTask(
            function()
                for i = 0, dis do
                    local curPos = posMiddle + Vector2(dirNew.x * i, dirNew.y * i)
                    local posIndex = Vector2.Pos2Index(curPos)

                    ---@type SkillSummonTrapEffectResult
                    local summonTrapResult = summonTrapResultDic[posIndex]
                    if summonTrapResult then
                        local trapIDList = summonTrapResult:GetTrapIDList()
                        for i = 1, #trapIDList do
                            ---@type Entity
                            local trapEntity = self._world:GetEntityByID(trapIDList[i])
                            trapServiceRender:CreateSingleTrapRender(TT, trapEntity, true)
                            trapEntity:SetPosition(Vector2(summonTrapResult:GetPos().x, summonTrapResult:GetPos().y))
                        end

                        summonTrapResultDic[posIndex] = nil
                    end

                    for _, v in ipairs(damageResultDic) do
                        local damageCasterID = v.casterID
                        local damagePosIndex = v.posIndex
                        local damageResult = v.damageResult
                        if damageCasterID == entityID and damagePosIndex == posIndex then
                            self:_OnPlayHit(TT, damageResult)
                        end
                    end

                    YIELD(TT, flyOneTime)
                    --走过一个格子以后  召唤机关
                end
            end
        )
    end

    YIELD(TT, 1000)

    for _, effectEntity in ipairs(moveEffectList) do
        self._world:DestroyEntity(effectEntity)
    end

    for _, v in ipairs(skillEffectResultControlMonsterMove) do
        ---@type SkillEffectResultControlMonsterMove
        local skillEffectResult = v
        local entityID = skillEffectResult:GetCasterEntityID()
        local targetEntity = self._world:GetEntityByID(entityID)
        targetEntity:SetAnimatorControllerTriggers({"Idle"})
    end

    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    --冲刺结束后
    --用真实的瞬移数据，触发机关，发送通知
    for _, result in pairs(skillEffectResult_Teleport) do
        local targetEntityID = result:GetTargetID()
        local targetEntity = self._world:GetEntityByID(targetEntityID)

        local posOld = result:GetPosOld()
        local posNew = result:GetPosNew()

        targetEntity:SetPosition(posNew)

        local trapIDList = result:GetTriggerTrapIDList()
        local trapEntityList = {}
        for _, v in ipairs(trapIDList) do
            local trapEntity = self._world:GetEntityByID(v)
            trapEntityList[#trapEntityList + 1] = trapEntity
        end

        playSkillInstructionSvc:PlayTrapTrigger(TT, targetEntity, trapEntityList)

        renderEntityService:DestroyMonsterAreaOutLineEntity(targetEntity)
        renderEntityService:CreateMonsterAreaOutlineEntity(targetEntity)
        self:_PlayCasterControlGridDown(targetEntity, 1)

        playBuffSvc:PlayBuffView(TT, NTTeleport:New(casterEntity, posOld, posNew))
    end

    -- ---@type PieceServiceRender
    -- local pieceService = self._world:GetService("Piece")
    --设置怪物脚底暗色  刷新红线
    -- pieceService:RefreshPieceAnim()
    -- pieceService:RefreshMonsterAreaOutLine(TT)

    YIELD(TT)
end

---
function PlaySkillControlMonsterMoveAttackSummonPhase:_OnPlayHit(TT, damageResult)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = self._casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()

    ---@type DamageInfo
    local damageInfo = damageResult:GetDamageInfo(1)
    local targetEntity = self._world:GetEntityByID(damageResult:GetTargetID())
    local damageGridPos = damageResult:GetGridPos()

    local playFinalAttack = false

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    ---调用统一处理被击的逻辑
    local beHitParam =
        HandleBeHitParam:New():SetHandleBeHitParam_CasterEntity(self._casterEntity):SetHandleBeHitParam_TargetEntity(
        targetEntity
    ):SetHandleBeHitParam_HitAnimName(self._hitAnimName):SetHandleBeHitParam_HitEffectID(self._hitEffectID):SetHandleBeHitParam_DamageInfo(
        damageInfo
    ):SetHandleBeHitParam_DamagePos(damageGridPos):SetHandleBeHitParam_HitTurnTarget(self._turnToTarget):SetHandleBeHitParam_DeathClear(
        0
    ):SetHandleBeHitParam_IsFinalHit(playFinalAttack):SetHandleBeHitParam_SkillID(skillID)
    playSkillService:HandleBeHit(TT, beHitParam)
end

function PlaySkillControlMonsterMoveAttackSummonPhase:_PlayCasterControlGridDown(casterEntity, enable)
    if casterEntity:MonsterID() then
        ---@type MonsterIDComponent
        local monsterIDCmpt = casterEntity:MonsterID()
        monsterIDCmpt:SetNeedGridDownEnable(enable == 1)
    elseif casterEntity:HasTrapID() then
        ---@type TrapRenderComponent
        local trapRender = casterEntity:TrapRender()
        trapRender:SetNeedGridDownEnable(enable == 1)
    else
        return
    end
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type BodyAreaComponent
    local bodyAreaCmpt = casterEntity:BodyArea()
    local areaArray = bodyAreaCmpt:GetArea()
    ---@type PieceServiceRender
    local pieceSvc = world:GetService("Piece")
    local monsterGridPos = casterEntity:GetRenderGridPosition()
    for i = 1, #areaArray do
        local curAreaPos = areaArray[i]
        local pos = Vector2(curAreaPos.x + monsterGridPos.x, curAreaPos.y + monsterGridPos.y)
        if enable == 1 then
            pieceSvc:SetPieceAnimDark(pos)
        else
            pieceSvc:SetPieceAnimNormal(pos)
        end
    end
end
