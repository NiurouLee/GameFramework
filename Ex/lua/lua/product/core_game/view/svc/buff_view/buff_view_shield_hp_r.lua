--[[
    血条盾表现
]]
_class("BuffViewAddHPShield", BuffViewBase)
---@class BuffViewAddHPShield:BuffViewBase
BuffViewAddHPShield = BuffViewAddHPShield

function BuffViewAddHPShield:PlayView(TT)
    local eid = self._buffResult:GetEntityID()
    ---@type Entity
    local entity = self._world:GetEntityByID(eid)

    ---@type DamageInfo
    local damageInfo = self._buffResult:GetDamageInfo()

    if entity:HasPet() then
        entity = entity:Pet():GetOwnerTeamEntity()
    end
    ---@type HPComponent
    local hpCmpt = entity:HP()
    local curShield = damageInfo:GetHPShield() or 0
    hpCmpt:SetShieldValue(curShield)

    ---@type PlayDamageService
    local playDamageSvc = self._world:GetService("PlayDamage")
    playDamageSvc:UpdateTargetHPBar(TT, entity, damageInfo)
end

_class("BuffViewRemoveHPShield", BuffViewBase)
BuffViewRemoveHPShield = BuffViewRemoveHPShield

function BuffViewRemoveHPShield:PlayView(TT)
    local eid = self._buffResult:GetEntityID()
    ---@type Entity
    local entity = self._world:GetEntityByID(eid)

    local damageInfo = self._buffResult:GetDamageInfo()
    if entity:HasPet() then
        entity = entity:Pet():GetOwnerTeamEntity()
    end
    ---@type HPComponent
    local hpCmpt = entity:HP()
    local curShield = damageInfo:GetHPShield() or 0
    hpCmpt:SetShieldValue(curShield)

    ---@type PlayDamageService
    local playDamageSvc = self._world:GetService("PlayDamage")
    playDamageSvc:UpdateTargetHPBar(TT, entity, damageInfo)
end
