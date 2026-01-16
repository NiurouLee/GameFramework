require("trigger_type")

---------------------------------------------------------------------------------------
--触发器的基类
_class("TriggerBase", Object)
---@class TriggerBase:Object
TriggerBase = TriggerBase

function TriggerBase:Constructor(owner, triggerCond)
    ---@type Entity
    self._owner = owner
    ---@type MainWorld
    self._world = owner._world
    self._triggerType = triggerCond[1]
    self._x = triggerCond[2]
    self._y = triggerCond[3]
    self._z = triggerCond[4]
    self._param = {}
    for i = 2, #(triggerCond) do
        table.insert(self._param, triggerCond[i])
    end
end

--通知类型
function TriggerBase:GetNotifyType()
    return self._owner:GetNotifyType()
end

--触发类型
function TriggerBase:GetTriggerType()
    return self._triggerType
end

function TriggerBase:OnNotify(notify)
end

--是否满足条件
function TriggerBase:IsSatisfied(notify)
    return false
end

function TriggerBase:Reset()
end

---@return Entity
function TriggerBase:GetOwnerEntity()
    return self._owner:GetOwnerEntity()
end

---@return MainWorld
function TriggerBase:GetWorld()
    return self._owner:GetWorld()
end

function TriggerBase:GetTriggerParamByIndex(paramIndex)
    local paramCount = #self._param
    if paramIndex > paramCount then 
        return nil
    end

    return self._param[paramIndex]
end

-----------------------------------------------------------------------------------
--触发队列
_class("CombinedTrigger", TriggerBase)
----@class CombinedTrigger:CombinedTrigger
CombinedTrigger = CombinedTrigger
function CombinedTrigger:Constructor(triggerOwner, notifyTypes, world)
    self._triggers = {}
    ---@type MainWorld
    self._world = world
    ----@type ITriggerOwner
    self._triggerOwner = triggerOwner
    self._notifyType = notifyTypes
end

function CombinedTrigger:GetNotifyType()
    return self._notifyType
end

function CombinedTrigger:AddTrigger(trigger)
    table.insert(self._triggers, trigger)
end

function CombinedTrigger:GetTriggers()
    return self._triggers
end

function CombinedTrigger:OnNotifyWrapper(notify)
    local notifyList = self:GetNotifyType()
    for k, notifyType in ipairs(notifyList) do
        if notify:GetNotifyType() == notifyType then
            for i, trigger in ipairs(self._triggers) do
                trigger:OnNotify(notify)
            end
            return
        end
    end
end

--是否匹配回合
function CombinedTrigger:CheckNotifyGameTurn(notify)
    if self._world:MatchType() ~= MatchType.MT_BlackFist then
        return true
    end

    for i, trigger in ipairs(self._triggers) do
        if trigger:GetTriggerType() == TriggerType.DonotCheckGameTurn then
            return true
        end
    end

    --判断当前是哪个player的回合
    local ownerEntity = self._triggerOwner:GetOwnerEntity()
    if notify:NeedCheckGameTurn() and ownerEntity:HasGameTurn() then
        local ownerEntityTurn = ownerEntity:GameTurn():GetGameTurn()
        --敌方回合触发
        if notify:GetNotifyType() == NotifyType.EnemyTurnStart or notify:GetNotifyType() == NotifyType.EnemyTurnEnd then
            local enemyTurn = notify:GetNotifyEntity():GameTurn():GetGameTurn()
            if enemyTurn == ownerEntityTurn then --小丑不能是自己
                return false
            end
        else
            --正常是自己的回合触发
            if self._world:GetGameTurn() ~= ownerEntityTurn then
                --Log.debug('CombinedTrigger owner entity is not in game turn! entityID=',ownerEntity:GetID())
                return false
            end
        end
    end

    return true
end

function CombinedTrigger:IsSatisfied(notify)
    if not self:CheckNotifyGameTurn(notify) then
        return false
    end
    for i, trigger in ipairs(self._triggers) do
        if not trigger:IsSatisfied(notify) then
            return false
        end
    end
    return true
