--[[
    播放特效
]]
_class("BuffViewPlayEffect", BuffViewBase)
BuffViewPlayEffect = BuffViewPlayEffect

function BuffViewPlayEffect:PlayView(TT)
    ---@type BuffResultPlayEffect
    local buffResult = self._buffResult

    local playerEntity = self._world:Player():GetCurrentTeamEntity()
    local effectID = buffResult:GetEffectID()
    if effectID then
        ---@type EffectService
        local effectService = self._world:GetService("Effect")
        local effectEntity = effectService:CreateEffect(effectID, playerEntity)
    -- YIELD(TT, 1000)
    end
end
