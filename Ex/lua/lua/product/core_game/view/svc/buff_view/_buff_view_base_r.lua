--[[
    播放buff表现
]]
_class("BuffViewBase", Object)
---@class BuffViewBase:Object
BuffViewBase = BuffViewBase

---@param viewInstance BuffViewInstance
function BuffViewBase:Constructor(viewInstance, buffResult, viewName, triggers, notify)
	---@type BuffViewInstance
    self._viewInstance = viewInstance
    self._buffResult = buffResult
    ---@type MainWorld
    self._world = viewInstance:World()
    ---@type Entity
    self._entity = viewInstance:Entity()
    self._viewName = viewName
    self._triggers = triggers
    self._notify = notify
end

function BuffViewBase:BuffViewInstance()
    return self._viewInstance
end

function BuffViewBase:GetBuffResult()
    return self._buffResult
end
---@return Entity
function BuffViewBase:Entity()
    return self._entity
end
---@return MainWorld
function BuffViewBase:World()
    return self._world
end

function BuffViewBase:ViewName()
    return self._viewName
end

function BuffViewBase:ViewParams()
    return self._viewInstance:BuffConfigData():GetViewParams()
end

function BuffViewBase:GetNotify()
    return self._notify
end

function BuffViewBase:GetTriggers()
    return self._triggers
end

function BuffViewBase:HasTriggerType(triggerType)
    if not self._triggers then 
        return false
    end
    
    for _, trigger in ipairs(self._triggers) do
        if triggerType == trigger:GetTriggerType() then
            return true
        end
    end
    return false
end

--是否匹配参数
function BuffViewBase:IsNotifyMatch(notify)
    return true
end

--必然检查的通知和触发条件
function BuffViewBase:CheckNotifyAndTriggers(notify)
    local notifyType = notify:GetNotifyType()
    --连锁技表现需要检查次数
    if notify.GetChainSkillIndex then
        if notify:GetChainSkillIndex() ~= self._notify:GetChainSkillIndex() then
            return false
        end
    end
    --检查通知目标是自己
    if self:HasTriggerType(TriggerType.NotifyMe) then
        if notify:GetNotifyEntity() ~= self._entity then
            return false
        end
    end
    return self:IsNotifyMatch(notify)
end

function BuffViewBase:PlayView(TT)
end
