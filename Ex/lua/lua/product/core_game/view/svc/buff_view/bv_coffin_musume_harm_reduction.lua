_class("BuffViewCoffinMusumeHarmReduction", BuffViewBase)
---@class BuffViewCoffinMusumeHarmReduction : BuffViewBase
BuffViewCoffinMusumeHarmReduction = BuffViewCoffinMusumeHarmReduction

function BuffViewCoffinMusumeHarmReduction:PlayView(TT, notify)
    ---@type BuffResultCoffinMusumeHarmReductionAndAttack
    local buffResult = self._buffResult

    self._world:EventDispatcher():Dispatch(GameEventType.UpdateCoffinMusumeUIDef, buffResult)
end
