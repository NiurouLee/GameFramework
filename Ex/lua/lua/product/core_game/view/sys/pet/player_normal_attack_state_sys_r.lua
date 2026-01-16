--[[----------------------------------------------------------
    PlayerNormalAttackStateSystem_Render处理玩家普通攻击状态
]] ------------------------------------------------------------
---@class PlayerNormalAttackStateSystem_Render:ReactiveSystem
_class("PlayerNormalAttackStateSystem_Render", ReactiveSystem)
PlayerNormalAttackStateSystem_Render = PlayerNormalAttackStateSystem_Render

---@param world MainWorld
function PlayerNormalAttackStateSystem_Render:Constructor(world)
    self._world = world
end

---@param world World
function PlayerNormalAttackStateSystem_Render:GetTrigger(world)
    local c =
        Collector:New(
        {
            world:GetGroup(world.BW_WEMatchers.MoveFSM)
        },
        {
            "Added"
        }
    )
    return c
end

---@param entity Entity
function PlayerNormalAttackStateSystem_Render:Filter(entity)
    if not entity:HasMoveFSM() then
        return false
    end

    local move_fsm_cmpt = entity:MoveFSM()
    local cur_state_id = move_fsm_cmpt:GetMoveFSMCurStateID()
    if cur_state_id == PlayerActionStateID.NormalAttack then
        return true
    end

    return false
end

function PlayerNormalAttackStateSystem_Render:ExecuteEntities(entities)
    --Log.fatal("PlayerNormalAttackStateSystem_Render begin execute >>>>>>>>>>>>>>>>>>>>")
    for i = 1, #entities do
        self:HandleAttack(entities[i])
    end
end

function PlayerNormalAttackStateSystem_Render:HandleAttack(entity)
    --Log.fatal("PlayerNormalAttackStateSystem_Render HandleAttack >>>>>>>>>>>>>>>>>>>>",entity:GetID())

    ---@type SkillPathNormalAttackData
    local normalAttackData = self:_GetPetNormalAttackData(entity)
    ---@type table
    local pathPointAttackDic = normalAttackData:GetPathAttackData()

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local curActorPos = boardServiceRender:GetRealEntityGridPos(entity)
    --计算出最后一个有攻击数据的划线点
    local lastDamagePoint = self:_CalcLastNormalDamagePathPoint(normalAttackData)

    local hasNormalAttackData = normalAttackData:HasPathPointNormalAttackData(curActorPos)
    if hasNormalAttackData then
        for pathPointPos, pathPointAttackData in pairs(pathPointAttackDic) do
            if pathPointPos == curActorPos then
                Log.debug("[attack] _HandlePlayAttack pathPointPos ", pathPointPos.x, " ", pathPointPos.y)
                TaskManager:GetInstance():CoreGameStartTask(
                    self._PlayAttackToTarget,
                    self,
                    entity,
                    pathPointAttackData,
                    pathPointPos,
                    lastDamagePoint
                )
                return
            end
        end
    else
        self._world:EventDispatcher():Dispatch(GameEventType.NormalAttackFinish, 1, entity:GetID())
    end
end

---@param entity Entity
function PlayerNormalAttackStateSystem_Render:_GetPetNormalSkillID(entity)
    local skillID = entity:SkillInfo():GetNormalSkillID()
    return skillID
end

---@param entity Entity
function PlayerNormalAttackStateSystem_Render:_GetPetNormalAttackData(entity)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type L2R_NormalAttackResult
    local normalAtkResCmpt = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.NormalAttack)
    ---@type SkillPathNormalAttackData
    local normalAttackData = normalAtkResCmpt:GetPetNormalAttackResult(entity:GetID())
    return normalAttackData
end

