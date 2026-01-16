--[[
    修改机关能量表现
]]
_class("BuffViewChangeTrapPower", BuffViewBase)
BuffViewChangeTrapPower = BuffViewChangeTrapPower

function BuffViewChangeTrapPower:PlayView(TT)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.TrapPowerChange)
end
