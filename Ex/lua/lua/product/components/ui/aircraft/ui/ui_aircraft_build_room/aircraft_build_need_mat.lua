--region AircrafBuildNeedMat 风船建筑升级需要材料类
---@class AircrafBuildNeedMat:Object
_class("AircrafBuildNeedMat", Object)
AircrafBuildNeedMat = AircrafBuildNeedMat

function AircrafBuildNeedMat:Constructor()
    self._matID = 0
    self._count = 0
end
function AircrafBuildNeedMat:Init(matID, count)
    self._matID = matID
    self._count = count
end
