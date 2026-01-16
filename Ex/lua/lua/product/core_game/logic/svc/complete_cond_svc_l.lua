--[[------------------
    波次胜利条件
--]]
------------------
_class("CompleteConditionService", BaseService)
---@class CompleteConditionService:BaseService
CompleteConditionService = CompleteConditionService

---@class CompleteConditionCheckFlagType
---用在检测flag计数buff时选择检测目标类型
---其中Hero是用不上的，因为队长不在group里
CompleteConditionCheckFlagType = {
    [1] = "Hero",
    [2] = "MonsterID",
    [3] = "Trap",
    Hero = 1,
    Monster = 2,
    Trap = 3
}
-- _enum("CompleteConditionCheckFlagType", CompleteConditionCheckFlagType)

function CompleteConditionService:Constructor(world)
    ---注册所有过程段执行器
    self._completeConditionFunc = {}

    self._completeConditionFunc[CompleteConditionType.AllMonsterDead] = CCAllMonsterDead:New(world)
    self._completeConditionFunc[CompleteConditionType.CollectItems] = CCCollectItems:New(world)
    self._completeConditionFunc[CompleteConditionType.WaveEnd] = CCWaveEnd:New(world)
    self._completeConditionFunc[CompleteConditionType.RuneDisappear] = CCRuneDisappear:New(world)
    self._completeConditionFunc[CompleteConditionType.AllBossNotSurvival] = CCAllBossNotSurvival:New(world)
    self._completeConditionFunc[CompleteConditionType.MonsterEscape] = CCMonsterEscape:New(world)
    self._completeConditionFunc[CompleteConditionType.RoundCountLimit] = CCRoundCountLimit:New(world)
    self._completeConditionFunc[CompleteConditionType.ArriveAtPos] = CCArriveAtPos:New(world)
    self._completeConditionFunc[CompleteConditionType.MonsterDead] = CCMonsterDead:New(world)
    self._completeConditionFunc[CompleteConditionType.AllRefreshMonsterDead] = CCAllRefreshMonsterDead:New(world)
    self._completeConditionFunc[CompleteConditionType.AllRefreshMonsterDeadOrRoundCountLimit] =
        CCAllRefreshMonsterDeadOrRoundCountLimit:New(world)
    self._completeConditionFunc[CompleteConditionType.CheckFlagBuffCount] = CCCheckFlagBuffCount:New(world)
    self._completeConditionFunc[CompleteConditionType.AssignWaveAndRandomNextWave] =
        CCAssignWaveAndRandomNextWave:New(world)
    self._completeConditionFunc[CompleteConditionType.KillAnyMonsterCount] = CKillAnyMonsterCount:New(world)
    self._completeConditionFunc[CompleteConditionType.UpHoldAndKillAllInternalRefreshMonster] =
        CCUpHoldAndKillAnyMonsterWave:New(world)
    self._completeConditionFunc[CompleteConditionType.AllMonsterNotSurvival] = CCAllMonsterNotSurvival:New(world)
    self._completeConditionFunc[CompleteConditionType.RemotePlayerDead] = CCRemotePlayerDead:New(world)
    self._completeConditionFunc[CompleteConditionType.AllConfigMonsterDead] = CCAllConfigMonsterDead:New(world)
    self._completeConditionFunc[CompleteConditionType.AllConfigMonsterHPLock] = CCAllConfigMonsterHPLock:New(world)
    self._completeConditionFunc[CompleteConditionType.TrapTypeDeadAndAllMonsterDead] =
        CCTrapTypeDeadAndAllMonsterDead:New(world)
    self._completeConditionFunc[CompleteConditionType.RoundCountLimitAndCheckMonsterEscape] =
        CCRoundCountLimitAndCheckMonsterEscape:New(world)
    self._completeConditionFunc[CompleteConditionType.ChessEscape] = CCChessEscape:New(world)
    self._completeConditionFunc[CompleteConditionType.SelectChessEscape] = CCChessEscape:New(world)
    self._completeConditionFunc[CompleteConditionType.CompareMonsterNumber] = CCCompareMonsterNumber:New(world)
    self._completeConditionFunc[CompleteConditionType.OnlySpecifiedMonsterSurvival] = CCOnlySpecifiedMonsterSurvival:New(
        world)
    self._completeConditionFunc[CompleteConditionType.AllMonsterNotSurvivaldifferent] = CCAllMonsterNotSurvival:New(world)
    self._completeConditionFunc[CompleteConditionType.ComparePopStarNumber] = CCComparePopStarNumber:New(world)
