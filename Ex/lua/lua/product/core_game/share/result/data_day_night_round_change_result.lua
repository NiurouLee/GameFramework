--[[------------------------------------------------------------------------------------------
    DataDayNightRoundChangeResult : 昼夜 回合变化 切换
]] --------------------------------------------------------------------------------------------

_class("DataDayNightRoundChangeResult", Object)
---@class DataDayNightRoundChangeResult: Object
DataDayNightRoundChangeResult = DataDayNightRoundChangeResult
---
function DataDayNightRoundChangeResult:Constructor(curState,oldState,restRound)
    self._curState = curState
    self._oldState = oldState
    self._restRound = restRound
end
---
function DataDayNightRoundChangeResult:GetCurState()
    return self._curState
end
---
function DataDayNightRoundChangeResult:GetOldState()
    return self._oldState
end
---
function DataDayNightRoundChangeResult:GetRestRound()
    return self._restRound
end
