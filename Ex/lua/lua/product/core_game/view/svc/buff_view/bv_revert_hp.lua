require("_buff_view_base_r")

_class("BuffViewDoRevertHP", BuffViewBase)
BuffViewDoRevertHP = BuffViewDoRevertHP
---@class BuffViewDoRevertHP : BuffViewBase
---@field _buffResult BuffResultDoRevertHP

function BuffViewDoRevertHP:PlayView(TT)
    ---@type  Entity
    local entity = self._entity
    local damageInfo = self._buffResult:GetDamageInfo()

    local materialEntity = entity
    if entity:HasTeam() then
        materialEntity = entity:GetTeamLeaderPetEntity()
    end
    if damageInfo:GetDamageType() == DamageType.Recover then
        --材质动画
        if materialEntity:MaterialAnimationComponent() then 
            materialEntity:MaterialAnimationComponent():PlayCure()
        end
        --加血飘字
        ---@type PlayDamageService
        local playDamageService = self._world:GetService("PlayDamage")
        playDamageService:AsyncUpdateHPAndDisplayDamage( materialEntity, damageInfo)
    else
        local playBuffSvc = self._world:GetService("PlayBuff")
        playBuffSvc:PlayDamageBuff(TT, self)
    end
end
