--[[
    刷新血量上自爆层数的显示
]]
_class("BuffViewHPBombLayer", BuffViewBase)
BuffViewHPBombLayer = BuffViewHPBombLayer

function BuffViewHPBombLayer:PlayView(TT)
    local entityID = self._buffResult:GetEntityID()
    local layerCount = self._buffResult:GetLayerCount()

    self._world:EventDispatcher():Dispatch(GameEventType.HPBombLayer, entityID, layerCount)
end