end

---
function CompleteConditionService:IsDoneCompleteCondition(conditionType, conditionParam, combinedConditionArguments)
    if conditionType == CompleteConditionType.CombinedCompleteCondition then
        return self:_IsDoneCombinedCondition(conditionParam, combinedConditionArguments)
    end

    local checker = self._completeConditionFunc[conditionType]
    if not checker then
        Log.fatal("IsDoneCompleteCondition() not find checker! conditionType=", conditionType)
        return false
    end
    return checker:CheckCondition(conditionParam)
end

---
function CompleteConditionService:_IsDoneCombinedCondition(conditionParam, combinedConditionArguments)
    local mode = conditionParam[1][1]

    local conditionA = combinedConditionArguments.conditionA
    local conditionParamA = combinedConditionArguments.conditionParamA
    local conditionB = combinedConditionArguments.conditionB
    local conditionParamB = combinedConditionArguments.conditionParamB

    local resultA, paramA = self:IsDoneCompleteCondition(conditionA, conditionParamA)
    local resultB, paramB = self:IsDoneCompleteCondition(conditionB, conditionParamB)

    paramA = paramA or {}
    paramA.isCompleted = resultA

    paramB = paramB or {}
    paramB.isCompleted = resultB

    ---@type BattleStatComponent
    local uniqueBattleStat = self._world:BattleStat()
    uniqueBattleStat:AppendCombinedConditionRecord(resultA, resultB)

    if mode == CombinedCompleteConditionMode.And then
        return resultA and resultB, paramA, paramB
    elseif mode == CombinedCompleteConditionMode.Or then
        if resultA then
            return true, paramA, paramB
        end
        return resultB, paramA, paramB
    end
end

function CompleteConditionService:GetArchivedData(conditionType)
    local checker = self._completeConditionFunc[conditionType]
    return checker:GetArchivedData()
end

function CompleteConditionService:SetArchivedData(conditionType, data)
    local checker = self._completeConditionFunc[conditionType]
    checker:SetArchivedData(data)
end

_class("ComplateConditionBase", Object)
---@class ComplateConditionBase : Object
ComplateConditionBase = ComplateConditionBase

function ComplateConditionBase:Constructor(world)
    ---@type MainWorld
    self._world = world
end

function ComplateConditionBase:CheckCondition(conditionParam)
    Log.exception("CheckCondition() not implemented! cls=", self._className)
end

function ComplateConditionBase:GetArchivedData()
end

function ComplateConditionBase:SetArchivedData(data)
end

function ComplateConditionBase:_CalcMonsterCount()
    local monster_group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    local monster_entities = monster_group:GetEntities()
    local count = 0
    for k, v in ipairs(monster_entities) do
        if not v:HasDeadMark() then
            count = count + 1
        end
    end
    --符文刺客 离场怪
    local offBoardMonsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.OffBoardMonster)
    local offBoardMonsterEntities = offBoardMonsterGroup:GetEntities()
    for k, v in ipairs(offBoardMonsterEntities) do
        if not v:HasDeadMark() then
            count = count + 1
        end
    end

    return count
end

function ComplateConditionBase:_IsAllMonsterDead()
    local count = self:_CalcMonsterCount()
    if count <= 0 then
        return true
    end
    return false
end

--全部怪物死亡
_class("CCAllMonsterDead", ComplateConditionBase)
CCAllMonsterDead = CCAllMonsterDead

function CCAllMonsterDead:CheckCondition(conditionParam)
    local monster_count = self:_CalcMonsterCount()
    --Log.notice("MonsterCount :", monster_count)
    --怪物全死 战斗结束
    if monster_count <= 0 then
        return true
    end
    return false
end

--收集物品
_class("CCCollectItems", ComplateConditionBase)
CCCollectItems = CCCollectItems

function CCCollectItems:CheckCondition(conditionParam)
    local maxCollectCount = conditionParam[1][2]
    local curCollectNum = self._world:BattleStat():GetDropCollectNum()
    if curCollectNum >= maxCollectCount then
        return true
    end
    return false
end

