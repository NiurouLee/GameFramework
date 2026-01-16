--[[
    播放爆炸buff
]]
_class("BuffViewAddExplode", BuffViewBase)
BuffViewAddExplode = BuffViewAddExplode

--现在怀疑有combo数逻辑表现对不上的问题
function BuffViewAddExplode:IsNotifyMatch(notify)
    local combo = self._world:GetService("RenderBattle"):GetComboNum()
    Log.debug('BuffViewAddExplode:IsNotifyMatch() show combo=',combo,' view combo=',self._buffResult.combo)
    return combo >= self._buffResult:GetCombo()
end

function BuffViewAddExplode:PlayView(TT, notify)
    local effectService = self._world:GetService("Effect")
    local effectID = self:ViewParams().ExecEffectID
    effectService:CreateEffect(effectID, notify:GetDefenderEntity())
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:PlayDamageBuff(TT, self)
end
