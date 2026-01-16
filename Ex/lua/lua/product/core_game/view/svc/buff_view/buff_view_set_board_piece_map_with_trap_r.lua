--[[

]]
_class("BuffViewSetBoardPieceMapWithTrap", BuffViewBase)
---@class BuffViewSetBoardPieceMapWithTrap : BuffViewBase
BuffViewSetBoardPieceMapWithTrap = BuffViewSetBoardPieceMapWithTrap

function BuffViewSetBoardPieceMapWithTrap:PlayView(TT)
end

--是否匹配参数
function BuffViewSetBoardPieceMapWithTrap:IsNotifyMatch(notify)
    ---@type BuffResultSetBoardPieceMapWithTrap
    local result = self._buffResult
    return true
end
