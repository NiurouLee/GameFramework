require("base_ins_r")

_class("PlayTankRushPerGridInstruction", BaseInstruction)
---@class PlayTankRushPerGridInstruction: BaseInstruction
PlayTankRushPerGridInstruction = PlayTankRushPerGridInstruction

function PlayTankRushPerGridInstruction:Constructor(paramList)
    self._rotateTime = tonumber(paramList.rotateTime) or 1

    self._rushEffectID = tonumber(paramList.rushEffectID)
    self._rushEffectDestroyDelay = tonumber(paramList.rushEffectDestroyDelay)
    self._rushEndEffectID = tonumber(paramList.rushEndEffectID)

    self._rushSpeed = tonumber(paramList.rushSpeed)
    self._rushAnimatorTrigger = paramList.rushAnimatorTrigger

    self._hitAnimName = paramList["hitAnimName"]
    self._hitEffectID = tonumber(paramList["hitEffectID"])
    self._turnToTarget = tonumber(paramList["turnToTarget"])
    self._deathClear = tonumber(paramList["deathClear"])
end

function PlayTankRushPerGridInstruction:GetCacheResource()
    return {
        self:GetEffectResCacheInfo(self._rushEffectID),
        self:GetEffectResCacheInfo(self._rushEndEffectID),
        self:GetEffectResCacheInfo(self._hitEffectID),
    }
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTankRushPerGridInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_TankRushPerGrid
    local result = routineComponent:GetEffectResultByArray(SkillEffectType.TankRushPerGrid)

    if not result then
        return
    end

    local walkResArray = result:GetWalkResArray()
    local isCasterDead = result:IsCasterDead()

    local lastWalkRes = walkResArray[#walkResArray]
    local lastWalkPos = lastWalkRes:GetWalkPos()

    local casterPos = casterEntity:GetRenderGridPosition()
    local bodyArea = casterEntity:BodyArea():GetArea()
    local dis = 2147483647
    local comparePos = casterPos
    for _, body in ipairs(bodyArea) do
        local v2 = body + casterPos
        local d = Vector2.Distance(v2, lastWalkPos)
        if d < dis then
            dis = d
            comparePos = v2
        end
    end
    local dir = lastWalkPos - comparePos
    if dir.x > 0 then
        dir.x = 1
    elseif dir.x < 0 then
        dir.x = -1
    end
    if dir.y > 0 then
        dir.y = 1
    elseif dir.y < 0 then
        dir.y = -1
    end

    if dir ~= casterEntity:GetRenderGridDirection() then
        local world = casterEntity:GetOwnerWorld()
        ---@type BoardServiceRender
        local BoardServiceRender = world:GetService("BoardRender")
        local v3Forward = BoardServiceRender:GridPos2RenderPos(lastWalkPos + casterEntity:GridLocation():GetDamageOffset())

        local go = casterEntity:View():GetGameObject()
        local tween = go.transform:DOLookAt(v3Forward, self._rotateTime * 0.001)
        YIELD(TT, self._rotateTime)
        if not tween:IsComplete() then
            tween:Complete()
        end
    end

    local world = casterEntity:GetOwnerWorld()

    local fxsvc = world:GetService("Effect")
    ---@type Entity
    local rushEffectEntity = fxsvc:CreateEffect(self._rushEffectID, casterEntity)
    self:_PlayRush(TT, casterEntity, walkResArray, isCasterDead)
    GameGlobal.TaskManager():CoreGameStartTask(
        function(subTT)
            YIELD(subTT, self._rushEffectDestroyDelay)
            world:DestroyEntity(rushEffectEntity)
        end
    )

    local damageResultArray = result:GetDamageResultArray() or {}
    local damageResult = damageResultArray[1]
    if damageResult then
        ---@type Entity
        local rushEndEffectEntity = fxsvc:CreateEffect(self._rushEndEffectID, casterEntity)
        self:_PlayDamage(TT, casterEntity, phaseContext, damageResult)
    end

    local hitBackResultArray = result:GetHitBackResultArray() or {}
    local hitBackResult = hitBackResultArray[1]
    if hitBackResult then
        self:_PlayHitBack(TT, casterEntity, phaseContext, hitBackResult)
    end
end

--region 移动部分
---@param casterEntity Entity
---@param walkResultList MonsterMoveGridResult[]
---@param isCasterDead boolean
function PlayTankRushPerGridInstruction:_PlayRush(TT, casterEntity, walkResultList, isCasterDead)
    local world = casterEntity:GetOwnerWorld()

    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")

    for _, result in ipairs(walkResultList) do
        local walkPos = result:GetWalkPos()
        local curPos = boardServiceRender:GetRealEntityGridPos(casterEntity)

        casterEntity:AddGridMove(self._rushSpeed, walkPos, curPos)

        --方向代码源自上古代码，除必要变量名修改外保持不变
        local walkDir = walkPos - curPos
        ---@type BodyAreaComponent
        local bodyAreaCmpt = casterEntity:BodyArea()
        local areaCount = bodyAreaCmpt:GetAreaCount()
        ---普攻阶段多格的只有四格，以后如果有别的，再处理
        if areaCount == 4 then
            ---取左下位置坐标
            local leftDownPos = Vector2(curPos.x - 0.5, curPos.y - 0.5)
            walkDir = walkPos - leftDownPos
        end

        casterEntity:SetDirection(walkDir)
        --方向代码结束

        while casterEntity:HasGridMove() do
            YIELD(TT)
        end
    end

    if isCasterDead then
        ---@type MonsterShowRenderService
        local sMonsterShowRender = self._world:GetService("MonsterShowRender")
        sMonsterShowRender:_DoOneMonsterDead(TT, casterEntity)
    end
end

---@param casterEntity Entity
---@param walkRes MonsterMoveFrontAttackResult
function PlayTankRushPerGridInstruction:_PlayRushArrivePos(TT, casterEntity, walkRes)
    local trapResList = walkRes:GetWalkTrapResultList()
    for _, v in ipairs(trapResList) do
        ---@type WalkTriggerTrapResult
        local walkTrapRes = v
        local trapEntityID = walkTrapRes:GetTrapEntityID()
        local trapEntity = self._world:GetEntityByID(trapEntityID)
        ---@type AISkillResult
        local trapSkillRes = walkTrapRes:GetTrapResult()
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = trapSkillRes:GetResultContainer()
        trapEntity:SkillRoutine():SetResultContainer(skillEffectResultContainer)

        ---@type TrapServiceRender
        local trapSvc = self._world:GetService("TrapRender")
        trapSvc:PlayTrapTriggerSkill(TT, trapEntity, false, casterEntity)
    end
end
--endregion

--region 伤害表现部分
---@param casterEntity Entity
---@param damageResult SkillDamageEffectResult
---@param phaseContext SkillPhaseContext
function PlayTankRushPerGridInstruction:_PlayDamage(TT, casterEntity, phaseContext, damageResult)
    local world = casterEntity:GetOwnerWorld()

    ---@type PlaySkillService
    local playSkillService = world:GetService("PlaySkill")

    local damageGridPos = damageResult:GetGridPos()
    local playFinalAttack = playSkillService:GetFinalAttack(world, casterEntity, phaseContext)
    local targetEntity = world:GetEntityByID(damageResult:GetTargetID())
    local curDamageInfoIndex = phaseContext:GetCurDamageInfoIndex()
    ---@type DamageInfo
    local damageInfo = damageResult:GetDamageInfo(curDamageInfoIndex)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()

    local beHitParam = HandleBeHitParam:New()
                                       :SetHandleBeHitParam_CasterEntity(casterEntity)
                                       :SetHandleBeHitParam_TargetEntity(targetEntity)
                                       :SetHandleBeHitParam_HitAnimName(self._hitAnimName)
                                       :SetHandleBeHitParam_HitEffectID(self._hitEffectID)
                                       :SetHandleBeHitParam_DamageInfo(damageInfo)
                                       :SetHandleBeHitParam_DamagePos(damageGridPos)
                                       :SetHandleBeHitParam_HitTurnTarget(self._turnToTarget)
                                       :SetHandleBeHitParam_DeathClear(self._deathClear)
                                       :SetHandleBeHitParam_IsFinalHit(playFinalAttack)
                                       :SetHandleBeHitParam_SkillID(skillID)
                                       :SetHandleBeHitParam_DamageIndex(1)
    playSkillService:HandleBeHit(TT, beHitParam)
end
--endregion

--region 击退表现部分
---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
---@param hitBackResult SkillHitBackEffectResult
function PlayTankRushPerGridInstruction:_PlayHitBack(TT, casterEntity, phaseContext, hitBackResult)
    local world = casterEntity:GetOwnerWorld()
    local targetEntity = world:GetEntityByID(hitBackResult:GetTargetID())

    ---@type PlaySkillService
    local playSkillService = world:GetService("PlaySkill")

    local processHitTaskID = nil
    processHitTaskID = playSkillService:ProcessHit(casterEntity, targetEntity, hitBackResult)
    if processHitTaskID then
        while not TaskHelper:GetInstance():IsTaskFinished(processHitTaskID) do
            YIELD(TT)
        end
    end
end
--endregion
