--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    计时器通用类，可以延迟一段时间回调
**********************************************************************************************
]] --------------------------------------------------------------------------------------------

---@class TimerTriggerCount
local TimerTriggerCount = {
    Once = 1,
    Infinite = 99999999
}
_enum("TimerTriggerCount", TimerTriggerCount)

_class("H3DTimer", Object)
---@class H3DTimer:Object
H3DTimer = H3DTimer
function H3DTimer:Constructor(world)
    ---@type MainWorld
    self._world = world

    self.eventQueue = Heap:New(Heap.CPM_CUSTOM, H3DTimerEvent.PriorityComparer)
    self._newEventList = ArrayList:New()
    self._delEventList = ArrayList:New()    
end

---添加事件
---@param delayMS 延迟时间
---@param func 对象的函数
---@param ... 函数的参数
---@return H3DTimerEvent
function H3DTimer:AddEvent(delayMS, func, ...)
    return self:AddEventTimes(delayMS, 1, func, ...)
end
function H3DTimer:AddEventTimes(delayMS, times, func, ...)
    local curTime = self:_GetCurrentTime()
    local event = H3DTimerEvent:New(curTime, delayMS, times, func, ...)
    self._newEventList:PushBack(event)
    return event
end
---取消事件
---@param event H3DTimerEvent
function H3DTimer:CancelEvent(event)
    event:Cancel()
    if self._newEventList:Remove(event) == -1 then
        if (event._heap_index < 0 and event._Complete == false) then
            Log.error("H3DTimer:CancelEvent _Complete ==false error index ", event._heap_index, Log.traceback())
        elseif (event._heap_index > 0 and event._Complete == true) then
            Log.error("H3DTimer:CancelEvent _Complete ==true error index ", event._heap_index, Log.traceback())
        end
        self._delEventList:PushBack(event)
    end
end

function H3DTimer:_GetCurrentTime()
    if self._world then
        ---@type TimeService
        local timeService = self._world:GetService("Time")
        return timeService:GetCurrentTimeMs()
    else
        return GameGlobal:GetInstance():GetCurrentTime()
    end
end

function H3DTimer:Update(deltaTimeMS)
    --处理新增
    local newevent_size = self._newEventList:Size()
    if (self._newEventList:Size() > 0) then
        for i = 1, self._newEventList:Size() do
            local con = self._newEventList:GetAt(i)
            if con:IsCancel() == false then
                self.eventQueue:Enqueue(con)
            end
        end
        self._newEventList:Clear()
    end

    local delevent_size = self._delEventList:Size()
    --处理删除
    if (self._delEventList:Size() > 0) then
        for i = 1, self._delEventList:Size() do
            local con = self._delEventList:GetAt(i)
            self.eventQueue:Remove(con)
        end
        self._delEventList:Clear()
    end

    local queue = self.eventQueue
    local currentTime = self:_GetCurrentTime()

    --[[
    测试时间精确性
    local intTime = (currentTime - currentTime % 1000) / 1000
    if not self.lastIntTime then
        self.lastIntTime = intTime
    end
    if self.lastIntTime ~= intTime then
        Log.debug("H3DTimer current time：" .. currentTime / 1000)
        self.lastIntTime = intTime
    end
    --]]
    local queue_size = self.eventQueue:Size()
    while true do
        local event = queue:Peek()
        if not event or event.nextExecutionTime > currentTime then
            return
        end

        queue:Dequeue()
        if event:IsCancel() == false then
            event:Complete()
            event:Call()
            if (event:ReduceTimes() > 0) then
                event:Reset(self:_GetCurrentTime())
                self._newEventList:PushBack(event)
            else
            end
        else
            Log.error("H3dTimererror IsCancel true ")
        end
    end

    if self._last_update_time == nil then
        self._last_update_time = 0
    end
    if self._cur_time == nil then
        self._cur_time = 0
    end
    self._cur_time = self._cur_time+deltaTimeMS
    if( self._cur_time - self._last_update_time < 0000) then
        return 
    end
    self._last_update_time = self._cur_time
    Log.debug("time size queue_size ",queue_size," newevent_size ",newevent_size," delevent_size ",delevent_size)

end ---@class H3DTimerEvent

function H3DTimer:Clear()
    self._newEventList:Clear()
    self._delEventList:Clear()
    self.eventQueue:Clear()
end

--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    具体的计时事件
**********************************************************************************************
]]
_class("H3DTimerEvent", Object)
H3DTimerEvent = H3DTimerEvent
function H3DTimerEvent:Constructor(currentTime, delayMS, times, func, ...)
    self._heap_index = -1
    self._Complete = false
    self._insertion_index = -1
    self._times = times
    --进入队列的时间
    self.addTime = currentTime
    self._delayMs = delayMS
    -- 下次执行的时间
    self.nextExecutionTime = currentTime + delayMS or 0
    self._cancel = false
    self.callback = GameHelper:GetInstance():CreateCallback(func, ...)
end
function H3DTimerEvent:Cancel()
    self._cancel = true
end
function H3DTimerEvent:IsCancel()
    return self._cancel
end
function H3DTimerEvent:Reset(currentTime)
    self._heap_index = -1
    self._insertion_index = -1
    self._Complete = false
    --进入队列的时间
    self.addTime = currentTime
    -- 下次执行的时间
    self.nextExecutionTime = currentTime + self._delayMs or 0
end
function H3DTimerEvent:GetTimes()
    return self._times
end
function H3DTimerEvent:ReduceTimes()
    self._times = self._times - 1
    return self._times
end
function H3DTimerEvent:Call(...)
    if self.callback then
        self.callback:Call(...)
    end
end
function H3DTimerEvent:Complete()
    self._Complete = true
end
H3DTimerEvent.PriorityComparer = function(a, b)
    if a.nextExecutionTime < b.nextExecutionTime then
        return 1
    elseif a.nextExecutionTime > b.nextExecutionTime then
        return -1
    else
        return 0
    end
end
