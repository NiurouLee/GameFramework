--[[------------------
    创建怪物位置逻辑
--]] ------------------
---@class MonsterRefreshService:BaseService
_class("MonsterRefreshService", BaseService)
MonsterRefreshService = MonsterRefreshService

function MonsterRefreshService:Constructor(world)
    ---注册所有过程段执行器
    self._monsterRefreshFunc = {}

    self._monsterRefreshFunc[MonsterWaveInternalRefreshType.AfterMonsterDead] = self._IsMonsterDead
    self._monsterRefreshFunc[MonsterWaveInternalRefreshType.EveryRoundCount] = self._IsRoundAccept
    self._monsterRefreshFunc[MonsterWaveInternalRefreshType.WatchTarget] = self._WatchTargetExceptMonsterTurn
    self._monsterRefreshFunc[MonsterWaveInternalRefreshType.AllMonsterDead] = self._AllMonsterDead
    self._monsterRefreshFunc[MonsterWaveInternalRefreshType.TargetRound] = self._TargetRound
    self._monsterRefreshFunc[MonsterWaveInternalRefreshType.RoundResultWatchTarget] = self._RoundResultTargetRound
    self._monsterRefreshFunc[MonsterWaveInternalRefreshType.RoundResultCheckMonsterCount] = self._RoundResultCheckMonsterCount
    self._monsterRefreshFunc[MonsterWaveInternalRefreshType.AssignRefreshTypeAndTime] = self._AssignRefreshTypeAndTime
    self._monsterRefreshFunc[MonsterWaveInternalRefreshType.CompareMonsterNumber] = self._CompareMonsterNumber
    self._monsterRefreshFunc[MonsterWaveInternalRefreshType.OnlySpecifiedMonsterSurvival] = self._OnlySpecifiedMonsterSurvival
end

---@param refreshType MonsterWaveInternalRefreshType
---@param refreshParam number[]
---@return MonsterTransformParam[]
function MonsterRefreshService:IsRefreshMonster(refreshType, refreshParam, monsterWaveInternalTime, hadRefreshRound)
    return self._monsterRefreshFunc[refreshType](self, refreshParam, monsterWaveInternalTime, hadRefreshRound)
end

---@param refreshParam number[]
function MonsterRefreshService:_IsMonsterDead(refreshParam, monsterWaveInternalTime, hadRefreshRound, notCheckTime)
    if not notCheckTime and monsterWaveInternalTime == MonsterWaveInternalTime.MonsterTurn then
        return false
    end

    local roundCount = self:_GetBattleStatComponent():GetCurWaveTotalRoundCount()
    if table.intable(hadRefreshRound, roundCount) then
        return false
    end

    if self:_GetBattleStatComponent():IsCurWaveHasDeadRefreshMonster() then
        return false
    end

    local needMonsterList = table.cloneconf(refreshParam)
    ---@type number[]
    local monsterIDList = self:_GetBattleStatComponent():GetCurWaveDeadMonsterIDList()
    for _, id in ipairs(monsterIDList) do
        table.removev(needMonsterList, id)
    end
    ---@type boolean
    local ret = (#needMonsterList == 0)
    self:_GetBattleStatComponent():SetCurWaveHasDeadRefreshMonsterState(ret)
    return ret
end

---@param refreshParam number[]
function MonsterRefreshService:_IsRoundAccept(refreshParam, monsterWaveInternalTime, hadRefreshRound, notCheckTime)
    if not notCheckTime and monsterWaveInternalTime ~= MonsterWaveInternalTime.MonsterTurn then
        return false
    end

    local roundCount = self:_GetBattleStatComponent():GetCurWaveTotalRoundCount()
    if table.intable(hadRefreshRound, roundCount) then
        return false
    end

    local condition = tonumber(refreshParam[1])
    if condition > roundCount then
        return false
    end
    --判断是否能整除能整除就是符合条件
    local _, r = math.modf(roundCount / condition)
    return r == 0
end

function MonsterRefreshService:_WatchTargetExceptMonsterTurn(refreshParam, monsterWaveInternalTime, hadRefreshRound,
                                                             notCheckTime)
    if not notCheckTime and monsterWaveInternalTime == MonsterWaveInternalTime.MonsterTurn then
        return false
    end

    return self:_WatchTarget(refreshParam, hadRefreshRound)
end

function MonsterRefreshService:_WatchTarget(refreshParam, hadRefreshRound)
    local roundCount = self:_GetBattleStatComponent():GetCurWaveTotalRoundCount()
    if table.intable(hadRefreshRound, roundCount) then
        --Log.fatal("HasRefresh RoundCount:",roundCount," ",Log.traceback())
        return false
    end

    --一个/多个怪物
    local monsterID = refreshParam[1]
    local monsterTargetCount = tonumber(refreshParam[2])
    local limitCount = tonumber(refreshParam[3]) --限制刷新的次数
    if limitCount and table.count(hadRefreshRound) >= limitCount then
        return false
    end

    local curMonsterCount = 0
    ---统计指定的怪物数量
    local group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, aiEntity in ipairs(group:GetEntities()) do
        if not aiEntity:HasDeadMark() then
            ---@type MonsterIDComponent
            local monsterIDCmpt = aiEntity:MonsterID()
            if monsterIDCmpt ~= nil then
                local curID = monsterIDCmpt:GetMonsterID()
                if type(monsterID) ~= "table" and curID == tonumber(monsterID) then
                    curMonsterCount = curMonsterCount + 1
                elseif type(monsterID) == "table" and table.intable(monsterID, curID) then
                    curMonsterCount = curMonsterCount + 1
                elseif type(monsterID) == "table" and #monsterID == 0 then
                    --检查场上所有怪物数量
                    curMonsterCount = curMonsterCount + 1
                end
            end
        end
    end

    if curMonsterCount < monsterTargetCount then
        --Log.fatal("NeedRefresh RoundCount:",roundCount," ",Log.traceback())
        return true
    end

    return false
end

function MonsterRefreshService:_RoundResultTargetRound(refreshParam, monsterWaveInternalTime, hadRefreshRound,
                                                       notCheckTime)
    local invalidTime = { MonsterWaveInternalTime.ActiveSkill, MonsterWaveInternalTime.MonsterTurn }
    if not notCheckTime and table.icontains(invalidTime, monsterWaveInternalTime) then
        return false
    end
    return self:_WatchTarget(refreshParam, hadRefreshRound)
end

function MonsterRefreshService:_AllMonsterDead(refreshParam, monsterWaveInternalTime, hadRefreshRound, notCheckTime)
    if not notCheckTime and monsterWaveInternalTime == MonsterWaveInternalTime.MonsterTurn then
        return false
    end
    local battleStatCmpt = self:_GetBattleStatComponent()
    local roundCount = battleStatCmpt:GetCurWaveTotalRoundCount()
    if table.intable(hadRefreshRound, roundCount) then
        return false
    end

    if #hadRefreshRound > 0 then
        return false
    end

    local group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    local curMonsterCount = #(group:GetEntities())
     --符文刺客 离场怪
     local offBoardMonsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.OffBoardMonster)
     curMonsterCount = curMonsterCount + #(offBoardMonsterGroup:GetEntities())

    if curMonsterCount ~= 0 then
        return false
    end

    local strRefreshTimes = refreshParam[1]

    if strRefreshTimes ~= nil then
        local nRefreshTimes = tonumber(strRefreshTimes)
        local nCurRefreshTimes = battleStatCmpt:GetCurWaveAllMonsterDeadTimes()
        if nCurRefreshTimes >= nRefreshTimes then
            return false
        end
        battleStatCmpt:AddCurWaveAllmonsterDeadTimes()
        return true
    end
    return true