function CCCollectItems:GetArchivedData()
    local curCollectNum = self._world:BattleStat():GetDropCollectNum()
    return curCollectNum
end

function CCCollectItems:SetArchivedData(data)
    self._world:BattleStat():SetDropCollectNum(data)
end

--波次结束且怪物全死
_class("CCWaveEnd", ComplateConditionBase)
CCWaveEnd = CCWaveEnd

function CCWaveEnd:CheckCondition(conditionParam)
    local isAllMonsterDead = self:_IsAllMonsterDead()
    local hasNextWave = self._world:BattleStat():HasNextWave()
    --怪物全死 战斗结束
    if isAllMonsterDead == true and hasNextWave == false then
        return true
    end

    return false
end

--符文全部消失+怪物全部死亡
_class("CCRuneDisappear", ComplateConditionBase)
CCRuneDisappear = CCRuneDisappear

function CCRuneDisappear:CheckCondition(conditionParam)
    --判断是否还有符文
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for i, e in ipairs(trapGroup:GetEntities()) do
        ---@type TrapComponent
        local trapCmpt = e:Trap()
        if trapCmpt:IsRuneChange() then
            return false
        end
    end

    return self:_IsAllMonsterDead()
end

--boss死亡
_class("CCAllBossNotSurvival", ComplateConditionBase)
CCAllBossNotSurvival = CCAllBossNotSurvival

function CCAllBossNotSurvival:CheckCondition(conditionParam)
    local hasNextWave = self._world:BattleStat():HasNextWave()
    local param = conditionParam[1]
    local monsterIDList = {}
    for _, strID in ipairs(param) do
        table.insert(monsterIDList, tonumber(strID))
    end
    local monster_group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    local monster_entities = monster_group:GetEntities()
    local count = 0
    for _, id in ipairs(monsterIDList) do
        for k, v in ipairs(monster_entities) do
            ---@type Entity
            local monsterEntity = v
            if v:HasMonsterID() and v:MonsterID():GetMonsterID() == id then
                if not monsterEntity:HasDeadMark() then
                    return false
                end
            end
        end
    end
    ---完成了,杀掉在场的其余怪物
    if true and not hasNextWave then
        return true
    else
        return false
    end
end

---不能逃跑的怪物逃跑了
_class("CCMonsterEscape", ComplateConditionBase)
CCMonsterEscape = CCMonsterEscape

function CCMonsterEscape:Constructor()
    self._escapeCount = 0
    self._archivedCount = 0
end

function CCMonsterEscape:CheckCondition(conditionParam)
    --判断是否还有符文
    local entityGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterEscape)
    local es = entityGroup:GetEntities()
    local nEscape = 0
    ---@param e Entity
    for _, e in ipairs(es) do
        ---@type MonsterEscapeComponent
        local monsterEscapeComponent = e:MonsterEscape()
        if monsterEscapeComponent and monsterEscapeComponent:IsEscapeSuccess() then
            nEscape = nEscape + 1
        end
    end

    local nLimitCount = conditionParam[1]
    self._escapeCount = nEscape
    return nEscape > nLimitCount
end

--TODO 怀疑不用存档，怪物没死
function CCMonsterEscape:GetArchivedData()
    return self._escapeCount
end

function CCMonsterEscape:SetArchivedData(data)
    self._archivedCount = data
end

---回合数到了
_class("CCRoundCountLimit", ComplateConditionBase)
CCRoundCountLimit = CCRoundCountLimit

function CCRoundCountLimit:CheckCondition(conditionParam)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local nRoundNow = battleStatCmpt:GetCurWaveTotalRoundCount()
    local nRoundLimit = conditionParam[1][1]
    --补充修改关卡回合(buff 电击枪)
    local levelSupplementRoundCount = battleStatCmpt:GetLevelSupplementRoundCount()
    local nRoundMax = nRoundLimit + levelSupplementRoundCount
    if nRoundNow > nRoundMax then
        return true, { current = nRoundNow - 1, full = nRoundMax }
    end
    return false, { current = nRoundNow - 1, full = nRoundMax }
end

function CCRoundCountLimit:GetArchivedData()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local nRoundNow = battleStatCmpt:GetCurWaveTotalRoundCount()
    return nRoundNow
end

function CCRoundCountLimit:SetArchivedData(data)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    battleStatCmpt:SetCurWaveTotalRoundCount(data)
end

