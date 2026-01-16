_class("BuffViewNumLockHP", BuffViewBase)
---@class BuffViewNumLockHP:BuffViewBase
BuffViewNumLockHP = BuffViewNumLockHP

function BuffViewNumLockHP:PlayView(TT)
    ---@type BuffResultNumLockHP
    local buffResult = self._buffResult
    local numLockHP = buffResult:GetNumLockHP()

    ---@type BuffViewComponent
    local buffView = self._entity:BuffView()
    buffView:SetBuffValue("NumLockHP", numLockHP)

    -- self._world:EventDispatcher():Dispatch(GameEventType.ChangeBuff)
end

function BuffViewNumLockHP:IsNotifyMatch(notify)
    ---@type BuffResultNumLockHP
    local buffResult = self._buffResult
    return true
end
