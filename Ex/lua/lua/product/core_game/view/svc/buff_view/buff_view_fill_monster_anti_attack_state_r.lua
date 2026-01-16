--[[
    表现
]]
---@class BuffViewFillMonsterAntiAttackStat : BuffViewBase
_class("BuffViewFillMonsterAntiAttackStat", BuffViewBase)
BuffViewFillMonsterAntiAttackStat = BuffViewFillMonsterAntiAttackStat

--是否匹配参数
function BuffViewFillMonsterAntiAttackStat:IsNotifyMatch(notify)
    ---@type FillMonsterAntiAttackStat
    local result = self._buffResult
    local entityID = result:GetEntityID()
    return true
end

function BuffViewFillMonsterAntiAttackStat:PlayView(TT, notify)
    ---@type FillMonsterAntiAttackStat
    local result = self._buffResult
    local entityID = result:GetEntityID()

    GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateAntiActiveSkill, entityID)
end
