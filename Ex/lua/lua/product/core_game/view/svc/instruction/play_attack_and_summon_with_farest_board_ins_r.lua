require("base_ins_r")
---@class PlayAttackAndSummonWithFarestBoardInstruction: BaseInstruction
_class("PlayAttackAndSummonWithFarestBoardInstruction", BaseInstruction)
PlayAttackAndSummonWithFarestBoardInstruction = PlayAttackAndSummonWithFarestBoardInstruction

function PlayAttackAndSummonWithFarestBoardInstruction:Constructor(paramList)
    -- self._speed = tonumber(paramList.speed) or 12

    self._hitEffectID = tonumber(paramList.hitEffectID) or 0
    self._flyEffectID = tonumber(paramList.flyEffectID) or 0
    self._time = tonumber(paramList.time)

    self._animNameUp = "moveup"
    self._animNameDown = "movedown"
end

function PlayAttackAndSummonWithFarestBoardInstruction:GetCacheResource()
    local t = {}
    if self._hitEffectID and self._hitEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._hitEffectID].ResPath, 1})
    end
    if self._flyEffectID and self._flyEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._flyEffectID].ResPath, 1})
    end
    return t
end

---@param TT TaskToken
---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayAttackAndSummonWithFarestBoardInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    ---@type SkillDamageEffectResult[]
    local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)

    ---@type SkillEffectResult_SummonEverything[]
    local summonEverythingResult = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SummonEverything)

    if not damageResultArray then
        return
    end

    local listWaitTask = {}
    local world = casterEntity:GetOwnerWorld()

    ---@type PlaySkillService
    local playSkillService = world:GetService("PlaySkill")
    ---@type EffectService
    local sEffect = world:GetService("Effect")

    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    local gridPos = boardServiceRender:GetRealEntityGridPos(casterEntity)

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
    --起点
    local scopeResultStart = scopeCalculator:ComputeScopeRange(SkillScopeType.FarthestBoardRowOrColumn, {1})
    local attackRangeStart = scopeResultStart:GetAttackRange()
    --召唤
    local scopeResultSummon = scopeCalculator:ComputeScopeRange(SkillScopeType.FarthestBoardRowOrColumn, {2})

    --终点
    local scopeResultEnd = scopeCalculator:ComputeScopeRange(SkillScopeType.FarthestBoardRowOrColumn, {3})
    local attackRangeEnd = scopeResultEnd:GetAttackRange()

    local posOld = attackRangeStart[1]
    local posNew = attackRangeEnd[1]

    -- local dis = Vector2.Distance(scopeResultStart, scopeResultSummon)

    -- local gridCount = (posOld - posNew).sqrMagnitude

    local distance = Vector2.Distance(posNew, posOld)
    local speed = distance / self._time * 1000
    local oneGridFlyTime = self._time / distance
    -- GridMoveSystem的起始位置是从GridLocation取的
    -- Teleport逻辑是立刻将GridLocation更新的
    -- GridLocation和GridMove之间还有点其他的关系
    -- 牵扯的东西实在太多了，为了能顺利完成演出，这里会临时绕一下这个逻辑
    --casterEntity:SetGridPosition(posOld)
    -- if casterEntity:HasPetPstID() then
    --     local boardService = world:GetService("BoardRender")
    --     local oldPos = teleportResult:GetPosOld()
    --     local oldColor = teleportResult:GetColorOld()
    --     boardService:ReCreateGridEntity(oldColor, oldPos)
    -- end

    casterEntity:SetAnimatorControllerTriggers({self._animNameUp})
    YIELD(TT, 667)

    casterEntity:SetPosition(posOld)

    casterEntity:SetAnimatorControllerTriggers({self._animNameDown})
    YIELD(TT, 500)

    YIELD(TT)

    while (casterEntity:HasGridMove()) do
        local gridMoveComponent = casterEntity:GridMove()
        YIELD(TT)
    end

    --添加地刺特效
    local flyEffect = sEffect:CreateEffect(self._flyEffectID, casterEntity)

    casterEntity:AddGridMove(speed, posNew, posOld)

    local attackRangeSummon = scopeResultSummon:GetAttackRange()
    local distanceStartToSummon = Vector2.Distance(posOld, attackRangeSummon[1])
    YIELD(TT, oneGridFlyTime * distanceStartToSummon)

    --召唤结果
    if summonEverythingResult and table.count(summonEverythingResult) > 0 then
        ---@type PlaySkillInstructionService
        local sPlaySkillInstruction = world:GetService("PlaySkillInstruction")
        for _, summoResult in ipairs(summonEverythingResult) do
            local nTaskID =
                GameGlobal.TaskManager():CoreGameStartTask(
                sPlaySkillInstruction.ShowSummonAction,
                sPlaySkillInstruction,
                world,
                summoResult
            )
            table.insert(listWaitTask, nTaskID)
        end
    end

    YIELD(TT, oneGridFlyTime)

    --伤害结果
    if damageResultArray and table.count(damageResultArray) > 0 then
        for _, damageResult in ipairs(damageResultArray) do
            local targetEntityID = damageResult:GetTargetID()
            local targetEntity = world:GetEntityByID(targetEntityID)
            ---@type DamageInfo
            local damageInfo = damageResult:GetDamageInfo(1)
            local damageGridPos = damageResult:GetGridPos()
            ---调用统一处理被击的逻辑
            local beHitParam = HandleBeHitParam:New()
                :SetHandleBeHitParam_CasterEntity(casterEntity)
                :SetHandleBeHitParam_TargetEntity(targetEntity)
                :SetHandleBeHitParam_HitAnimName("Hit")
                :SetHandleBeHitParam_HitEffectID(self._hitEffectID)
                :SetHandleBeHitParam_DamageInfo(damageInfo)
                :SetHandleBeHitParam_DamagePos(damageGridPos)
                :SetHandleBeHitParam_HitTurnTarget(TurnToTargetType.None)
                :SetHandleBeHitParam_DeathClear(false)
                :SetHandleBeHitParam_IsFinalHit(false)
                :SetHandleBeHitParam_SkillID(skillID)

            playSkillService:HandleBeHit(TT, beHitParam)
        end
    end

    while (casterEntity:HasGridMove()) do
        YIELD(TT)
    end

    --删除地刺特效
    world:DestroyEntity(flyEffect)

    casterEntity:SetAnimatorControllerTriggers({self._animNameUp})
    YIELD(TT, 667)

    --回到自己坐标
    casterEntity:SetPosition(gridPos)

    casterEntity:SetAnimatorControllerTriggers({self._animNameDown})
    YIELD(TT, 500)

    --等待召唤技能的表现
    if table.count(listWaitTask) > 0 then
        while not TaskHelper:GetInstance():IsAllTaskFinished(listWaitTask) do
            YIELD(TT)
        end
    end
end
