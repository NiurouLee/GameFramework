--[[------------------------------------------------------------------------------------------
    TimeService : 服务端时间
]] --------------------------------------------------------------------------------------------

---@class TimeService: TimeBaseService
_class("TimeService", TimeBaseService)
TimeService=TimeService

--每帧更新
function TimeService:SetCurrentTime(curTimeMS,deltaTimeMS)
    self._CurTimeMS = curTimeMS
    self._DeltaTimeMS = deltaTimeMS
    self._DeltaTime = deltaTimeMS / 1000
end

function TimeService:SetCurrentTime(curTimeMS)
    self._DeltaTimeMS = curTimeMS - self._CurTimeMS
    self._DeltaTime = self._DeltaTimeMS / 1000

    self._CurTimeMS = curTimeMS
end