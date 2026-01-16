_class("BuffViewCoffinMusumeSetCandleLight", BuffViewBase)
---@class BuffViewCoffinMusumeSetCandleLight : BuffViewBase
BuffViewCoffinMusumeSetCandleLight = BuffViewCoffinMusumeSetCandleLight

function BuffViewCoffinMusumeSetCandleLight:PlayView(TT, notify)
    local effectID = self:ViewParams().ExecEffectID
    ---@type Entity
    local e = self:Entity()

    ---@type BuffResultCoffinMusumeSetCandleLight
    local buffResult = self._buffResult

    ---@type EffectService
    local fxsvc = self._world:GetService("Effect")

    --点亮就是一个特效，熄灭就是删掉特效
    if buffResult:IsLightAfter() == 1 then
        fxsvc:CreateEffect(effectID, e)
    elseif (buffResult:IsLightAfter() == 0) then
        fxsvc:DestroyEntityEffectByID(e, {effectID})
    end

    self._world:GetService("PlayBuff"):PlayBuffView(TT, NTCoffinMusumeLightChanged:New())
end
