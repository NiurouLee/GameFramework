--[[------------------------------------------------------------------------------------------
    LevelMonsterParam : 关卡怪物参数
]] --------------------------------------------------------------------------------------------

---@class LevelMonsterParam: Object
_class("LevelMonsterParam", Object)
LevelMonsterParam = LevelMonsterParam

function LevelMonsterParam:Constructor(world)
    ---@type MainWorld
    self._world = world

    self._monsterWaveCount = 0
    ---@type LevelMonsterWaveParam[]
    self._monsterWaveArray = {}

    self._allWaveMonsterIDs = {}
    self._loadingMonsterIDs = {}
    self._runningMonsterIDs = {}
end

function LevelMonsterParam:GetMonsterWaveArray()
    return self._monsterWaveArray
end

---@return LevelMonsterWaveParam
function LevelMonsterParam:GetWaveConfig(waveNum)
    local waveConfig = self._monsterWaveArray[waveNum]
    if waveConfig then
        return waveConfig
    end
    return nil
end

function LevelMonsterParam:GetWaveCompleteConditionType(waveNum)
    local waveConfig = self._monsterWaveArray[waveNum]
    if waveConfig then
        return waveConfig:GetCompleteConditionType()
    end
    return nil
end
function LevelMonsterParam:GetWaveCompleteConditionParam(waveNum)
    local waveConfig = self._monsterWaveArray[waveNum]
    if waveConfig then
        return waveConfig:GetCompleteConditionParam()
    end
    return nil
end

---
function LevelMonsterParam:IsCombinedConditionWave(waveNum)
    local waveConfig = self._monsterWaveArray[waveNum]
    if not waveConfig then
        return
    end

    return waveConfig:IsCombinedConditionWave()
end

---
function LevelMonsterParam:GetWaveCombinedCompleteConditionArguments(waveNum)
    ---@type LevelMonsterWaveParam
    local waveConfig = self._monsterWaveArray[waveNum]
    if not waveConfig then
        return
    end

    return waveConfig:GetCombinedCompleteConditionArguments()
end

---提取某波次的波次内刷怪数据
function LevelMonsterParam:GetWaveInternalRefreshData(waveNum)
    ---@type LevelMonsterWaveParam
    local waveConfig = self._monsterWaveArray[waveNum]
    if waveConfig then
        return waveConfig:GetWaveInternalRefreshData()
    end
    return nil
end

function LevelMonsterParam:GetWaveInternalRefreshType(waveNum)
    local waveConfig = self._monsterWaveArray[waveNum]
    if waveConfig then
        return waveConfig:GetInternalRefreshType()
    end
    return nil
end

function LevelMonsterParam:GetWaveInternalRefreshTypeParam(waveNum)
    local waveConfig = self._monsterWaveArray[waveNum]
    if waveConfig then
        return waveConfig:GetInternalRefreshTypeParam()
    end
    return nil
end
function LevelMonsterParam:GetMonsterWaveCount()
    return self._monsterWaveCount
end

--获得波次开始的怪物刷新配置
function LevelMonsterParam:GetWaveBeginMonsterParam(waveNum, playerPos)
    local waveConfig = self:GetWaveConfig(waveNum)
    if waveConfig then
        return waveConfig:GetWaveBeginRefreshParam(playerPos)
    end
    return nil
end
--根据刷怪类型和波次获得怪物波次中刷新配置
function LevelMonsterParam:GetWaveInternalRefreshMonsterParam(waveNum, refreshType)
    local waveConfig = self:GetWaveConfig(waveNum)
    if waveConfig then
        return waveConfig:GetWaveInternalRefreshParam(refreshType)
    end
    return nil
end

function LevelMonsterParam:GetWaveBeginTrapArray(waveNum)
    local waveConfig = self:GetWaveConfig(waveNum)
    if waveConfig then
        return waveConfig:GetWaveBeginRefreshTrapArray()
    end
    return nil
end

function LevelMonsterParam:GetMonsterConfigWaveArray(levelConfigData)
    if self._world.BW_WorldInfo.matchType == MatchType.MT_Conquest then
        return self._world.BW_WorldInfo.waveIDList
    else
        return levelConfigData.MonsterWave
    end
end

