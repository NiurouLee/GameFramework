--[[------------------------------------------------------------------------------------------
    EffectHolderComponent : 
]] --------------------------------------------------------------------------------------------


_class("EffectHolderComponent", Object)
---@class EffectHolderComponent: Object
EffectHolderComponent = EffectHolderComponent

function EffectHolderComponent:Constructor()
    ---perment特效Entity的ID数组
    self._permanentEffectIDList = {}

    self._idleEffectIDList = {} ---idle特效Entity的ID数组
    self._weakEffectIDList = {} --虚弱特效Entity的ID数组
    self._effectIDEntityDic = {} --通过effect ID引用的特效字典

    self._dictEffectId = {} --key-number[]结构

    self._bindEffectId = {} --动态绑定的特效ID，用于存档恢复

    self._audio2PlayID = {} --配置音效ID和对应的PlayID

    --菲雅 仲胥 连线移动中添加的perment特效，结束后要清理，记录一下，避免清除其他特效
    self._chainMovePermanentEffectIDList = {}
    --[[
        注意！

        如果添加了新的特效存储，需要在EffectService:ClearEntityEffect中添加清理
        且特效销毁过后，对应的ID也要从这里清掉，否则会造成其他错误
    ]]

    self._replacedHolderEffectIDs = {}

    ---精英出生特效字典，key为特效ID，value为特效EntityID
    self._eliteEffIDDic = {}
end

function EffectHolderComponent:AddReplacedHolderEffectIDs(effectID, entityID)
    if not self._replacedHolderEffectIDs[effectID] then
        self._replacedHolderEffectIDs[effectID] = {}
    end
    table.insert(self._replacedHolderEffectIDs[effectID], entityID)
end

function EffectHolderComponent:GetReplacedHolderEffectIDs(effectID)
    return self._replacedHolderEffectIDs[effectID]
end

function EffectHolderComponent:ClearReplacedHolderEffectIDs(effectID)
    self._replacedHolderEffectIDs[effectID] = nil
end