---回合数到了且逃脱数小于m
_class("CCRoundCountLimitAndCheckMonsterEscape", ComplateConditionBase)
---@class CCRoundCountLimitAndCheckMonsterEscape : ComplateConditionBase
CCRoundCountLimitAndCheckMonsterEscape = CCRoundCountLimitAndCheckMonsterEscape
function CCRoundCountLimitAndCheckMonsterEscape:Constructor()
    self._escapeCount = 0
    self._archivedCount = 0
end

function CCRoundCountLimitAndCheckMonsterEscape:CheckCondition(conditionParam)
    local escapeOk, escapeParam = self:_CheckEscape(conditionParam)
    if escapeOk then
        local roundOk = self:_CheckRound(conditionParam)
        if roundOk then
            return true, escapeParam
        end
    end
    return false
end

function CCRoundCountLimitAndCheckMonsterEscape:_CheckRound(conditionParam)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local nRoundNow = battleStatCmpt:GetCurWaveTotalRoundCount()
    local nRoundLimit = conditionParam[1][1]
    --补充修改关卡回合(buff 电击枪)
    local levelSupplementRoundCount = battleStatCmpt:GetLevelSupplementRoundCount()
    local nRoundMax = nRoundLimit + levelSupplementRoundCount
    if nRoundNow > nRoundMax then
        return true, { current = nRoundNow - 1, full = nRoundMax }
    end
    return false, { current = nRoundNow - 1, full = nRoundMax }
end

function CCRoundCountLimitAndCheckMonsterEscape:_CheckEscape(conditionParam)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    -- local entityGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterEscape)
    -- local es = entityGroup:GetEntities()
    -- local nEscape = 0
    -- ---@param e Entity
    -- for _, e in ipairs(es) do
    --     ---@type MonsterEscapeComponent
    --     local monsterEscapeComponent = e:MonsterEscape()
    --     if monsterEscapeComponent and monsterEscapeComponent:IsEscapeSuccess() then
    --         nEscape = nEscape + 1
    --     end
    -- end

    local nLimitCount = conditionParam[1][2]
    local nEscape = battleStatCmpt:GetMonsterEscapeNum()
    self._escapeCount = nEscape
    return nEscape < nLimitCount, { current = self._escapeCount, full = nLimitCount }
end

function CCRoundCountLimitAndCheckMonsterEscape:GetArchivedData()
    local data = {}

    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local nRoundNow = battleStatCmpt:GetCurWaveTotalRoundCount()
    data.nRoundNow = nRoundNow
    data.escapeCount = self._escapeCount
    return data
end

function CCRoundCountLimitAndCheckMonsterEscape:SetArchivedData(data)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    battleStatCmpt:SetCurWaveTotalRoundCount(data.nRoundNow)
    self._archivedCount = data.escapeCount --应该用不到
    --self._escapeCount = data.escapeCount
end

--到达出口
_class("CCArriveAtPos", ComplateConditionBase)
CCArriveAtPos = CCArriveAtPos

function CCArriveAtPos:CheckCondition(conditionParam)
    local ePlayer = self._world:Player():GetLocalTeamEntity()
    if ePlayer and ePlayer:GridLocation().Position == Vector2(conditionParam[1][1], conditionParam[1][2]) then
        return true
    end
    return false
end

--指定id的怪物死亡
_class("CCMonsterDead", ComplateConditionBase)
CCMonsterDead = CCMonsterDead

function CCMonsterDead:CheckCondition(conditionParam)
    local monsterIDList = {}
    for _, monsterID in ipairs(conditionParam[1]) do
        table.insert(monsterIDList, tonumber(monsterID))
    end
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local totalDeadMonsterIDList = battleStatCmpt:GetTotalDeadMonsterIDList()
    for _, id in ipairs(monsterIDList) do
        local bFind = false
        for k, v in ipairs(totalDeadMonsterIDList) do
            if v:GetMonsterID() == id then
                bFind = true
            end
        end
        if not bFind then
            return false
        end
    end
    return true
end

-- function CCMonsterDead:GetArchivedData()
--     ---@type BattleStatComponent
--     local battleStatCmpt = self._world:BattleStat()
--     local totalDeadMonsterIDList = battleStatCmpt:GetTotalDeadMonsterIDList()
--     return totalDeadMonsterIDList
-- end

