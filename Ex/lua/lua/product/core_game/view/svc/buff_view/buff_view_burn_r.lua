--[[
    灼烧
]]
_class("BuffViewAddBurn", BuffViewBase)
BuffViewAddBurn = BuffViewAddBurn

function BuffViewAddBurn:PlayView(TT)
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:PlayDamageBuff(TT, self)
end

