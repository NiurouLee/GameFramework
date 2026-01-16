--[[
    通过公式造成伤害的buff，表现就是刷血条+飘字
]]
_class("BuffViewDamageByBodyAreaPieceCount", BuffViewBase)
BuffViewDamageByBodyAreaPieceCount = BuffViewDamageByBodyAreaPieceCount

function BuffViewDamageByBodyAreaPieceCount:PlayView(TT)
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:PlayDamageBuff(TT, self)
end

function BuffViewDamageByBodyAreaPieceCount:IsNotifyMatch(notify)
    ---@type BuffResultDamage
    local result = self._buffResult
    ---@type Entity
    local entity = self._entity

    if notify:GetNotifyType() == NotifyType.BuffLoad then
        return entity:GetID() == notify:GetNotifyEntity():GetID()
    end

    return true
end