-- function CCMonsterDead:SetArchivedData(data)
--     ---@type BattleStatComponent
--     local battleStatCmpt = self._world:BattleStat()
--     for i, monsterDeadParam in ipairs(data) do
--         battleStatCmpt:AddDeadMonsterID(monsterDeadParam:GetMonsterID())
--     end
-- end

--刷新怪物死亡
_class("CCAllRefreshMonsterDead", ComplateConditionBase)
CCAllRefreshMonsterDead = CCAllRefreshMonsterDead

function CCAllRefreshMonsterDead:CheckCondition(conditionParam)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local totalDeadMonsterIDList = battleStatCmpt:GetTotalDeadMonsterIDList()

    ---@type LevelConfigData
    local levelConfigData = self._world:GetService("Config"):GetLevelConfigData()
    local monsterIds = levelConfigData:GetAllMonsterID()

    --复制一份关卡刷新的怪物，不包含后召唤的怪物
    local monsterIdsCopy = {}
    table.appendArray(monsterIdsCopy, monsterIds)

    --判断已经杀死的怪物 如果存在于复制的关卡刷新怪物列表里 则删除复制列表里的值
    for _, monsterDeadParam in ipairs(totalDeadMonsterIDList) do
        local deadMonsterID = monsterDeadParam:GetMonsterID()
        if table.intable(monsterIdsCopy, deadMonsterID) then
            table.removev(monsterIdsCopy, deadMonsterID)
        end
    end

    --如果关卡刷新的怪物都死掉 则胜利
    if #monsterIdsCopy == 0 then
        return true
    end

    return false
end

-- function CCAllRefreshMonsterDead:GetArchivedData()
--     ---@type BattleStatComponent
--     local battleStatCmpt = self._world:BattleStat()
--     local totalDeadMonsterIDList = battleStatCmpt:GetTotalDeadMonsterIDList()
--     return totalDeadMonsterIDList
-- end

-- function CCAllRefreshMonsterDead:SetArchivedData(data)
--     ---@type BattleStatComponent
--     local battleStatCmpt = self._world:BattleStat()
--     for i, monsterDeadParam in ipairs(data) do
--         battleStatCmpt:AddDeadMonsterID(monsterDeadParam:GetMonsterID())
--     end
-- end

--怪物死亡或到达回合数
_class("CCAllRefreshMonsterDeadOrRoundCountLimit", ComplateConditionBase)
CCAllRefreshMonsterDeadOrRoundCountLimit = CCAllRefreshMonsterDeadOrRoundCountLimit

function CCAllRefreshMonsterDeadOrRoundCountLimit:CheckCondition(conditionParam)
    ---@type CompleteConditionService
    local ccsvc = self._world:GetService("CompleteCondition")

    local _roundCountLimit = ccsvc:IsDoneCompleteCondition(CompleteConditionType.RoundCountLimit, conditionParam)
    local _allRefreshMonsterDead =
        ccsvc:IsDoneCompleteCondition(CompleteConditionType.AllRefreshMonsterDead, conditionParam)

    if _roundCountLimit or _allRefreshMonsterDead then
        return true
    end

    return false
end

function CCAllRefreshMonsterDeadOrRoundCountLimit:GetArchivedData()
    local data = {}
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local waveDeadMonsterIDList = battleStatCmpt:GetCurWaveDeadMonsterIDList()
    data.deadMonsterIDList = waveDeadMonsterIDList

    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local nRoundNow = battleStatCmpt:GetCurWaveTotalRoundCount()
    data.waveRoundCount = nRoundNow

    return data
end

function CCAllRefreshMonsterDeadOrRoundCountLimit:SetArchivedData(data)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    for i, monsterID in ipairs(data.deadMonsterIDList) do
        battleStatCmpt:AddDeadMonsterID(monsterID)
    end

    battleStatCmpt:SetCurWaveTotalRoundCount(data.waveRoundCount)
end

-- 指定波次结束关卡并且概率出现下一波次，结算结果按照指定波次计算
_class("CCAssignWaveAndRandomNextWave", ComplateConditionBase)
CCAssignWaveAndRandomNextWave = CCAssignWaveAndRandomNextWave

