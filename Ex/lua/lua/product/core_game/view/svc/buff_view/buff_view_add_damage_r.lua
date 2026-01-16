--[[
    播放造成伤害的buff
]]
_class("BuffViewAddDamage", BuffViewBase)
BuffViewAddDamage = BuffViewAddDamage

function BuffViewAddDamage:PlayView(TT)
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:PlayDamageBuff(TT, self)
end
