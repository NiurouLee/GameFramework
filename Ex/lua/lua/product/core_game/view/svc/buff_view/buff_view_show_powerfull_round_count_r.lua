--[[
    用来修改UI上的技能已就绪图标 光灵米洛斯
]]
_class("BuffViewShowPowerfullRoundCountUI", BuffViewBase)
---@class BuffViewShowPowerfullRoundCountUI:BuffViewBase
BuffViewShowPowerfullRoundCountUI = BuffViewShowPowerfullRoundCountUI

function BuffViewShowPowerfullRoundCountUI:PlayView(TT)
    local bShow = self._buffResult:IsShow()
    local resDic = self._buffResult:GetResDic()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowPowerfullRoundCountUI, self._entity:PetPstID():GetPstID(),bShow,resDic)
end