function EffectHolderComponent:AttachPermanentEffect(effectEntityID)
    self._permanentEffectIDList[#self._permanentEffectIDList + 1] = effectEntityID
end
function EffectHolderComponent:AttachChainMovePermanentEffect(effectEntityID)
    self._chainMovePermanentEffectIDList[#self._chainMovePermanentEffectIDList + 1] = effectEntityID
end

function EffectHolderComponent:AttachIdleEffect(effectEntityID)
    self._idleEffectIDList[#self._idleEffectIDList + 1] = effectEntityID
end

---@param key string Charge，Palsy等
---@param effectEntityID number 常驻特效id
function EffectHolderComponent:AttachEffect(key, effectEntityID)
    if not self._dictEffectId then
        self._dictEffectId = {}
    end
    if not self._dictEffectId[key] then
        self._dictEffectId[key] = {}
    end
    table.insert(self._dictEffectId[key], effectEntityID)
end

function EffectHolderComponent:AttachWeakEffect(effectEntityID)
    self._weakEffectIDList[#self._weakEffectIDList + 1] = effectEntityID
end

function EffectHolderComponent:AttachEffectByEffectID(effectID, effectEntityID)
    if not self._effectIDEntityDic[effectID] then
        self._effectIDEntityDic[effectID] = {}
    end
    table.insert(self._effectIDEntityDic[effectID], effectEntityID)

    if table.icontains(BattleConst.MazeArchivedEffectID, effectID) then
        self:BindEffectID(effectID, effectEntityID)
    end
end

function EffectHolderComponent:GetIdleEffect()
    return self._idleEffectIDList
end

---@param key string Charge，Palsy等
---@return Entity[]
function EffectHolderComponent:GetEffectList(key)
    if self._dictEffectId then
        return self._dictEffectId[key]
    end
end

function EffectHolderComponent:ClearEffectList(key)
    if (not self._dictEffectId) or (not self._dictEffectId[key]) then
        return
    end

    self._dictEffectId[key] = nil
end

function EffectHolderComponent:GetDictEffectId()
    return self._dictEffectId
end

function EffectHolderComponent:GetWeakEffect()
    return self._weakEffectIDList
end

function EffectHolderComponent:GetPermanentEffect()
    return self._permanentEffectIDList
end
function EffectHolderComponent:GetChainMovePermanentEffect()
    return self._chainMovePermanentEffectIDList
end
function EffectHolderComponent:GetEffectIDEntityDic()
    return self._effectIDEntityDic
end

function EffectHolderComponent:GetEffectEntityIDByEffectID(effectID)
    return self._effectIDEntityDic[effectID]
end

function EffectHolderComponent:PostRemoved()
    --Detach All
end

function EffectHolderComponent:BindEffectID(effectID,effectEntityID)
    table.insert(self._bindEffectId, {effectID,effectEntityID})
end

function EffectHolderComponent:GetBindEffectID()
    local ret={}
    for i,v in ipairs(self._bindEffectId) do
        if self._entity._world:GetEntityByID(v[2]) and not table.icontains(ret,v[1]) then
            ret[#ret+1]=v[1]
        end
    end
    return ret
end

function EffectHolderComponent:GetBindEffectIDArray()
    local ret = {}
    for _, v in ipairs(self._bindEffectId) do
        table.insert(ret, v[2])
    end
    return ret
end

function EffectHolderComponent:AttachAudioID(audioID,playingID)
    if not self._audio2PlayID[audioID] then
        self._audio2PlayID[audioID]= {}
    end
    table.insert(self._audio2PlayID[audioID],playingID)
end

function EffectHolderComponent:GetAudioPlayingID(audioID)
    if not self._audio2PlayID[audioID] then
        return {}
    end
    return self._audio2PlayID[audioID]
end

function EffectHolderComponent:ClearAudioID(audioID)
    self._audio2PlayID[audioID] = {}
end

function EffectHolderComponent:ClearIdleEffectList() self._idleEffectIDList = {} end
function EffectHolderComponent:ClearWeakEffectList() self._weakEffectIDList = {} end
function EffectHolderComponent:ClearEffectIDEntityDic() self._effectIDEntityDic = {} end
function EffectHolderComponent:ClearDictEffectID() self._dictEffectId = {} end
function EffectHolderComponent:ClearBindEffectID() self._bindEffectId = {} end
--仅在destroy特效列表后用，同步从_permanentEffectIDList中清除
function EffectHolderComponent:ClearChainMovePermanentEffectIDListAfterDestroy()
    local permentList = {}
    for _, effID in ipairs(self._permanentEffectIDList) do
        if not table.icontains(self._chainMovePermanentEffectIDList, effID) then
            table.insert(permentList, effID)
        end
    end
    self._permanentEffectIDList = permentList
    self._chainMovePermanentEffectIDList = {}
end

function EffectHolderComponent:AddEliteEffID(effectID, entityID)
    if self._eliteEffIDDic[effectID] then
        ---每种精英特效均是唯一的，不存在同一个ID，多个实体对象的情况
        return
    end
    self._eliteEffIDDic[effectID] = entityID
end

function EffectHolderComponent:GetEliteEffEntityID(effectID)
    return self._eliteEffIDDic[effectID]
end

function EffectHolderComponent:GetEliteEffIDDic()
    return table.cloneconf(self._eliteEffIDDic)
end

function EffectHolderComponent:DeleteEliteEffIDDic(needDelEffIDList)
    local eliteDic = {}
    for effID, entityID in pairs(self._eliteEffIDDic) do
        if table.icontains(needDelEffIDList, effID) then
            table.removev(self._permanentEffectIDList, entityID)
        else
            eliteDic[effID] = entityID
        end
    end
    self._eliteEffIDDic = eliteDic
end

--------------------------------------------------------------------------------------------
--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return EffectHolderComponent
function Entity:EffectHolder()
    return self:GetComponent(self.WEComponentsEnum.EffectHolder)
end

function Entity:HasEffectHolder()
    return self:HasComponent(self.WEComponentsEnum.EffectHolder)
end

function Entity:AddEffectHolder()
    local index = self.WEComponentsEnum.EffectHolder
    local component = EffectHolderComponent:New()
    self:AddComponent(index, component)
end

function Entity:DetachEffect(effectEntity)
end

function Entity:ReplaceEffectHolder()
    local index = self.WEComponentsEnum.EffectHolder
    local component = EffectHolderComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemoveEffectHolder()
    if self:HasEffectHolder() then
        self:RemoveComponent(self.WEComponentsEnum.EffectHolder)
    end
end
