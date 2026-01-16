_class("BuffViewDecreaseMaxHP", BuffViewBase)
---@class BuffViewDecreaseMaxHP:BuffViewBase
BuffViewDecreaseMaxHP = BuffViewDecreaseMaxHP

function BuffViewDecreaseMaxHP:PlayView(TT)
    ---@type PlayDamageService
    local playDamageSvc = self._world:GetService("PlayDamage")
    ---@type BuffResultDecreaseMaxHP
    local result = self._buffResult
    local damageInfo = result:GetDamageInfo()
    local entityID = result:GetEntityID()
    local ret = result:GetMaxHPResult()

    for k, v in pairs(ret) do
        ---@type Entity
        local e = self._world:GetEntityByID(k)
        e:ReplaceMaxHP(v)
    end

    local entityWork = self._world:GetEntityByID(entityID)
    --血条刷新
    playDamageSvc:UpdateTargetHPBar(TT, entityWork, damageInfo)
end
