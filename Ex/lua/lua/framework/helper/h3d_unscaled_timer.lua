--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    计时器通用类，可以延迟一段时间回调（不受时间缩放影响）
**********************************************************************************************
]] --------------------------------------------------------------------------------------------

---@class H3DUnscaledTimer:H3DTimer
require "h3d_timer"
_class("H3DUnscaledTimer", H3DTimer)
H3DUnscaledTimer = H3DUnscaledTimer
function H3DUnscaledTimer:Constructor()
end

function H3DUnscaledTimer:_GetCurrentTime()
    return GameGlobal:GetInstance():GetCurrentUnscaledTime()
end