end

function CombinedTrigger:Reset()
    for i, trigger in ipairs(self._triggers) do
        trigger:Reset()
    end
end

--触发类型
function CombinedTrigger:GetTriggerOwner()
    return self._triggerOwner
end

--触发
function CombinedTrigger:OnTrigger(notify)
    self._triggerOwner:OnTrigger(notify, self._triggers)
end

function CombinedTrigger:SetActive(active)
    self._active = active
end

function CombinedTrigger:IsActive()
    return self._active
end

---@return Entity
function CombinedTrigger:GetOwnerEntity()
    return self._triggerOwner:GetOwnerEntity()
end

function CombinedTrigger:GetWorld()
    return self._world
end

-----------------------------------------------------------------------------------
--计数类的触发器
_class("TriggerCount", TriggerBase)
---@class TriggerCount:TriggerBase
TriggerCount = TriggerCount
function TriggerCount:Constructor()
    self._count = 0
end

function TriggerCount:SetCount(val)
    self._count = val
end

function TriggerCount:AddCount(val)
    self._count = self._count + val
end

function TriggerCount:IsSatisfied(notify)
    return self._count >= self._x
end

function TriggerCount:Reset()
    self._count = 0
end
----------------------------------------------------------------------------
--不触发
_class("TTNone", TriggerBase)
---@class TTNone:TriggerBase
TTNone = TTNone

function TTNone:IsSatisfied(notify)
    return false
end

--无条件触发器
_class("TTAlways", TriggerBase)
---@class TTAlways:TriggerBase
TTAlways = TTAlways

function TTAlways:IsSatisfied(notify)
    return true
end

--通知目标是自己
_class("TTNotifyMe", TriggerBase)
---@class TTNotifyMe:TriggerBase
TTNotifyMe = TTNotifyMe

---@param notify INotifyBase
function TTNotifyMe:IsSatisfied(notify)
    local owner = self:GetOwnerEntity()
    if notify:GetNotifyType() == NotifyType.CoffinMusumeSkillChangeLight then
        return table.icontains(notify:GetSelectLightID(), owner:GetID())
    end
    local entity = notify:GetNotifyEntity()
    return owner == entity
end

--概率触发器
_class("TTProb", TriggerBase)
---@class TTProb:TriggerBase
TTProb = TTProb

function TTProb:IsSatisfied(notify)
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    local r = randomSvc:LogicRand()
    return r < self._x
end

--通知目标是自己  并且  概率触发
_class("TTNotifyMeProb", TriggerBase)
---@class TTNotifyMeProb:TriggerBase
TTNotifyMeProb = TTNotifyMeProb

function TTNotifyMeProb:IsSatisfied(notify)
    local owner = self:GetOwnerEntity()
    local entity = notify:GetNotifyEntity()
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    local r = randomSvc:LogicRand()
    return owner == entity and r < self._x
end

--概率触发，概率=参数×层数
---@class TTProbMultiplyLayer:TriggerBase
_class("TTProbMultiplyLayer", TriggerBase)
TTProbMultiplyLayer = TTProbMultiplyLayer

function TTProbMultiplyLayer:IsSatisfied(notify)
    local buffId = self._x
    local rateParam = self._y
    local owner = self:GetOwnerEntity()
    local cBuff = owner:BuffComponent()
    local layerCount = 0
    local instance = cBuff:GetBuffById(buffId)
    if instance then
        local layerName = instance:GetBuffLayerName()
        layerCount = cBuff:GetBuffValue(layerName) or 0
    end
    local rate = layerCount * rateParam
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    local r = randomSvc:LogicRand()
    return r < rate
end

--自己的回合
_class("TTMyTurn", TriggerBase)
TTMyTurn = TTMyTurn