function CCAssignWaveAndRandomNextWave:CheckCondition(conditionParam)
    local baseParamInfoIndex = LevelCompleteAssignWaveParamExp.BaseLevelCompleteCond
    local param = conditionParam[1]
    -- 获取当前波次
    local battleStatCmpt = self._world:BattleStat()
    local nCurWave = battleStatCmpt:GetCurWaveIndex()
    local l_nAssignWave = param[LevelCompleteAssignWaveParamExp.AssignWaveEnd] -- 指定结束波次
    local l_nBaseCompleteConditionType = param[baseParamInfoIndex] -- 指定结束波次胜利条件
    local isFinish = false
    if nCurWave == l_nAssignWave then
        if l_nBaseCompleteConditionType and l_nBaseCompleteConditionType ~= CompleteConditionType.WaveEnd then
            local baseParam = {}
            local baseParamCount = table.count(param)
            if baseParamCount > baseParamInfoIndex then
                for i = (baseParamInfoIndex + 1), baseParamCount do
                    baseParam[i - baseParamInfoIndex] = param[i]
                end
            end
            ---@type CompleteConditionService
            local ccsvc = self._world:GetService("CompleteCondition")
            -- 计算到此为止是否结束
            isFinish = ccsvc:IsDoneCompleteCondition(l_nBaseCompleteConditionType, baseParam)
        else
            isFinish = self:_IsAllMonsterDead()
        end
        return isFinish
    elseif nCurWave > l_nAssignWave then -- 如果当前波次比指定波次大表示已经通关
        return true
    else
        return false
    end
end

_class("CCCheckFlagBuffCount", ComplateConditionBase)
CCCheckFlagBuffCount = CCCheckFlagBuffCount

function CCCheckFlagBuffCount:CheckCondition(conditionParam)
    local param = conditionParam[1]
    local targetType = param[1]
    local flagID = param[2]
    local requiredCount = param[3]

    local entities = {}
    if targetType == CompleteConditionCheckFlagType.Hero then
        table.insert(entities, self._world:Player():GetLocalTeamEntity())
    else
        local groupMatcher = self._world.BW_WEMatchers[CompleteConditionCheckFlagType[targetType]]
        local group = self._world:GetGroup(groupMatcher)
        if not group then
            Log.fatal("No entity group for targetType ", tostring(targetType))
            return false
        end

        entities = group:GetEntities()
    end

    if #entities == 0 then
        return false
    end

    local currentMaxCount = 0
    for _, entity in ipairs(entities) do
        currentMaxCount = math.max(currentMaxCount, self:_GetFlagBuffCount(entity, flagID))
    end

    return currentMaxCount >= requiredCount
end

---@param entity Entity
function CCCheckFlagBuffCount:_GetFlagBuffCount(entity, flagID)
    if not entity:HasBuff() then
        return 0
    end

    ---@type BuffComponent
    local buffComponent = entity:BuffComponent()
    local flagKey = string.format(BattleConst.FlagBuffOverlayKeyFormatter, flagID)
    return buffComponent:GetBuffValue(flagKey) or 0
end

function CCCheckFlagBuffCount:GetArchivedData()
    --不用存档，宝箱关进入后重新踩机关
end

function CCCheckFlagBuffCount:SetArchivedData(data)
end

_class("CKillAnyMonsterCount", ComplateConditionBase)
CKillAnyMonsterCount = CKillAnyMonsterCount

function CKillAnyMonsterCount:CheckCondition(conditionParam)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local totalDeadMonsterIDList = battleStatCmpt:GetCurWaveDeadMonsterIDList()
    --local totalDeadMonsterIDList = battleStatCmpt:GetTotalDeadMonsterIDList()
    local deadMonsterCount = table.count(totalDeadMonsterIDList)
    local needKillCount = conditionParam[1][1]
    if deadMonsterCount >= needKillCount then
        return true, { current = deadMonsterCount, full = needKillCount }
    end
    return false, { current = deadMonsterCount, full = needKillCount }
end

_class("CCUpHoldAndKillAnyMonsterWave", CCAllRefreshMonsterDead)
CCUpHoldAndKillAnyMonsterWave = CCUpHoldAndKillAnyMonsterWave
function CCUpHoldAndKillAnyMonsterWave:CheckCondition(conditionParam)
    return CCUpHoldAndKillAnyMonsterWave.super.CheckCondition(self, conditionParam)
end

--boss死亡
_class("CCAllMonsterNotSurvival", ComplateConditionBase)
CCAllMonsterNotSurvival = CCAllMonsterNotSurvival

