--[[
    强制显示被动技累积图标和数值
]]
---@class BuffViewShowPassiveAccumulateOverload:BuffViewBase
_class("BuffViewShowPassiveAccumulateOverload", BuffViewBase)
BuffViewShowPassiveAccumulateOverload = BuffViewShowPassiveAccumulateOverload

function BuffViewShowPassiveAccumulateOverload:PlayView(TT)
    ---@type BuffResultShowPassiveAccumulateOverload
    local buffResult = self._buffResult
    local isShowOverload = buffResult:IsOverLoadShow()
    local petPstID = self._entity:PetPstID():GetPstID()

    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowOverloadPassiveAccumulate, petPstID, isShowOverload)
end
