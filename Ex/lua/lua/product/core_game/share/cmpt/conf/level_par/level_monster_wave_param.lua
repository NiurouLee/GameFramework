--[[------------------------------------------------------------------------------------------
    LevelMonsterWaveParam : 关卡怪物波次参数
]] --------------------------------------------------------------------------------------------

_class("LevelMonsterWaveParam", Object)
---@class LevelMonsterWaveParam: Object
LevelMonsterWaveParam = LevelMonsterWaveParam

function LevelMonsterWaveParam:Constructor(world, waveNum)
    ---@type MainWorld
    self._world = world

    self._roundCount = 0
    self._completeCondition = 0
    self._completeConditionParam = 0
    --波次开始刷新参数
    ---@type LevelMonsterRefreshParam
    self._waveBeginRefreshParam = nil

    --波次中触发刷怪类型
    ---@type MonsterRefreshData[]
    self._internalRefreshDataArray = nil

    --是否是Boss波次
    self._isBoss = false
    self._hitBackParam = nil
    ---@type LevelMonsterWaveBeginRefreshParam[]
    self._waveBeginRefreshParamList = {}
    --波次要切换的bgm
    self._bgm = nil
    self._bossIDList = {}
    self._waveMonsterIDList = {}
    self._waveTrapList = {}
    --波次刷新格子
    self._waveBoard = nil
    self._waveNum = waveNum

    ---各种波次表现参数
    self._showInterval = 0 ---怪物刷新支持间隔，默认刷怪是一起出现
end

