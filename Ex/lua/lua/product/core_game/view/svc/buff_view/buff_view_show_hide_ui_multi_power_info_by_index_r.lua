--[[
    改变星灵附加主动技
]]
_class("BuffViewShowHideUiMultiPowerInfoByIndex", BuffViewBase)
---@class BuffViewShowHideUiMultiPowerInfoByIndex : BuffViewBase
BuffViewShowHideUiMultiPowerInfoByIndex = BuffViewShowHideUiMultiPowerInfoByIndex

function BuffViewShowHideUiMultiPowerInfoByIndex:PlayView(TT)
    local pstId = self._buffResult:GetPetPstID()
    local uiIndex = self._buffResult:GetUiIndex()
    local bShow = self._buffResult:GetIsShow()
    --通知更换主动技
    GameGlobal:EventDispatcher():Dispatch(GameEventType.ShowHideUiMultiPowerInfoByIndex, pstId, uiIndex,bShow)
end