function LevelMonsterParam:ParseMonsterParam(levelConfigData)
    self._monsterWaveArray = {}
    self._allWaveMonsterIDs = {}
    self._loadingMonsterIDs = {}
    self._runningMonsterIDs = {}

    local monsterWaveArray = self:GetMonsterConfigWaveArray(levelConfigData)
    self._monsterWaveCount = #monsterWaveArray

    local mazeService = self._world:GetService("Maze")

    local waveRandoms
    if mazeService and mazeService:IsMazeMatch() then
        waveRandoms = mazeService:GetMazeWaveRandoms()
    end
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    for k, monsterWaveID in ipairs(monsterWaveArray) do
        --Log.fatal("parse monster wave",monsterWaveID," ",type(monsterWaveArray))
        local monsterWaveConfig = Cfg.cfg_monster_wave[monsterWaveID]
        if (monsterWaveConfig == nil) then
            Log.error("LevelMonsterParam:ParseMonsterParam monsterWaveConfig =nil", monsterWaveID)
        end

        local mazeWaveInfo = nil
        if waveRandoms then
            mazeWaveInfo = {waveRandoms[2 * k - 1], waveRandoms[2 * k]}
        end

        local monsterWaveParam = LevelMonsterWaveParam:New(self._world, k)
        monsterWaveParam:ParseMonsterWaveParam(monsterWaveConfig, mazeWaveInfo)
        ----词条修改关卡配置
        if affixService then
            monsterWaveParam = affixService:ChangeWaveMonsterRefreshParam(monsterWaveParam, k)
        end
        self._monsterWaveArray[#self._monsterWaveArray + 1] = monsterWaveParam

        local monsterIDList = monsterWaveParam:GetWaveMonsterIDArray()
        table.appendArray(self._allWaveMonsterIDs, monsterIDList)
        if k == 1 then
            table.appendArray(self._loadingMonsterIDs, monsterIDList)
        else
            table.appendArray(self._runningMonsterIDs, monsterIDList)
        end
    end

    --提前波次
    local preMonsterWave = levelConfigData.PreMonsterWave
    if preMonsterWave then
        local monsterWaveConfig = Cfg.cfg_monster_wave[preMonsterWave]
        if (monsterWaveConfig == nil) then
            Log.error("LevelMonsterParam:ParseMonsterParam monsterWaveConfig =nil", preMonsterWave)
        end
        local monsterWaveParam = LevelMonsterWaveParam:New(self._world, 0)
        monsterWaveParam:ParseMonsterWaveParam(monsterWaveConfig)
        self._monsterWaveArray[0] = monsterWaveParam

        local monsterIDList = monsterWaveParam:GetWaveMonsterIDArray()
        table.appendArray(self._allWaveMonsterIDs, monsterIDList)
        table.appendArray(self._loadingMonsterIDs, monsterIDList)
    end
end

function LevelMonsterParam:GetIsBoss(waveNum)
    ---@type LevelMonsterWaveParam
    local waveConfig = self:GetWaveConfig(waveNum)
    if waveConfig then
        return waveConfig:IsBossWave()
    end
    return false
end

function LevelMonsterParam:GetBossID(waveNum)
    ---@type LevelMonsterWaveParam
    local waveConfig = self:GetWaveConfig(waveNum)
    if waveConfig then
        return waveConfig:GetBossID()
    end
    return nil
end

function LevelMonsterParam:GetAllMonsterID()
    return self._allWaveMonsterIDs
end

function LevelMonsterParam:GetLoadingMonsterID()
    return self._loadingMonsterIDs
end

function LevelMonsterParam:GetRunningMonsterID()
    return self._runningMonsterIDs
end

function LevelMonsterParam:HitBackParam(waveNum)
    ---@type LevelMonsterWaveParam
    local waveConfig = self:GetWaveConfig(waveNum)
    if waveConfig then
        return waveConfig:HitBackParam()
    end
    return false
end

function LevelMonsterParam:BGMParam(waveNum)
    ---@type LevelMonsterWaveParam
    local waveConfig = self:GetWaveConfig(waveNum)
    if waveConfig then
        return waveConfig:BGMParam()
    end
    return false
end

function LevelMonsterParam:DebugCompleteCondition(nType, nParam)
    for i = 1, #self._monsterWaveArray do
        ---@type LevelMonsterWaveParam
        local waveParam = self._monsterWaveArray[i]
        waveParam:DebugCompleteCondition(nType, nParam)
    end
end

--获得波次刷新格子
function LevelMonsterParam:GetWaveBoard(waveNum)
    local waveConfig = self:GetWaveConfig(waveNum)
    if waveConfig then
        return waveConfig:GetWaveBoard()
    end
    return nil
end

---解析多面棋盘
function LevelMonsterParam:ParseMonsterParamMultiBoard(monsterWaveArray)
    self._monsterWaveArray = {}
    self._allWaveMonsterIDs = {}
    self._loadingMonsterIDs = {}
    self._runningMonsterIDs = {}

    self._monsterWaveCount = #monsterWaveArray

    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    for k, monsterWaveID in ipairs(monsterWaveArray) do
        --Log.fatal("parse monster wave",monsterWaveID," ",type(monsterWaveArray))
        local monsterWaveConfig = Cfg.cfg_monster_wave[monsterWaveID]
        if (monsterWaveConfig == nil) then
            Log.error("LevelMonsterParam:ParseMonsterParam monsterWaveConfig =nil", monsterWaveID)
        end

        local mazeWaveInfo = nil
        local monsterWaveParam = LevelMonsterWaveParam:New(self._world, k)
        monsterWaveParam:ParseMonsterWaveParam(monsterWaveConfig, mazeWaveInfo)
        ----词条修改关卡配置
        if affixService then
            monsterWaveParam = affixService:ChangeWaveMonsterRefreshParam(monsterWaveParam, k)
        end
        self._monsterWaveArray[#self._monsterWaveArray + 1] = monsterWaveParam

        local monsterIDList = monsterWaveParam:GetWaveMonsterIDArray()
        table.appendArray(self._allWaveMonsterIDs, monsterIDList)
        if k == 1 then
            table.appendArray(self._loadingMonsterIDs, monsterIDList)
        else
            table.appendArray(self._runningMonsterIDs, monsterIDList)
        end
    end
end

function LevelMonsterParam:WaveMonsterShowInterval(waveNum)
    ---@type LevelMonsterWaveParam
    local waveConfig = self:GetWaveConfig(waveNum)
    if waveConfig then
        return waveConfig:GetMonsterWaveShowInterval()
    end
    return 0
end