--function LevelMonsterWaveParam:GetWaveBeginRefreshParam()
--    return self._waveBeginRefreshParam
--end
---@param playerPos Vector2
function LevelMonsterWaveParam:GetWaveBeginRefreshParam(playerPos)
    if self._waveBeginRefreshParam then
        return self._waveBeginRefreshParam
    end
    local paramList = {}
    for _, v in ipairs(self._waveBeginRefreshParamList) do
        if v:IsInMyArea(playerPos) then
            table.insert(paramList, v:GetRefreshParam())
        end
    end
    if #paramList == 1 then
        return paramList[1]
    elseif #paramList == 0 then
        local index = self:_CalcRandom(1, #self._waveBeginRefreshParamList)
        return self._waveBeginRefreshParamList[index]:GetRefreshParam()
    else
        local index = self:_CalcRandom(1, #paramList)
        return paramList[index]
    end
end

---获取波次内刷怪的数据，是个LevelMonsterInternalRefreshData的数组
---@return MonsterRefreshData[]
function LevelMonsterWaveParam:GetWaveInternalRefreshData()
    return self._internalRefreshDataArray
end
---@return number
function LevelMonsterWaveParam:GetWaveInternalRefreshCount()
    return table.count(self._internalRefreshDataArray)
end

function LevelMonsterWaveParam:GetWaveBeginRefreshTrapArray()
    if self._waveBeginRefreshParam then
        return self._waveBeginRefreshParam:GetTrapArray()
    end
end

function LevelMonsterWaveParam:GetWaveMonsterIDArray()
    return self._waveMonsterIDList
end

function LevelMonsterWaveParam:GetCompleteConditionType()
    return self._completeCondition
end

function LevelMonsterWaveParam:GetCompleteConditionParam()
    return self._completeConditionParam
end

function LevelMonsterWaveParam:GetRoundEnergyDic()
    return self._roundEnergyDic
end

---
function LevelMonsterWaveParam:IsCombinedConditionWave()
    return self._completeCondition == CompleteConditionType.CombinedCompleteCondition
end

---
function LevelMonsterWaveParam:GetCombinedCompleteConditionArguments()
    return {
        conditionA = self._combinedCompleteConditionA,
        conditionParamA = self._combinedCompleteConditionAParam,
        conditionB = self._combinedCompleteConditionB,
        conditionParamB = self._combinedCompleteConditionBParam
    }
end

function LevelMonsterWaveParam:ParseMonsterWaveParam(monsterWaveConfig, mazeWaveInfo)
    if not monsterWaveConfig then
        Log.fatal("monsterWaveConfig is nil")
    end

    self._roundCount = monsterWaveConfig.Round
    self._completeCondition = monsterWaveConfig.CompleteCondition
    self._completeConditionParam = monsterWaveConfig.CompleteConditionParam
    self._isBoss = monsterWaveConfig.IsBoss
    self._hitBackParam = monsterWaveConfig.HitBackParam
    self._bgm = monsterWaveConfig.BGM
    self._bossIDList = table.cloneconf(monsterWaveConfig.BossID)
    self._waveBoard = monsterWaveConfig.WaveBoard

    self._combinedCompleteConditionA = monsterWaveConfig.CombinedCompleteConditionA
    self._combinedCompleteConditionAParam = monsterWaveConfig.CombinedCompleteConditionParamA
    self._combinedCompleteConditionB = monsterWaveConfig.CombinedCompleteConditionB
    self._combinedCompleteConditionBParam = monsterWaveConfig.CombinedCompleteConditionParamB

    if monsterWaveConfig.WaveBeginRefresh then
        for _, v in ipairs(monsterWaveConfig.WaveBeginRefresh) do
            local cfg = Cfg.cfg_refresh[v.refreshID]
            if not cfg then
                Log.fatal("Cfg WaveBeginRefresh Not Find ID:", v.refreshID, "WaveID:", monsterWaveConfig.ID)
            end
            local monsterRefreshID = cfg.MonsterRefreshIDList[1] 
            local monsterRefCfg = Cfg.cfg_refresh_monster[monsterRefreshID]

            local trapRefreshID = cfg.TrapRefreshIDList[1]
            local trapRefCfg = Cfg.cfg_refresh_trap[trapRefreshID]

            local waveRefreshParam = LevelMonsterRefreshParam:New(self._world)
            waveRefreshParam:ParseMonsterRefreshParam(monsterRefCfg)
            waveRefreshParam:ParseTrapRefreshParam(trapRefCfg)
            table.appendArray(self._waveMonsterIDList, waveRefreshParam:GetMonsterIDArray())
            if self._isBoss and monsterRefCfg.RandomMonsterIDList then
                self._bossIDList = table.cloneconf(waveRefreshParam:GetMonsterIDArray())
            end

            local groupList = Cfg.cfg_monster_grid_group[v.gridGroupID]
            if not groupList then
                Log.fatal(
                    "Cfg GroupID Not Find ID:",
                    v.refreshID,
                    "WaveID:",
                    monsterWaveConfig.ID,
                    "GroupID:",
                    v.gridGroupID
                )
            end
            local beginRefreshParam =
                LevelMonsterBeginRefreshParam:New(monsterRefreshID, waveRefreshParam, groupList.Group)
            table.insert(self._waveBeginRefreshParamList, beginRefreshParam)
        end
    else
        local cfg = Cfg.cfg_refresh[monsterWaveConfig.WaveBeginRefreshID]
        if not cfg then
            Log.fatal("Cfg monsterWaveConfig.WaveBeginRefreshID Not Find ID:", monsterWaveConfig.WaveBeginRefreshID)
        end

        --随机怪物
        local monsterWeight = cfg.MonsterWeight
        local monsterRefreshIDs = cfg.MonsterRefreshIDList

        local totalw = 0
        for _, w in ipairs(monsterWeight) do
            totalw = totalw + w
        end
        local monsterRefreshId = monsterRefreshIDs[1]
        local rand = self:_CalcRandom()
        if mazeWaveInfo then
            rand = mazeWaveInfo[1]
        end
        local ww = rand * totalw
        for j, w in ipairs(monsterWeight) do
            ww = ww - w
            if ww <= 0 then
                monsterRefreshId = monsterRefreshIDs[j]
                break
            end
        end

        local monsterRefCfg = Cfg.cfg_refresh_monster[monsterRefreshId]
        self._waveBeginRefreshParam = LevelMonsterRefreshParam:New(self._world)
        self._waveBeginRefreshParam:ParseMonsterRefreshParam(monsterRefCfg)
        table.appendArray(self._waveMonsterIDList, self._waveBeginRefreshParam:GetMonsterIDArray())
        if self._isBoss and monsterRefCfg.RandomMonsterIDList then
            self._bossIDList = table.cloneconf(self._waveBeginRefreshParam:GetMonsterIDArray())
        end

        --随机机关
        local trapWeight = cfg.TrapWeight
        local trapRefreshIDs = cfg.TrapRefreshIDList
        if trapRefreshIDs and #trapRefreshIDs > 0 and trapRefreshIDs[1] > 0 then
            local totalw = 0
            for _, w in ipairs(trapWeight) do
                totalw = totalw + w
            end
            local trapRefreshId = trapRefreshIDs[1]
            local rand = self:_CalcRandom()
            if mazeWaveInfo then
                rand = mazeWaveInfo[2]
            end
            local ww = rand * totalw
            for j, w in ipairs(trapWeight) do
                ww = ww - w
                if ww <= 0 then
                    trapRefreshId = trapRefreshIDs[j]
                    break
                end
            end

            local trapRefCfg = Cfg.cfg_refresh_trap[trapRefreshId]
            if trapRefCfg then
                self._waveBeginRefreshParam:ParseTrapRefreshParam(trapRefCfg)
            end
        end
    end

    ---解析波次内怪物刷新
    self._internalRefreshDataArray = self:_ParseMonsterInternalRefresh(monsterWaveConfig)
    if self._internalRefreshDataArray ~= nil then
        ---提取波次内刷新怪
        for _, v in ipairs(self._internalRefreshDataArray) do
            ---@type MonsterRefreshData
            local refreshData = v
            local dataDic = refreshData:GetInternalMonsterIDDic()
            local refreshCount = refreshData:GetMonsterRefreshCount()
            for i = 1, refreshCount do
                for k, v in ipairs(dataDic) do
                    table.insert(self._waveMonsterIDList, v)
                end
            end
        end
    end

    ---解析表现参数
    local showParamCfg = monsterWaveConfig.ShowParam
    if showParamCfg then 
        if showParamCfg.showInterval then 
            self._showInterval = showParamCfg.showInterval
        end
    end
end
----@return MonsterRefreshData[]
function LevelMonsterWaveParam:_ParseMonsterInternalRefresh(monsterWaveConfig)
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    ---@type AffixAddWaveInternalParam[]
    local affixAddParamList = affixService:AddWaveInternalParam(self._waveNum)
    local refreshConfigTable = monsterWaveConfig.WaveInternalRefresh
    if refreshConfigTable == nil and table.count(affixAddParamList) == 0 then
        return nil
    end
    local refreshParamList = {}
    if refreshConfigTable then
        for index, refreshTableValue in ipairs(refreshConfigTable) do
            -- local cfg = Cfg.cfg_refresh[refreshTableValue.refreshID]
            -- local monsterRefreshID = cfg.MonsterRefreshIDList[1] --TODO jwk 随机还是不随机？
            local param = affixService:ChangeWaveInternalParam(refreshTableValue.param, index, self._waveNum)

            ---@type MonsterRefreshData
            local refreshData = MonsterRefreshData:New(refreshTableValue.refreshID, refreshTableValue.type, param,
                self._world)
            if refreshTableValue.showInterval then 
                refreshData:SetMonsterRefreshShowInterval(refreshTableValue.showInterval)
            end
            
            if refreshTableValue.gapTiles then
                refreshData:SetChangeGapTiles(refreshTableValue.gapTiles)
            end
            refreshParamList[#refreshParamList + 1] = refreshData
        end
    end
    for _, param in ipairs(affixAddParamList) do
        ---@type MonsterRefreshData
        local refreshData = MonsterRefreshData:New(param:GetRefreshID(), param:GetType(), param:GetParam(), self._world)
        refreshParamList[#refreshParamList + 1] = refreshData
    end
    return refreshParamList
end

function LevelMonsterWaveParam:GetInternalRefreshTypeParam()
    return self._waveInternalRefreshTypeParam
end

function LevelMonsterWaveParam:GetInternalRefreshType()
    return self._waveInternalRefreshType
end

function LevelMonsterWaveParam:IsBossWave()
    return self._isBoss
end

---@return table<number>
function LevelMonsterWaveParam:GetBossID()
    return self._bossIDList
end

---获取怪物出场击退宠物参数
function LevelMonsterWaveParam:HitBackParam()
    return self._hitBackParam
end

---获取波次BGM
function LevelMonsterWaveParam:BGMParam()
    return self._bgm
end

function LevelMonsterWaveParam:_CalcRandom(m, n)
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    return randomSvc:LogicRand(m, n)
end

function LevelMonsterWaveParam:DebugCompleteCondition(nType, nParam)
    self._completeCondition = nType
    self._completeConditionParam = nParam
end
_class("LevelMonsterBeginRefreshParam", Object)
---@class LevelMonsterWaveBeginRefreshParam: Object
LevelMonsterBeginRefreshParam = LevelMonsterBeginRefreshParam
---@param refreshID number
---@param refreshParam LevelMonsterRefreshParam
---@param areaPosList table<number,number>
function LevelMonsterBeginRefreshParam:Constructor(refreshID, refreshParam, areaPosList)
    self._refreshID = refreshID
    self._refreshParam = refreshParam
    self._areaPosList = {}
    if areaPosList then
        for _, v in ipairs(areaPosList) do
            table.insert(self._areaPosList, Vector2(v[1], v[2]))
        end
    end
end
---@param pos Vector2
function LevelMonsterBeginRefreshParam:IsInMyArea(pos)
    if #self._areaPosList == 0 then
        return true
    end
    return table.icontains(self._areaPosList, pos)
end
---@return LevelMonsterRefreshParam
function LevelMonsterBeginRefreshParam:GetRefreshParam()
    return self._refreshParam
end

---获取波次刷新格子
function LevelMonsterWaveParam:GetWaveBoard()
    return self._waveBoard
end

function LevelMonsterWaveParam:GetMonsterWaveShowInterval()
    return self._showInterval
end
