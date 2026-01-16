--[[
    流血
]]
_class("BuffViewAddBleed", BuffViewBase)
BuffViewAddBleed = BuffViewAddBleed

function BuffViewAddBleed:PlayView(TT)
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:PlayDamageBuff(TT, self)
end


