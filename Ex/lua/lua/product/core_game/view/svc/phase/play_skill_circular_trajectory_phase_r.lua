require "play_skill_phase_base_r"
---
_class("PlaySkillCircularTrajectoryPhase", PlaySkillPhaseBase)
---@class PlaySkillCircularTrajectoryPhase: PlaySkillPhaseBase
PlaySkillCircularTrajectoryPhase = PlaySkillCircularTrajectoryPhase

function PlaySkillCircularTrajectoryPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseCircularTrajectoryParam
    local effectParam = phaseParam

    local effectID = effectParam:GetEffectID()
    local spawnRadiusMin = effectParam:GetSpawnRadiusMin()
    local spawnRadiusMax = effectParam:GetSpawnRadiusMax()
    local spawnIntervalTime = effectParam:GetSpawnIntervalTime()
    local spawnCenterBone = effectParam:GetSpawnCenterBone()
    local oneArrowOffset = effectParam:GetOneArrowOffset()

    local waitFireTime = effectParam:GetWaitFireTime()

    local flyTime = effectParam:GetFlyTime()
    self._destroyBulletDelay = effectParam:GetdestroyBulletDelay()

    local targetHit = effectParam:GetTargetHit()
    self._turnToTarget = effectParam:GetTurnToTarget()
    self._hitAnimName = effectParam:GetHitAnimName()
    self._hitEffectID = effectParam:GetHitEffectID()
    self._casterEntity = casterEntity

    -----------------------------------------------------------------------------

    local listTask = {}

    -- ---@type  UnityEngine.Vector2
    -- local castPos = casterEntity:GetRenderGridPosition()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)

    --检测是否有攻击目标 没有就返回
    if damageResultArray == nil then
        return
    end

    local beAttackEntityID = damageResultArray[1]:GetTargetID()
    ---@type Entity
    local targetEntity = self._world:GetEntityByID(beAttackEntityID)
    if not targetEntity then
        return
    end

    ---@type Vector3
    local casterDir = casterEntity:GetDirection()

    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type EffectService
    local effectService = world:GetService("Effect")
    ---@type PlaySkillService
    local playSkillService = world:GetService("PlaySkill")

    ---@type TimeService
    local timeService = self._world:GetService("Time")
    local startTime = timeService:GetCurrentTimeMs()

    --计算目标位置
    local targetBoneTransform = playSkillService:GetEntityRenderSelectBoneTransform(targetEntity, targetHit)

    local damageCount = table.count(damageResultArray)
    self._eftEntityList = {}

    for i, damageResult in ipairs(damageResultArray) do
        -- local pos1 = UnityEngine.Random.insideUnitCircle * spawnRadiusMin
        -- local pos2 = pos1.normalized * (spawnRadiusMax + pos1.magnitude)

        --计算目标位置
        local casterBoneTransform = playSkillService:GetEntityRenderSelectBoneTransform(casterEntity, spawnCenterBone)

        local curAngle = self:_OnGetRandomAngle(i, damageCount)
        local curRotation = Quaternion.AngleAxis(curAngle, casterDir)
        local curDistance = math.random(spawnRadiusMin * 1000, spawnRadiusMax * 1000) / 1000

        --
        local posWork = casterBoneTransform.position + (curRotation * Vector3.up * curDistance)
        if damageCount == 1 then
            posWork = casterEntity:View():GetGameObject().transform:TransformPoint(oneArrowOffset)
        end

        ---@type Entity
        local eftEntity = effectService:CreatePositionEffect(effectID, posWork)
        local go = eftEntity:View():GetGameObject()

        local dir = targetBoneTransform.position - go.transform.position
        eftEntity:SetDirection(dir)

        table.insert(self._eftEntityList, eftEntity)

        GameGlobal.TaskManager():CoreGameStartTask(
            function(TT)
                YIELD(TT, waitFireTime)

                ---@type UnityEngine.Transform
                local trajectoryObject = eftEntity:View():GetGameObject()
                local transWork = trajectoryObject.transform
                transWork:DOMove(targetBoneTransform.position, flyTime / 1000, false):SetEase(DG.Tweening.Ease.Linear)

                YIELD(TT, flyTime)

                local playFinalAttack = (i == damageCount)

                self:_OnPlayHit(TT, damageResult, eftEntity, playFinalAttack)
            end
        )

        YIELD(TT, spawnIntervalTime)
    end

    -- YIELD(TT, waitFireTime)

    -- -- for _, eftEntity in ipairs(self._eftEntityList) do
    -- for i, damageResult in ipairs(damageResultArray) do
    --     local effectEntity = self._eftEntityList[i]
    --     ---@type UnityEngine.Transform
    --     local trajectoryObject = effectEntity:View():GetGameObject()
    --     local transWork = trajectoryObject.transform
    --     transWork:DOMove(targetBoneTransform.position, flyTime / 1000, false):SetEase(DG.Tweening.Ease.Linear)
    --     GameGlobal.TaskManager():CoreGameStartTask(
    --         function(TT)
    --             YIELD(TT, flyTime)

    --             local playFinalAttack = (i == damageCount)

    --             self:_OnPlayHit(TT, damageResult, effectEntity, playFinalAttack)
    --         end
    --     )
    --     YIELD(TT, spawnIntervalTime)
    -- end

    ----

    while table.count(self._eftEntityList) > 0 do
        YIELD(TT)
    end

    YIELD(TT)
end

---
function PlaySkillCircularTrajectoryPhase:_OnGetRandomAngle(index, count)
    local angleEcah = math.floor(360 / count)
    local angleMin = angleEcah * (index - 1)
    local angleMax = angleEcah * index
    local angle = math.random(angleMin, angleMax)

    if (angle >= 0 and angle <= 10) or (angle >= 350 and angle <= 360) or (angle >= 170 and angle <= 190) then
        return self:_OnGetRandomAngle(index, count)
    end
    return angle
end

---
function PlaySkillCircularTrajectoryPhase:_OnPlayHit(TT, damageResult, effectEntity, finalAttack)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = self._casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()

    ---@type DamageInfo
    local damageInfo = damageResult:GetDamageInfo(1)
    local targetEntity = self._world:GetEntityByID(damageResult:GetTargetID())
    local damageGridPos = damageResult:GetGridPos()

    local playFinalAttack = false
    if skillEffectResultContainer:IsFinalAttack() and finalAttack then
        playFinalAttack = true
    end

    local isPetShadow = (self._casterEntity:EntityType() and self._casterEntity:EntityType():IsPetShadow())
    if isPetShadow then
        --处理分身放连锁，取本体Entity 和 SkillID
        ---@type PetShadowRenderComponent
        local petShadowRenderComponent = self._casterEntity:PetShadowRender()
        local ownerEntityID = petShadowRenderComponent:GetOwnerEntityID()
        local ownerEntity = self._world:GetEntityByID(ownerEntityID)
        self._casterEntity = ownerEntity
        ---@type SkillEffectResultContainer
        skillEffectResultContainer = self._casterEntity:SkillRoutine():GetResultContainer()
        skillID = skillEffectResultContainer:GetSkillID()
    end

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

    YIELD(TT, self._destroyBulletDelay)
    table.removev(self._eftEntityList, effectEntity)
    self._world:DestroyEntity(effectEntity)
end
