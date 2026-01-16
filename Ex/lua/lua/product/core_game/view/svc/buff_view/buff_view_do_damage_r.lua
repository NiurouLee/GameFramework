--[[
    通过公式造成伤害的buff，表现就是刷血条+飘字
]]
_class("BuffViewDoDamage", BuffViewBase)
BuffViewDoDamage = BuffViewDoDamage

function BuffViewDoDamage:PlayView(TT)
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:PlayDamageBuff(TT, self)
end

function BuffViewDoDamage:IsNotifyMatch(notify)
    ---@type BuffResultDamage
    local result = self._buffResult
    ---@type Entity
    local entity = self._entity

    if notify:GetNotifyType() == NotifyType.MonsterMoveOneFinish then
        return entity:GetID() == notify:GetNotifyEntity():GetID() and result:GetWalkPos() == notify:GetWalkPos()
    end
end
