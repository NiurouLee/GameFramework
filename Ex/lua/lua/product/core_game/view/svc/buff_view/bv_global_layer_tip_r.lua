_class("BuffViewGlobalLayerTipShow", BuffViewBase)
---@class BuffViewGlobalLayerTipShow : BuffViewBase
BuffViewGlobalLayerTipShow = BuffViewGlobalLayerTipShow

function BuffViewGlobalLayerTipShow:PlayView(TT)
    self._world:EventDispatcher():Dispatch(GameEventType.UIInitGlobalLayerTipInfo, self._buffResult)
end

_class("BuffViewGlobalLayerTipHide", BuffViewBase)
---@class BuffViewGlobalLayerTipHide : BuffViewBase
BuffViewGlobalLayerTipHide = BuffViewGlobalLayerTipHide

function BuffViewGlobalLayerTipHide:PlayView(TT)
    self._world:EventDispatcher():Dispatch(GameEventType.UIHideGlobalLayerTipInfo)
end

_class("BuffViewGlobalLayerTipUpdate", BuffViewBase)
---@class BuffViewGlobalLayerTipUpdate : BuffViewBase
BuffViewGlobalLayerTipUpdate = BuffViewGlobalLayerTipUpdate

function BuffViewGlobalLayerTipUpdate:PlayView(TT)
    self._world:EventDispatcher():Dispatch(GameEventType.UIUpdateGlobalLayerTipInfo, self._buffResult)
end
