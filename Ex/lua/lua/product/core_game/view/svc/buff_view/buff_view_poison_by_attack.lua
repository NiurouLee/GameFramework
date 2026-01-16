--[[
    中毒buff：扣血使用施法者的攻击力
]]
---@class BuffViewAddPoisonByAttack:BuffViewBase
_class("BuffViewAddPoisonByAttack", BuffViewBase)
BuffViewAddPoisonByAttack = BuffViewAddPoisonByAttack

function BuffViewAddPoisonByAttack:PlayView(TT)
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:PlayDamageBuff(TT, self)
end
