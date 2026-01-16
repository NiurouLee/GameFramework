require("base_ins_r")
---@class PlayThrowMonsterAndDamageInstruction : BaseInstruction
_class("PlayThrowMonsterAndDamageInstruction", BaseInstruction)
PlayThrowMonsterAndDamageInstruction = PlayThrowMonsterAndDamageInstruction

function PlayThrowMonsterAndDamageInstruction:Constructor(paramList)
    self._hitAnimName = paramList.hitAnim
    self._hitEffectID = tonumber(paramList.hitEffectID)

    self._dieEffectID = tonumber(paramList.dieEffectID)
    self._trajectoryDelayTime = tonumber(paramList.trajectoryDelayTime) or 0

    self._flyDelay = tonumber(paramList.flyDelay) or 0
    self._trajectoryID = tonumber(paramList.trajectoryID)
    self._startHeight = tonumber(paramList.startHeight)
    self._endHeight = tonumber(paramList.endHeight)
    self._flyTotalTime = tonumber(paramList.flyTotalTime) or 0
    self._eachFlyDelayTime = tonumber(paramList.eachFlyDelayTime) or 0
end

function PlayThrowMonsterAndDamageInstruction:GetCacheResource()
    local t = {}
    if self._hitEffectID and self._hitEffectID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._hitEffectID].ResPath, 1 })
    end
    if self._dieEffectID and self._dieEffectID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._dieEffectID].ResPath, 1 })
    end
    if self._trapTrajectoryID and self._trapTrajectoryID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._trapTrajectoryID].ResPath, 1 })
    end
    return t
end

---@param casterEntity Entity
function PlayThrowMonsterAndDamageInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local resultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectThrowMonsterAndDamageResult
    local result = resultContainer:GetEffectResultByArray(SkillEffectType.ThrowMonsterAndDamage)
    if not result then
        return
    end

    --取目标位置
    ---@type SkillDamageEffectResult
    local damageResult = result:GetDamageResult()
    if not damageResult then
        return
    end

    local damagePos = damageResult:GetGridPos()
    local targetEntityID = damageResult:GetTargetID()
    local targetEntity = world:GetEntityByID(targetEntityID)
    local targetPos = Vector2.New(damagePos.x, damagePos.y)
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    targetPos = boardServiceRender:GridPos2RenderPos(Vector2.New(targetPos.x + 0.5, targetPos.y + 0.5))
    targetPos.y = targetPos.y + self._endHeight

    ---@type EffectService
    local effectService = world:GetService("Effect")
    ---@type MonsterShowRenderService
    local msrSvc = world:GetService("MonsterShowRender")

    local monsterIDArray = result:GetMonsterEntityIDs()
    for _, entityID in ipairs(monsterIDArray) do
        local entity = world:GetEntityByID(entityID)
        --隐藏怪物的血条
        ---@type HPComponent
        local hpComponent = entity:HP()
        if hpComponent then
            local sliderEntityId = hpComponent:GetHPSliderEntityID()
            local sliderEntity = world:GetEntityByID(sliderEntityId)
            if sliderEntity then
                sliderEntity:SetViewVisible(false)
            end
        end
    end

    local trapTaskIDs = {}
    for _, entityID in ipairs(monsterIDArray) do
        local monsterEntity = world:GetEntityByID(entityID)
        --播放怪物死亡
        GameGlobal.TaskManager():CoreGameStartTask(function(TT)
            msrSvc:PlayOneMonsterSpDead(TT, monsterEntity)
        end)

        local entityPos = boardServiceRender:GetRealEntityGridPos(monsterEntity)
        local effectDir = damagePos - entityPos
        local beginPos = boardServiceRender:GridPos2RenderPos(entityPos)
        local deadEffectEntity = effectService:CreatePositionEffect(self._dieEffectID, beginPos)
        if deadEffectEntity then
            deadEffectEntity:SetDirection(effectDir)
        end
        monsterEntity:SetViewVisible(false)
        YIELD(TT, self._trajectoryDelayTime)

        beginPos.y = beginPos.y + self._startHeight
        local effectEntity = effectService:CreatePositionEffect(self._trajectoryID, beginPos)
        if effectEntity then
            effectEntity:SetDirection(effectDir)
        end
        ---@class Internal_PlayThrowMonsterAndDamageInstruction_TrajectoryInfo
        local trajectoryInfo = {
            startHeight = self._startHeight,
            endHeight = self._endHeight,
            totalTime = self._flyTotalTime * 0.001,
            totalTimeMs = self._flyTotalTime,
            targetRenderPos = targetPos,
            currentTime = 0,
            trajectoryID = self._trajectoryID,
            trajectoryEntity = effectEntity,
            hitEntity = targetEntity
        }

        table.insert(trapTaskIDs, GameGlobal.TaskManager():CoreGameStartTask(self._DoFly, self, trajectoryInfo))

        YIELD(TT, self._eachFlyDelayTime)
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(trapTaskIDs) do
        YIELD(TT)
    end

    YIELD(TT)

    local hitAnimName = self._hitAnimName
    local hitFxID = self._hitEffectID
    ---@type PlaySkillService
    local playSkillSvc = world:GetService("PlaySkill")
    local skillID = resultContainer:GetSkillID()
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
    end
end

---@param trajectoryInfo Internal_PlayThrowMonsterAndDamageInstruction_TrajectoryInfo
function PlayThrowMonsterAndDamageInstruction:_DoFly(TT, trajectoryInfo)
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
    local world = entity:GetOwnerWorld()
    world:DestroyEntity(entity)

    trajectoryInfo.hitEntity:SetAnimatorControllerTriggers({ self._hitAnimName })
    ---@type EffectService
    local effectService = world:GetService("Effect")
    effectService:CreateEffect(self._hitEffectID, trajectoryInfo.hitEntity)
end