function CCAllMonsterNotSurvival:CheckCondition(conditionParam)
    local monsterIDList = {}
    for _, strID in ipairs(conditionParam[1]) do
        table.insert(monsterIDList, tonumber(strID))
    end
    local monster_group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    local monster_entities = monster_group:GetEntities()
    local count = 0
    for _, id in ipairs(monsterIDList) do
        for k, v in ipairs(monster_entities) do
            ---@type Entity
            local monsterEntity = v
            if v:HasMonsterID() and v:MonsterID():GetMonsterID() == id then
                if not monsterEntity:HasDeadMark() then
                    return false
                end
            end
        end
    end
    ---完成了,杀掉在场的其余怪物
    return true
end

--敌方队伍死亡
_class("CCRemotePlayerDead", ComplateConditionBase)
CCRemotePlayerDead = CCRemotePlayerDead

function CCRemotePlayerDead:CheckCondition(conditionParam)
    ---@type Entity
    local remoteTeamEntity = self._world:Player():GetRemoteTeamEntity()
    if remoteTeamEntity:HasTeamDeadMark() then
        return true
    end
    return false
end

--參數配置怪物都死亡，每个"|"表示And ，每个","表示OR,可以支持变身会换MonsterID的怪物
_class("CCAllConfigMonsterDead", ComplateConditionBase)
CCAllConfigMonsterDead = CCAllConfigMonsterDead

function CCAllConfigMonsterDead:CheckCondition(conditionParam)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    for i, param in ipairs(conditionParam) do
        if type(param) == "number" then
            if not battleStatCmpt:IsMonsterHasDead(param) then
                return false
            end
        end
        if type(param) == "table" then
            local noOne = true
            for _, v in ipairs(param) do
                local monsterID = tonumber(v)
                if battleStatCmpt:IsMonsterHasDead(monsterID) then
                    noOne = false
                    break
                end
            end
            if noOne then
                return false
            end
        end
    end
    return true
end

_class("CCAllConfigMonsterHPLock", ComplateConditionBase)
---@class CCAllConfigMonsterHPLock : ComplateConditionBase
CCAllConfigMonsterHPLock = CCAllConfigMonsterHPLock

function CCAllConfigMonsterHPLock:CheckCondition(conditionParam)
    local monsterClassIDTable = conditionParam[1]

    local lockHPDic = {}
    ---@type BuffLogicService
    local bufflsvc = self._world:GetService("BuffLogic")
    -- 这个专门用了个不一样的命名，用来提醒这个table是严禁修改的
    ---@type Entity[]
    local GLOBALmonsterGroupEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
    for _, entity in ipairs(GLOBALmonsterGroupEntities) do
        -- 死者不算
        if entity:HasDeadMark() then
            goto CC_ALL_CONFIG_MONSTER_HP_LOCK_CONTINUE
        end

        ---@type MonsterIDComponent
        local cMonsterID = entity:MonsterID()
        local monsterClassID = cMonsterID:GetMonsterClassID()
        if not table.icontains(monsterClassIDTable, monsterClassID) then
            goto CC_ALL_CONFIG_MONSTER_HP_LOCK_CONTINUE
        end

        local hasLockHPBuff, isLock = bufflsvc:CheckEntityLockHP(entity)

        if not hasLockHPBuff then
            goto CC_ALL_CONFIG_MONSTER_HP_LOCK_CONTINUE
        end

        local curHp = entity:Attributes():GetCurrentHP()
        local maxHp = entity:Attributes():CalcMaxHp()
        local leftHPPercent = curHp / maxHp * 100

        local lockHPPercent = bufflsvc:GetLockHPInfo(entity)
        if lockHPPercent > 0 then
            lockHPDic[monsterClassID] = true
        end

        ::CC_ALL_CONFIG_MONSTER_HP_LOCK_CONTINUE::
    end

    -- 只有配置的怪物都在场，且都处于锁血，才认为达成胜利条件
    local isAllConfigMonsterHPLock = true
    for _, classID in ipairs(monsterClassIDTable) do
        isAllConfigMonsterHPLock = isAllConfigMonsterHPLock and lockHPDic[classID]
    end

    return isAllConfigMonsterHPLock
end

