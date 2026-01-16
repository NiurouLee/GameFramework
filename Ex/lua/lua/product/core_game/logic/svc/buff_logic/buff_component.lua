--[[
    持有entity身上所有的buff，负责添加移除buff
]]
_class("BuffComponent", Object)
---@class BuffComponent: Object
BuffComponent = BuffComponent

function BuffComponent:Constructor(world)
    self._world = world
    ---@type BuffInstance[]
    self._buffArray = {} --buff列表
    ---@type table< BuffSource, table<number,BuffInstance> >
    self._buffSourceList = {}
    --buff状态位
    self._buffFlags = FlagValue:New(0)
    --buff状态值
    self._buffValues = {}

    ------其他临时数据------
    self._curHitIndex = 0
    ---@type number[]
    self._hasDropHpPercent = {}
    ---@type number[]
    self._lockHpPercent = {}
    ---@type number
    self._lockHpRoundIndex = 0
    self._lastUnlockHpRound = 0

    self._lockIndex = 0
    self._lockGSMState = 0
    self._unlockIndex = {}

    self._lastEffectedInfo = {}

    self._poisonByAttackCasterID = nil
end

function BuffComponent:Dispose()
end

--检查状态buff
function BuffComponent:HasFlag(flag)
    return self._buffFlags:CheckFlag(flag)
end

function BuffComponent:SetFlag(flag)
    self._buffFlags:SetFlag(flag)
end

function BuffComponent:ResetFlag(flag)
    self._buffFlags:ResetFlag(flag)
end

--获取所有状态值
function BuffComponent:GetBuffValues()
    return self._buffValues
end

--获取状态值
function BuffComponent:GetBuffValue(key)
    return self._buffValues[key]
end

--设置状态值
function BuffComponent:SetBuffValue(key, value)
    self._buffValues[key] = value
end

--累加状态值
function BuffComponent:AddBuffValue(key, value)
    if not self._buffValues[key] then
        self._buffValues[key] = 0
    end
    self._buffValues[key] = self._buffValues[key] + value
    return self._buffValues[key]
end

function BuffComponent:SetActive(active)
    for i, inst in ipairs(self._buffArray) do
        inst:SetActive(active)
    end
end

--所有实例
---@return BuffInstance[]
function BuffComponent:GetBuffArray()
    return self._buffArray
end

