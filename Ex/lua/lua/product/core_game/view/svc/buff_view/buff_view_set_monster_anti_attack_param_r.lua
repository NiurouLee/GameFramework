--[[
    表现
]]
---@class BuffViewSetMonsterAntiAttackParam : BuffViewBase
_class("BuffViewSetMonsterAntiAttackParam", BuffViewBase)
BuffViewSetMonsterAntiAttackParam = BuffViewSetMonsterAntiAttackParam

--是否匹配参数
function BuffViewSetMonsterAntiAttackParam:IsNotifyMatch(notify)
    ---@type BuffResultSetMonsterAntiAttackParam
    local result = self._buffResult
    local entityID = result:GetEntityID()

    --主动技反制这里传的是光灵
    -- if notify.GetNotifyEntity and notify:GetNotifyEntity():GetID() ~= entityID then
    --     return false
    -- end

    return true
end

function BuffViewSetMonsterAntiAttackParam:PlayView(TT, notify)
    ---@type BuffResultSetMonsterAntiAttackParam
    local result = self._buffResult
    local entityID = result:GetEntityID()

    GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateAntiActiveSkill, entityID)
end