--参数中的机关类型的机关全部死亡，并且全部怪物死亡
_class("CCTrapTypeDeadAndAllMonsterDead", ComplateConditionBase)
---@class CCTrapTypeDeadAndAllMonsterDead : ComplateConditionBase
CCTrapTypeDeadAndAllMonsterDead = CCTrapTypeDeadAndAllMonsterDead

function CCTrapTypeDeadAndAllMonsterDead:CheckCondition(conditionParam)
    local trapType = conditionParam[1][1]
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for i, e in ipairs(trapGroup:GetEntities()) do
        ---@type TrapComponent
        local trapCmpt = e:Trap()
        if trapCmpt:GetTrapType() == trapType and not e:HasDeadMark() then
            return false
        end
    end

    local monster_count = self:_CalcMonsterCount()
    if monster_count > 0 then
        return false
    end

    return true
end

---
_class("CCChessEscape", ComplateConditionBase)
---@class CCChessEscape : ComplateConditionBase
CCChessEscape = CCChessEscape

function CCChessEscape:Constructor()
    self._escapeCount = 0
    self._archivedCount = 0
end

function CCChessEscape:CheckCondition(conditionParam)
    local limitCount = conditionParam[1][1]
    local targetChessClassID = conditionParam[1][2] or 0

    --杀死所有怪物也可以通过
    local monster_count = self:_CalcMonsterCount()
    if monster_count <= 0 then
        return true, { current = limitCount, full = limitCount }
    end

    local entityGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterEscape)
    local es = entityGroup:GetEntities()
    local nEscape = 0
    ---@param e Entity
    for _, e in ipairs(es) do
        ---@type MonsterEscapeComponent
        local monsterEscapeComponent = e:MonsterEscape()
        ---@type ChessPetComponent
        local chessPetCmpt = e:ChessPet()
        if monsterEscapeComponent and monsterEscapeComponent:IsEscapeSuccess() and chessPetCmpt then
            if targetChessClassID ~= 0 then
                local chessPetClassID = chessPetCmpt:GetChessPetClassID()
                if targetChessClassID == chessPetClassID then
                    nEscape = nEscape + 1
                end
            else
                nEscape = nEscape + 1
            end
        end
    end

    self._escapeCount = nEscape
    return nEscape >= limitCount, { current = nEscape, full = limitCount }
end

--region 怪物剩余数量达到配置条件
---@class CCCompareMonsterNumber : ComplateConditionBase
_class("CCCompareMonsterNumber", ComplateConditionBase)
CCCompareMonsterNumber = CCCompareMonsterNumber

function CCCompareMonsterNumber:CheckCondition(conditionParam)
    local type = conditionParam[1][1] or ConditionCompareType.Equal
    local count = conditionParam[1][2] or 0
    local curCount = self:_CalcMonsterCount()

    return CompareFunByType(type, curCount, count)
end

--endregion

--region 只有配置参数内的怪物存活
---@class CCOnlySpecifiedMonsterSurvival : ComplateConditionBase
_class("CCOnlySpecifiedMonsterSurvival", ComplateConditionBase)
CCOnlySpecifiedMonsterSurvival = CCOnlySpecifiedMonsterSurvival

function CCOnlySpecifiedMonsterSurvival:CheckCondition(conditionParam)
    local monsterIDList = {}
    for _, strID in ipairs(conditionParam[1]) do
        table.insert(monsterIDList, tonumber(strID))
    end
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    local monsters = monsterGroup:GetEntities()
    for k, v in ipairs(monsters) do
        local monsterID = nil
        if v:HasMonsterID() then
            monsterID = v:MonsterID():GetMonsterID()
        end
        if monsterID and not table.icontains(monsterIDList, monsterID) and not v:HasDeadMark() then
            return false
        end
    end

    return true
end

--endregion

--region 达到消除格子数
---@class CCComparePopStarNumber : ComplateConditionBase
_class("CCComparePopStarNumber", ComplateConditionBase)
CCComparePopStarNumber = CCComparePopStarNumber

function CCComparePopStarNumber:CheckCondition(conditionParam)
    local popNumMax = conditionParam[1][1]
    
    ---@type PopStarServiceLogic
    local popStarSvc = self._world:GetService("PopStarLogic")
    local curNum = popStarSvc:GetPopGridNum()
    if curNum >= popNumMax then
        return true
    end

    return false
end

--endregion
