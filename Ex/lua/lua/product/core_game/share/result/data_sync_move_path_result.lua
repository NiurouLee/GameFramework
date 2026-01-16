--[[------------------------------------------------------------------------------------------
    DataSyncMovePathResult : 逻辑层通知播放表现层 同步移动的路径（早苗的机关）
]] --------------------------------------------------------------------------------------------


_class("DataSyncMovePathResult", Object)
---@class DataSyncMovePathResult: Object
DataSyncMovePathResult = DataSyncMovePathResult

function DataSyncMovePathResult:Constructor(entityID,movePath)
    self._entityID = entityID
    self._syncMovePathResult = movePath
end
function DataSyncMovePathResult:SetEntityID(entityID)
    self._entityID = entityID
end
function DataSyncMovePathResult:GetEntityID()
    return self._entityID
end

function DataSyncMovePathResult:SetSyncMovePathResult(res)
    self._syncMovePathResult = res
end

function DataSyncMovePathResult:GetSyncMovePathResult()
    return self._syncMovePathResult
end