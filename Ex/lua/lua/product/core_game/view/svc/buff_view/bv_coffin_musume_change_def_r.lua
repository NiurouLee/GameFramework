_class("BuffViewCoffinMusumeChangeDefenceByCandle", BuffViewBase)
---@class BuffViewCoffinMusumeChangeDefenceByCandle : BuffViewBase
BuffViewCoffinMusumeChangeDefenceByCandle = BuffViewCoffinMusumeChangeDefenceByCandle

function BuffViewCoffinMusumeChangeDefenceByCandle:PlayView(TT, notify)
    ---@type BuffResultCoffinMusumeChangeDefenceByCandle
    local buffResult = self._buffResult

    self._world:EventDispatcher():Dispatch(GameEventType.UpdateCoffinMusumeUIDef, buffResult)
end
