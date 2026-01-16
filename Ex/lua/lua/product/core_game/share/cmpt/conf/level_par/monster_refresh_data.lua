--[[------------------------------------------------------------------------------------------
    MonsterRefreshData : 波次中刷怪(机关)的数据
]] --------------------------------------------------------------------------------------------

_class("MonsterRefreshData", Object)
---@class MonsterRefreshData: Object
MonsterRefreshData = MonsterRefreshData

function MonsterRefreshData:Constructor(id, type, param, world)
    self._refreshID = id
    self._refreshType = type
    self._refreshParam = param
    self._hadRefreshRound = {}
    self._refreshCount = 1 --刷新的次数，默认是1，用于结合关卡胜利条件10，杀死全部刷新怪物的计数。

    ---本次波次内刷新的怪物数据
    self._waveInternalRefreshParam = LevelMonsterRefreshParam:New(world)

    local cfg = Cfg.cfg_refresh[self._refreshID]
    if not cfg then
        Log.fatal("Cfg MonsterRefreshData Not Find ID:", self._refreshID)
    end

    local monsterRefreshID = cfg.MonsterRefreshIDList[1] --TODO jwk 随机还是不随机？
    local trapRefreshID = cfg.TrapRefreshIDList[1]

    self._monsterInternalIDList = {}
    ----@type TrapTransformParam
    self._trapInternalIDList = {}

    if self._refreshType ~= MonsterWaveInternalRefreshType.None then
        if monsterRefreshID > 0 then
            local monsterRefCfg = Cfg.cfg_refresh_monster[monsterRefreshID]
            if not monsterRefCfg then
                Log.fatal("Cfg monsterWaveConfig.WaveInternalRefreshID Not Find ID:", self._refreshID)
            end
            self._monsterInternalIDList =
            table.cloneconf(self._waveInternalRefreshParam:ParseMonsterRefreshParam(monsterRefCfg))
        end

        if trapRefreshID > 0 then
            local trapRefCfg = Cfg.cfg_refresh_trap[trapRefreshID]
            if not trapRefCfg then
                Log.fatal("Cfg monsterWaveConfig.WaveInternalRefreshID Not Find ID:", self._refreshID)
            end
            self._trapInternalIDList = table.cloneconf(self._waveInternalRefreshParam:ParseTrapRefreshParam(trapRefCfg))
        end
    end

    local limitCount
    if self._refreshType == MonsterWaveInternalRefreshType.WatchTarget then
        limitCount = tonumber(self._refreshParam[3]) --限制刷新的次数
    elseif self._refreshType == MonsterWaveInternalRefreshType.AllMonsterDead then
        limitCount = tonumber(self._refreshParam[1])
    elseif self._refreshType == MonsterWaveInternalRefreshType.RoundResultWatchTarget then
        limitCount = tonumber(self._refreshParam[3])
    elseif self._refreshType == MonsterWaveInternalRefreshType.RoundResultCheckMonsterCount then
        limitCount = tonumber(self._refreshParam[3])
    end
    if limitCount and limitCount > 0 then
        self._refreshCount = limitCount
    end

    self._showInterval = 0 ---刷新怪物的间隔，默认没有间隔
end

---设置 该类型下 刷新过的回合
function MonsterRefreshData:AddRefreshRound(key, round)
    local curRefreshRound = self._hadRefreshRound[key]
    if not curRefreshRound then
        curRefreshRound = {}
    end

    if not table.intable(curRefreshRound, round) then
        table.insert(curRefreshRound, round)
    end

    self._hadRefreshRound[key] = curRefreshRound
end

---获取 该类型 刷新过的回合
function MonsterRefreshData:GetHadRefreshRound(key)
    local curRefreshRound = self._hadRefreshRound[key]
    if not curRefreshRound then
        curRefreshRound = {}
        self._hadRefreshRound[key] = curRefreshRound
    end

    return curRefreshRound
end

function MonsterRefreshData:SetChangeGapTiles(gapTiles)
    self._newGapTiles = gapTiles
end

function MonsterRefreshData:GetGapTiles()
    return self._newGapTiles
end

function MonsterRefreshData:GetInternalRefreshID()
    return self._refreshID
end

---@return MonsterWaveInternalRefreshType
function MonsterRefreshData:GetInternalRefreshType()
    return self._refreshType
end

function MonsterRefreshData:GetInternalRefreshParam()
    return self._refreshParam
end

---波次内怪物刷新的列表
function MonsterRefreshData:GetInternalMonsterIDDic()
    return self._monsterInternalIDList
end

---波次内机关刷新的列表
function MonsterRefreshData:GetInternalTrapIDDic()
    return self._trapInternalIDList
end

function MonsterRefreshData:GetMonsterRefreshParam()
    return self._waveInternalRefreshParam
end

function MonsterRefreshData:GetMonsterRefreshCount()
    return self._refreshCount
end

function MonsterRefreshData:SetMonsterRefreshShowInterval(interval)
    self._showInterval = interval
end

function MonsterRefreshData:GetMonsterRefreshShowInterval()
    return self._showInterval
end