end

function MonsterRefreshService:_TargetRound(refreshParam, monsterWaveInternalTime, hadRefreshRound, notCheckTime)
    if not notCheckTime and monsterWaveInternalTime ~= MonsterWaveInternalTime.MonsterTurn then
        return false
    end

    local roundCount = self:_GetBattleStatComponent():GetCurWaveTotalRoundCount()
    if table.intable(hadRefreshRound, roundCount) then
        return false
    end

    if #hadRefreshRound > 0 then
        return false
    end

    local condition = tonumber(refreshParam[1])
    return condition == roundCount
end

function MonsterRefreshService:_RoundResultCheckMonsterCount(refreshParam, monsterWaveInternalTime, hadRefreshRound,
                                                             notCheckTime)
    if not notCheckTime and MonsterWaveInternalTime.RoundResult ~= monsterWaveInternalTime then
        return false
    end
    return self:_WatchTarget(refreshParam, hadRefreshRound)
end

function MonsterRefreshService:_AssignRefreshTypeAndTime(refreshParam, monsterWaveInternalTime, hadRefreshRound)
    local assignType = refreshParam.refreshType
    local assignParam = refreshParam.refreshParam
    local assignTimeList = refreshParam.time
    if not table.icontains(assignTimeList, monsterWaveInternalTime) then
        return false
    end
    return self._monsterRefreshFunc[assignType](self, assignParam, monsterWaveInternalTime, hadRefreshRound, true)
end

function MonsterRefreshService:_CompareMonsterNumber(refreshParam, monsterWaveInternalTime, hadRefreshRound, notCheckTime)
    local roundCount = self:_GetBattleStatComponent():GetCurWaveTotalRoundCount()
    if table.intable(hadRefreshRound, roundCount) then
        return false
    end

    local type = tonumber(refreshParam[1])
    local count = tonumber(refreshParam[2])

    local curMonsterCount = 0
    ---统计场上存活的怪物数量
    local group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, monster in ipairs(group:GetEntities()) do
        if not monster:HasDeadMark() then
            curMonsterCount = curMonsterCount + 1
        end
    end

    return CompareFunByType(type, curMonsterCount, count)
end

function MonsterRefreshService:_OnlySpecifiedMonsterSurvival(refreshParam, monsterWaveInternalTime, hadRefreshRound, notCheckTime)
    local roundCount = self:_GetBattleStatComponent():GetCurWaveTotalRoundCount()
    if table.intable(hadRefreshRound, roundCount) then
        return false
    end

    local monsterID = refreshParam[1]

    ---非配置的怪物存活，返回false
    local group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, monster in ipairs(group:GetEntities()) do
        if not monster:HasDeadMark() then
            ---@type MonsterIDComponent
            local monsterIDCmpt = monster:MonsterID()
            if monsterIDCmpt ~= nil then
                local curID = monsterIDCmpt:GetMonsterID()
                if type(monsterID) ~= "table" and curID ~= tonumber(monsterID) then
                    return false
                elseif type(monsterID) == "table" and not table.intable(monsterID, curID) then
                    return false
                end
            end
        end
    end

    return true
end
