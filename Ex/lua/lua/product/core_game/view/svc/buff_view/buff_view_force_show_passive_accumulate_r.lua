--[[
    强制显示被动技累积图标和数值
]]
---@class BuffViewForceShowPassiveAccumulate:BuffViewBase
_class("BuffViewForceShowPassiveAccumulate", BuffViewBase)
BuffViewForceShowPassiveAccumulate = BuffViewForceShowPassiveAccumulate

function BuffViewForceShowPassiveAccumulate:PlayView(TT)
    ---@type BuffResultForceShowPassiveAccumulate
    local buffResult = self._buffResult
    local buffLayerList = buffResult:GetBuffLayerList()
    local forceInitType = buffResult:GetForceInitType()
    local maxCount = buffResult:GetMaxLayerCount()
    local petPstID = self._entity:PetPstID():GetPstID()

    GameGlobal.EventDispatcher():Dispatch(GameEventType.ForceInitPassiveAccumulate, petPstID, buffLayerList, forceInitType, maxCount)
end