--[[------------------------------------------------------------------------------------------
    ClientTimeService : 客户端时间服务
]] --------------------------------------------------------------------------------------------
require("time_base_service")

---@class ClientTimeService: TimeBaseService
_class("ClientTimeService", TimeBaseService)
ClientTimeService = ClientTimeService

function ClientTimeService:SetCurrentTime(curTimeMS)
    self._CurTimeMS = curTimeMS
end

function ClientTimeService:SetDeltaTime(deltaTimeMS)
    self._DeltaTimeMS = deltaTimeMS
    self._DeltaTime = deltaTimeMS / 1000
end
