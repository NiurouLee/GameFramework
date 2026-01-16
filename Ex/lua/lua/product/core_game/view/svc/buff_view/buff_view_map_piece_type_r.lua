--[[

]]
_class("BuffViewMapPieceType", BuffViewBase)
---@class BuffViewMapPieceType : BuffViewBase
BuffViewMapPieceType = BuffViewMapPieceType

function BuffViewMapPieceType:PlayView(TT)
end

--是否匹配参数
function BuffViewMapPieceType:IsNotifyMatch(notify)
    ---@type BuffResultMapPieceType
    local result = self._buffResult
    return true
end
