--[[------------------------------------------------------------------------------------------
    时间服务基类
]]--------------------------------------------------------------------------------------------

_class( "TimeBaseService", BaseService )
---@class TimeBaseService:BaseService
TimeBaseService = TimeBaseService
function TimeBaseService:Constructor(world)
    self._FrameRate = 30
    self._DeltaTime = 1 / self._FrameRate
    self._DeltaTimeMS = self._DeltaTime * 1000
    self._CurTimeMS = 0
end

---获取距上一帧的间隔时间 单位:秒
---@return number 
function TimeBaseService:GetDeltaTime()
    return self._DeltaTime
end

---获取距上一帧的间隔时间 单位:毫秒
---@return number 
function TimeBaseService:GetDeltaTimeMs()
    return self._DeltaTimeMS
end

---获取当前时间 单位:毫秒
---@return number 
function TimeBaseService:GetCurrentTimeMs()
    return self._CurTimeMS
end
