--[[
    通过公式造成伤害的buff，表现就是刷血条+飘字
]]
_class("BuffViewDamageByMoveAndBuffLayer", BuffViewBase)
BuffViewDamageByMoveAndBuffLayer = BuffViewDamageByMoveAndBuffLayer

function BuffViewDamageByMoveAndBuffLayer:PlayView(TT)
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:PlayDamageBuff(TT, self)
end

function BuffViewDamageByMoveAndBuffLayer:IsNotifyMatch(notify)
    ---@type BuffResultDamage
    local result = self._buffResult
    ---@type Entity
    local entity = self._entity

    if notify:GetNotifyType() == NotifyType.MonsterMoveOneFinish then
        return entity:GetID() == notify:GetNotifyEntity():GetID() and result:GetWalkPos() == notify:GetWalkPos()
    end
    if notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveEnd then
        return result:GetWalkPos() == notify:GetPos()
    end

    return true
end