--根据效果类型获取buffInstance
---@return BuffInstance[]
function BuffComponent:GetBuffArrayByBuffEffect(et)
    local ret = {}
    for i, buff in ipairs(self._buffArray) do
        if buff:GetBuffEffectType() == et and not buff:IsUnload() then
            ret[#ret + 1] = buff
        end
    end
    return ret
end

--根据效果类型获取第一个buffInstance
---@return BuffInstance
function BuffComponent:GetSingleBuffByBuffEffect(et)
    for i, buff in ipairs(self._buffArray) do
        if buff:GetBuffEffectType() == et and not buff:IsUnload() then
            return buff
        end
    end
    return nil
end

--判断是否有某id的buff
function BuffComponent:CheckHaveBuffById(buffId)
    for i, buff in ipairs(self._buffArray) do
        if buff:BuffID() == buffId then
            return true
        end
    end
    return false
end

--根据id获取buffinstance
---若身上有多个相同ID的Buff共存，只会返回第一个，可能会因此造成Bug
---@return BuffInstance
function BuffComponent:GetBuffById(buffId)
    for i, buff in ipairs(self._buffArray) do
        local cur_buffid = buff:BuffID()
        if cur_buffid == buffId and not buff:IsUnload() then
            return buff
        end
    end
    return nil
end

--根据buff类型获取buffInstance
---@return BuffInstance[]
function BuffComponent:GetBuffArrayByBuffType(type)
    local ret = {}
    for i, buff in ipairs(self._buffArray) do
        if buff:GetBuffType() == type then
            ret[#ret + 1] = buff
        end
    end
    return ret
end

--是否有某种buff效果
function BuffComponent:HasBuffEffect(et)
    for i, buff in ipairs(self._buffArray) do
        if buff:GetBuffEffectType() == et and not buff:IsUnload() then
            return true
        end
    end
    return false
end

---@param buffSource BuffSource
---@param buffInstance BuffInstance
function BuffComponent:AddBuffSource(buffSource, buffInstance)
    if not buffSource then
        return
    end

    for _buffSource, list in pairs(self._buffSourceList) do
        if _buffSource == buffSource then
            self:PrintBuffCmptLog(
                "AddBuff SourceType:",
                buffSource._sourceType,
                "SourceID:",
                buffSource._sourceID,
                " BuffID:",
                buffInstance:BuffID(),
                "BuffSeq:",
                buffInstance:BuffSeq()
            )
            table.insert(list, buffInstance)
            return
        end
    end

    self._buffSourceList[buffSource] = { buffInstance }
    self:PrintBuffCmptLog(
        "AddBuff SourceType:",
        buffSource._sourceType,
        "SourceID:",
        buffSource._sourceID,
        " BuffID:",
        buffInstance:BuffID(),
        "BuffSeq:",
        buffInstance:BuffSeq()
    )
end

function BuffComponent:UnLoadBuff(buffSource)
    if #self._buffSourceList == 0 then
        return
    end
    for _buffSource, list in pairs(self._buffSourceList) do
        if _buffSource == buffSource then
            for _, buffInstance in pairs(list) do
                buffInstance:Unload()
                self:PrintBuffCmptLog("UnLoad BuffID:", buffInstance:BuffID(), "BuffSeq:", buffInstance:BuffSeq())
            end
            return
        end
    end
end

---@return BuffSource
function BuffComponent:GetBuffSourceByBuffID(buffID)
    for _buffSource, list in pairs(self._buffSourceList) do
        for k, buffInstance in pairs(list) do
            if buffInstance:BuffID() == buffID then
                return _buffSource
            end
        end
    end
    return nil
end

---@param buffInstance BuffInstance
function BuffComponent:AddBuffInstance(buffInstance)
    table.insert(self._buffArray, buffInstance)
    --创建viewInstance
    local res = DataBuffAddResult:New(self._entity:GetID(),
        buffInstance:BuffSeq(),
        buffInstance:BuffID(),
        buffInstance:Context())
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, res)
    --触发加载事件
    buffInstance:Load()
end

function BuffComponent:RemoveBuffInstance(buffInstance)
    if table.icontains(self._buffArray, buffInstance) then
        table.removev(self._buffArray, buffInstance)
    end
end

---@return BuffInstance
function BuffComponent:GetBuffBySeq(buffSeq)
    for i, buff in ipairs(self._buffArray) do
        if buff:BuffSeq() == buffSeq then
            return buff
        end
    end
end

--移除某个buff
function BuffComponent:RemoveBuffBySeq(buffSeq, notice)
    for i = #self._buffArray, 1, -1 do
        local buff = self._buffArray[i]
        if buff:BuffSeq() == buffSeq then
            buff:Unload(notice)
            self._buffArray[i] = nil
            return
        end
    end
end

--移除某种类型的buff
function BuffComponent:RemoveBuffByEffectType(effectType, notice)
    local tSeqID = {}
    for i = #self._buffArray, 1, -1 do
        local buff = self._buffArray[i]
        if buff:GetBuffEffectType() == effectType then
            table.insert(tSeqID, buff:BuffSeq())
            buff:Unload(notice)
        end
    end
    return tSeqID
end

--删除标记为卸载的buffInstance
function BuffComponent:RemoveUnloadedBuffInstance()
    for i = #self._buffArray, 1, -1 do
        local buffInstance = self._buffArray[i]
        if buffInstance:IsUnload() then
            self:PrintBuffCmptLog("RemoveUnloadedBuffInstance entity=", self._entity:GetID(), " buffID=", buffInstance:BuffID())
            table.remove(self._buffArray, i)
        end
    end
end

--清空buffInstance
function BuffComponent:ClearAllBuffInstances()
    for i, buff in ipairs(self._buffArray) do
        buff:OnUnload(nil, true)
    end

    self._buffArray = {}
    self._buffFlags:Clear()
    self._buffValues = {}
end

function BuffComponent:HasDebuff()
    for i, buff in ipairs(self._buffArray) do
        local buffcfgdata = buff:BuffConfigData()
        if buffcfgdata:IsDebuff() then
            return true
        end
    end
    return false
end

function BuffComponent:GetCurHitIndex()
    return self._curHitIndex
end

function BuffComponent:AddHitIndex()
    self._curHitIndex = self._curHitIndex + 1
    return self._curHitIndex
end

---参数不是实际血量 是已经掉落过的配置血量
function BuffComponent:IsHPPercentHasDrop(hpPercent)
    for _, v in ipairs(self._hasDropHpPercent) do
        if v == hpPercent then
            return true
        end
    end
    return false
end

function BuffComponent:AddHasDropHpPercent(hpPercent)
    table.insert(self._hasDropHpPercent, hpPercent)
end

function BuffComponent:IsAlwaysLock()
    return self:GetBuffValue("LockHPAlways")
end

function BuffComponent:GetLockHPRoundIndex()
    return self._lockHpRoundIndex
end

function BuffComponent:GetLockGSMState()
    return self._lockGSMState
end

---判断是否能取消锁血
function BuffComponent:IsHPNeedUnLock(roundIndex, nowGSMState)
    if self:GetBuffValue("LockHPAlways") then
        return false
    end
    if roundIndex and self._lockHpRoundIndex ~= 0 and self._lockHpRoundIndex == roundIndex then
        if self._lockGSMState == GameStateID.MonsterTurn then
            if self:GetBuffValue("LockHPType") == LockHPType.MonsterTurnUnLock then
                return true
            end
            if self._lockGSMState == nowGSMState then
                return true
            end
        else
            return true
        end
    end
    return false
end

---判断是否被锁血
function BuffComponent:IsHPLock(roundIndex)
    if roundIndex and self._lockHpRoundIndex ~= 0 and self._lockHpRoundIndex == roundIndex then
        return true
    end
    return false
end

function BuffComponent:AddHpLockState(roundIndex, hpPercent, lockIndex, lockGSMState)
    self._lockHpRoundIndex = roundIndex
    table.insert(self._lockHpPercent, hpPercent)
    self._lockIndex = lockIndex
    self._lockGSMState = lockGSMState
end

function BuffComponent:GetHPLockIndex()
    return self._lockIndex
end

function BuffComponent:ResetHPLockState()
    self._lockHpRoundIndex = 0
    self._lockIndex = 0
    self._lockGSMState = 0
end

---@return boolean
function BuffComponent:HpIsHasLocked(hpPercent)
    if #self._lockHpPercent == 0 then
        return false
    end
    return table.icontains(self._lockHpPercent, hpPercent)
end

---判断宿主是否触发过锁血
function BuffComponent:HpHasLocked()
    return #self._lockHpPercent ~= 0
end

function BuffComponent:RecordUnlockHPIndex(index)
    self._unlockIndex[#self._unlockIndex + 1] = index
end

function BuffComponent:GetUnlockHPIndex()
    return self._unlockIndex
end

function BuffComponent:RecordLastUnlockHPRound(round)
    self._lastUnlockHpRound = round
end

function BuffComponent:GetLastUnlockHPRound()
    return self._lastUnlockHpRound
end

function BuffComponent:SaveArchivedData()
    local lockHpList = self:GetBuffValue("LockHPList")
    if lockHpList then
        local buffData = {}
        buffData._lockHpRoundIndex = self._lockHpRoundIndex
        buffData._lockGSMState = self._lockGSMState
        buffData._lockIndex = self._lockIndex
        buffData._lockHpPercent = self._lockHpPercent
        buffData._unlockIndex = self._unlockIndex
        return buffData
    end
    return nil
end

function BuffComponent:LoadArchivedData(buffData)
    if buffData then
        self._lockHpRoundIndex = buffData._lockHpRoundIndex
        self._lockGSMState = buffData._lockGSMState
        self._lockIndex = buffData._lockIndex
        self._lockHpPercent = buffData._lockHpPercent
        self._unlockIndex = buffData._unlockIndex or {}
    end
end

---是否是Buff被冻结状态
---被冻结的buff 不参与触发 不参与回合结算
function BuffComponent:IsBuffFreeze()
    return self:GetBuffValue("Freeze") == 1
end

function BuffComponent:PrintBuffCmptLog(...)
    if self._world and self._world:IsDevelopEnv() then
        Log.debug(...)
    end
end

function BuffComponent:GetLastEffectedLogicInfo(key)
    return self._lastEffectedInfo[key]
end

function BuffComponent:SetLastEffectedLogicInfo(key, info)
    self._lastEffectedInfo[key] = info
end

function BuffComponent:RemoveLastEffectedLogicInfo(key)
    self._lastEffectedInfo[key] = nil
end

--region 灰血相关
---
function BuffComponent:IsGreyHPEnabled()
    return self:GetBuffValue("GreyHPEnabled") == 1
end

---
function BuffComponent:SetGreyHPEnable(enabled)
    self:SetBuffValue("GreyHPEnabled", enabled and 1 or 0)
end

---
---@return number|nil 如果单位没有灰血条功能，这里会返回nil
function BuffComponent:GetGreyHPValue(safety)
    local v = self:GetBuffValue("GreyHPValue")
    if safety and (not v) then
        v = 0
    end
    return v
end

---
function BuffComponent:SetGreyHPValue(v)
    self:SetBuffValue("GreyHPValue", v)
end

---
function BuffComponent:ClearGreyHPValue()
    self:SetBuffValue("GreyHPValue", nil)
end

function BuffComponent:GetRecoverByMaxHPCountValue()
    local v = self:GetBuffValue("RecoverByMaxHPCount")
    if not v then
        v = 0
    end
    return v
end

function BuffComponent:SetRecoverByMaxHPCountValue(v)
    self:SetBuffValue("RecoverByMaxHPCount", v)
end

function BuffComponent:ClearRecoverByMaxHPCountValue()
    self:SetBuffValue("RecoverByMaxHPCount", nil)
end

function BuffComponent:SetPoisonByAttackCasterID(casterID)
    --只赋值一次，使用首次附加Buff的施法者ID
    if not self._poisonByAttackCasterID then
        self._poisonByAttackCasterID = casterID
    end
end

function BuffComponent:ClearPoisonByAttackCasterID()
    self._poisonByAttackCasterID = nil
end

function BuffComponent:GetPoisonByAttackCasterID()
    return self._poisonByAttackCasterID
end


--endregion

--region 诅咒血池相关
---
function BuffComponent:IsCurseHPEnabled()
    return self:GetBuffValue("CurseHPEnabled") == 1
end
function BuffComponent:GetCurseHPSourceEntityID()
    return self:GetBuffValue("CurseHPSourceEntityID")
end
---
function BuffComponent:SetCurseHPEnable(enabled)
    self:SetBuffValue("CurseHPEnabled", enabled and 1 or 0)
end
function BuffComponent:SetCurseHPSourceEntityID(entityID)
    self:SetBuffValue("CurseHPSourceEntityID", entityID)
end

---
function BuffComponent:GetCurseHPValue(safety)
    local v = self:GetBuffValue("CurseHPValue")
    if safety and (not v) then
        v = 0
    end
    return v
end

---
function BuffComponent:SetCurseHPValue(v)
    self:SetBuffValue("CurseHPValue", v)
end

---
function BuffComponent:ClearCurseHPValue()
    self:SetBuffValue("CurseHPValue", nil)
end
--endregion

---------------------------------------------------------------------
---entity
---------------------------------------------------------------------

---@return BuffComponent
function Entity:BuffComponent()
    return self:GetComponent(self.WEComponentsEnum.Buff)
end

---@return boolean
function Entity:HasBuff()
    return self:HasComponent(self.WEComponentsEnum.Buff)
end

function Entity:AddBuffComponent()
    local world = self:GetOwnerWorld()
    local index = self.WEComponentsEnum.Buff
    local component = BuffComponent:New(world)
    self:AddComponent(index, component)
end

function Entity:RemoveBuffComponent()
    if self:HasBuff() then
        self:RemoveComponent(self.WEComponentsEnum.Buff)
    end
end

function Entity:HasBuffFlag(flag)
    if not self:HasBuff() then
        return false
    end

    return self:BuffComponent():HasFlag(flag)
end