function TTMyTurn:IsSatisfied(notify)
    local e = self:GetOwnerEntity()
    if e:HasMonsterID() and notify:GetNotifyType() == NotifyType.MonsterTurnStart then
        return true
    end
    if (e:HasPetPstID() or e:HasTeam()) and notify:GetNotifyType() == NotifyType.PlayerTurnStart then
        return true
    end
    return false
end

--判断buff层数
---@class TTLayerCount:TriggerBase
_class("TTLayerCount", TriggerBase)
TTLayerCount = TTLayerCount

function TTLayerCount:IsSatisfied(notify) --buffId为_x的层数达到_y时，返回true
    local buffId = self._x --buffId
    local maxLayerCount = self._y --最大层数
    local e = self:GetOwnerEntity()
    local cBuff = e:BuffComponent()
    local layerCount = 0
    local instance = cBuff:GetBuffById(buffId)
    if instance then
        local layerName = instance:GetBuffLayerName()
        layerCount = cBuff:GetBuffValue(layerName) or 0
    end
    return layerCount >= maxLayerCount
end

--buff层数是否满足一种比较关系
---@class TTCompareLayerCount:TriggerBase
_class("TTCompareLayerCount", TriggerBase)
TTCompareLayerCount = TTCompareLayerCount

function TTCompareLayerCount:IsSatisfied(notify)
    local compareFlag = self._x --比较操作枚举
    local buffId = self._y --buffId
    local count = self._z --配置的层数
    local e = self:GetOwnerEntity()
    if e:HasDeadMark() then
        return false
    end

    ---@type BuffComponent
    local cBuff = e:BuffComponent()

    ---第四个参数是count参数类型，没有配就是默认的第三个参数，固定值
    ---配置成1，表示count取另外一个buffID的count
    local countParamType = self:GetTriggerParamByIndex(4)
    if countParamType and countParamType == 1 then 
        ---这种模式下，第5个参数代表取其他buff的层数
        local targetBuffID = self:GetTriggerParamByIndex(5)
        ---@type BuffInstance
        local instance = cBuff:GetBuffById(targetBuffID)
        if instance then
            local layerName = instance:GetBuffLayerName()
            count = cBuff:GetBuffValue(layerName) or 0
        end
    end

    local layerCount = 0
    local instance = cBuff:GetBuffById(buffId)
    if instance then
        local layerName = instance:GetBuffLayerName()
        layerCount = cBuff:GetBuffValue(layerName) or 0
    end
    local satisfied = false
    if compareFlag == ComparisonOperator.EQ then --eq
        satisfied = layerCount == count
    elseif compareFlag == ComparisonOperator.NE then --ne
        satisfied = layerCount ~= count
    elseif compareFlag == ComparisonOperator.GT then --gt
        satisfied = layerCount > count
    elseif compareFlag == ComparisonOperator.GE then --ge
        satisfied = layerCount >= count
    elseif compareFlag == ComparisonOperator.LT then --lt
        satisfied = layerCount < count
    elseif compareFlag == ComparisonOperator.LE then --le
        satisfied = layerCount <= count
    end
    return satisfied
end

--通知的buff层数变化是否满足一种比较关系
---@class TTCompareLayerChange:TriggerBase
_class("TTCompareLayerChange", TriggerBase)
TTCompareLayerChange = TTCompareLayerChange

function TTCompareLayerChange:IsSatisfied(notify)
    local compareFlag = self._x --比较操作枚举
    local count = self._y --配置的层数
    local change = notify:GetChangeLayer()

    local satisfied = false
    if compareFlag == ComparisonOperator.EQ then --eq
        satisfied = change == count
    elseif compareFlag == ComparisonOperator.NE then --ne
        satisfied = change ~= count
    elseif compareFlag == ComparisonOperator.GT then --gt
        satisfied = change > count
    elseif compareFlag == ComparisonOperator.GE then --ge
        satisfied = change >= count
    elseif compareFlag == ComparisonOperator.LT then --lt
        satisfied = change < count
    elseif compareFlag == ComparisonOperator.LE then --le
        satisfied = change <= count
    end
    return satisfied
end
