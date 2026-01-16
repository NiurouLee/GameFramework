--[[
    根据LayerMark增加血量
]]
_class("BuffViewAddHPByLayerMark", BuffViewBase)
---@class BuffViewAddHPByLayerMark:BuffViewBase
BuffViewAddHPByLayerMark = BuffViewAddHPByLayerMark

function BuffViewAddHPByLayerMark:Constructor()
end

function BuffViewAddHPByLayerMark:PlayView(TT)
    ---@type BuffResultAddHPByLayerMark
    local res = self._buffResult
    local damageInfo = res:GetDamageInfo()
    local entity = self._world:GetEntityByID(res:GetEntityID())

    YIELD(TT)

    --材质动画
    local materialAnimationComponent = entity:MaterialAnimationComponent()
    if materialAnimationComponent then
        materialAnimationComponent:PlayCure()
    end

    --加血飘字
    ---@type PlayDamageService
    local playDamageService = self._world:GetService("PlayDamage")
    playDamageService:AsyncUpdateHPAndDisplayDamage(entity, damageInfo)
end
