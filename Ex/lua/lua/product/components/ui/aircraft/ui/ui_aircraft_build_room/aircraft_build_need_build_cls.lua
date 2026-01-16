--region AircrafBuildNeedCondition 风船建筑需要前提建筑类
---@class AircrafBuildNeedCondition:Object
_class("AircrafBuildNeedCondition", Object)
AircrafBuildNeedCondition = AircrafBuildNeedCondition

function AircrafBuildNeedCondition:Constructor()
    self._buildType = 0
    self._buildLv = 0
    self._buildCount = 0
end
function AircrafBuildNeedCondition:Init(buildType, buildLv, buildCount)
    self._buildType = buildType
    self._buildLv = buildLv
    self._buildCount = buildCount
end
