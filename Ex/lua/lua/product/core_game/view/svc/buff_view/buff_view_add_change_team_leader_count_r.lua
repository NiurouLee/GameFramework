--[[
    修改换队长剩余次数
]]
_class("BuffViewAddChangeTeamLeaderCount", BuffViewBase)
BuffViewAddChangeTeamLeaderCount = BuffViewAddChangeTeamLeaderCount

function BuffViewAddChangeTeamLeaderCount:PlayView(TT)
    ---@type BuffResultAddChangeTeamLeaderCount
    local result = self:GetBuffResult()
    local newCount = result:GetNewCount()
    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.UIChangeTeamLeaderLeftCount, newCount)
end