---@param pathPointAttackData SkillPathPointNormalAttackData 每个连线坐标产生的攻击数据AttackGridData的数组，key是被攻击点的坐标
---@param casterEntity Entity
---普攻表现
---星灵在一个连线坐标，攻击不同的格子，视为一次攻击。（如樱龙使/卡莲普攻一次普攻造成多个伤害，都是一次普攻）
---每次攻击的技能ID都可能是不同的，取的方法是 athPointAttackData:GetAttackGridDic()根据被击坐标取出来的AttackGridData，:GetAttackGridSkillId()
function PlayerNormalAttackStateSystem_Render:_PlayAttackToTarget(
    TT,
    casterEntity,
    pathPointAttackData,
    pathPointPos,
    lastDamagePoint)
    ---@type ConfigService
    local configService = self._world:GetService("Config")

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    --播放动作
    casterEntity:SetViewVisible(true)
    local attackGridDic = pathPointAttackData:GetAttackGridDic()
    --队伍的最后一个成员
    local freezeTimeScale = false
    local isLastTeamMember = self:_IsLastTeamMember(casterEntity)

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type L2R_NormalAttackResult
    local normalAtkRes = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.NormalAttack)

    local isFinalAtk = normalAtkRes:GetPlayNormalAttackFinalAttack()

    if isLastTeamMember == true and isFinalAtk == true then
        --当前的点是最后一个伤害点
        if lastDamagePoint == pathPointPos then
            --本次普攻就要慢放了
            freezeTimeScale = true
        end
    end

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local normalSkillBeforeMove = utilDataSvc:GetEntityBuffValue(casterEntity, "NormalSkillBeforeMove")

    --取出连线队列
    local orderArray = pathPointAttackData:GetPetOrderGridArray(casterEntity, pathPointPos)
    local attackCount = #orderArray
    if casterEntity:BuffView():GetBuffValue("ForcePetNormalAttackAfterMove") then
        local cRenderChain = self._world:GetRenderBoardEntity():RenderChainPath()
        if cRenderChain:GetRenderChainPath()[1] == pathPointPos then
            orderArray = {}
            attackCount = 0
        else
            orderArray = {pathPointPos}
            attackCount = 1
        end
    end

    for k, beAttackPos in ipairs(orderArray) do
        ---@type AttackGridData
        local attackGridData = self:_GetAttackGridPointData(attackGridDic, beAttackPos)
        local effectResultDict = attackGridData:GetEffectResultDict()
        --如果连线终点没有普攻技能数据effectResultDict，只有目标数据orderArray，会表现不存在的普攻，报错
        if effectResultDict and table.count(effectResultDict) > 0 then
            ---调用技能服务，执行技能表现
            local skillId = attackGridData:GetAttackGridSkillId()
            ---@type SkillEffectResultContainer
            local skillEffectResultContainer = SkillEffectResultContainer:New()
            skillEffectResultContainer:SetEffectResultDict(effectResultDict)
            skillEffectResultContainer:SetSkillID(skillId)
            --播放技能的时候，如果技能是普攻则播放combo
            skillEffectResultContainer:SetNormalAttack(true)
            skillEffectResultContainer:SetNormalAttackBeAttackOriPos(beAttackPos)

            if k == attackCount and freezeTimeScale == true then
                skillEffectResultContainer:SetFinalAttack(true)
            end
            if k == attackCount then
                skillEffectResultContainer:SetLastNormalAttackAtOnGrid(true)
            else
                skillEffectResultContainer:SetLastNormalAttackAtOnGrid(false)
            end
            casterEntity:SkillRoutine():ClearSkillRoutine()
            casterEntity:SkillRoutine():SetResultContainer(skillEffectResultContainer)

            local skinId = 1
            if casterEntity:MatchPet() then
                skinId = casterEntity:MatchPet():GetMatchPet():GetSkinId()
            end
            ---@type SkillConfigData
            local skillConfigData = configService:GetSkillConfigData(skillId, casterEntity)
            local skillPhaseArray = skillConfigData:GetSkillPhaseArray(skinId)
            local waitTaskID = playSkillService:StartSkillRoutine(casterEntity, skillPhaseArray, skillId)
            if not normalSkillBeforeMove then
                while not self:_IsTaskFinished(waitTaskID) do
                    YIELD(TT)
                end
            end
        end

        --普攻结束的buff表现统一处理了，这里不需要
    end

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    if skillEffectResultContainer ~= nil then
        skillEffectResultContainer:SetNormalAttack(false)
    end

    self._world:EventDispatcher():Dispatch(GameEventType.NormalAttackFinish, 1, casterEntity:GetID())
end

function PlayerNormalAttackStateSystem_Render:_GetAttackGridPointData(attackGridDic, checkPos)
    for beAttackPos, attackGridData in pairs(attackGridDic) do
        if beAttackPos == checkPos then
            return attackGridData
        end
    end

    return nil
end

function PlayerNormalAttackStateSystem_Render:_IsTaskFinished(taskID)
    local task = TaskManager:GetInstance():FindTask(taskID)
    if task ~= nil then
        --Log.fatal("task not finished ",taskID)
        return false
    else
        --Log.fatal("task has finished ",taskID)
    end

    return true
end

---查询自己是不是出战的最后一个成员
function PlayerNormalAttackStateSystem_Render:_IsLastTeamMember(curPetEntity)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderRoundTeamComponent
    local rroundteam = renderBoardEntity:RenderRoundTeam()
    local roundTeam = rroundteam:GetRoundTeam()
    return roundTeam[#roundTeam] == curPetEntity:GetID()
end

---@param pathNormalAttackData SkillPathNormalAttackData
function PlayerNormalAttackStateSystem_Render:_CalcLastNormalDamagePathPoint(pathNormalAttackData)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderChainPathComponent
    local rchainpath = renderBoardEntity:RenderChainPath()

    local chainPath = rchainpath:GetRenderChainPath()
    if not chainPath then
        return nil
    end

    local chainPathCount = #chainPath

    for index = chainPathCount, 1, -1 do
        local pathPoint = chainPath[index]
        local hasDamage = pathNormalAttackData:HasPathPointNormalDamage(pathPoint)
        if hasDamage == true then
            return pathPoint
        end
    end

    ---没有攻击数据，都打空了
    return nil
end

--所有人都进入idle状态就是普攻结束了
-- function PlayerNormalAttackStateSystem_Render:IsAllNormalAttackEnd(curPos)
--     local group = self._world:GetGroup(self._world.BW_WEMatchers.MoveFSM)
--     for i, e in ipairs(group:GetEntities()) do
--         local move_fsm_cmpt = e:MoveFSM()
--         local cur_state_id = move_fsm_cmpt:GetMoveFSMCurStateID()
--         if cur_state_id ~= PlayerActionStateID.Idle then
--             return false
--         end
--     end
--     return true
-- end
