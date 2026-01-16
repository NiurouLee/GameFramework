--[[
    加血效果
]]
_class("BuffViewAddHPComplex", BuffViewBase)
BuffViewAddHPComplex = BuffViewAddHPComplex

function BuffViewAddHPComplex:Constructor()
end

function BuffViewAddHPComplex:PlayView(TT)
    ---@type BuffResultAddHPComplex
    local res = self._buffResult
    local entity = self._entity
    local damageInfo = res:GetDamageInfo()
    local headOut = res:GetHeadout()
    local delay = res:GetDelay()

    if delay > 0 then
        YIELD(TT, delay)
    end
    --对应星灵头像左移
    if headOut then
        local petPstIdCmp = entity:PetPstID()
        local petPstId = petPstIdCmp:GetPstID()
        GameGlobal.EventDispatcher():Dispatch(GameEventType.InOutQueue, petPstId, true)
    end
    --材质动画
    ---@type MaterialAnimationComponent
    local materialAnimCmpt = entity:MaterialAnimationComponent()
    if materialAnimCmpt then
        materialAnimCmpt:PlayCure()
    end

    --加血飘字
    ---@type PlayDamageService
    local playDmg = self._world:GetService("PlayDamage")
    --如果是一个星灵，则对队长加血
    if entity:PetPstID() then
        entity:Pet():GetOwnerTeamEntity()
        local teamEntity = entity:Pet():GetOwnerTeamEntity()
        playDmg:AsyncUpdateHPAndDisplayDamage(teamEntity, damageInfo)
    else
        playDmg:AsyncUpdateHPAndDisplayDamage(entity, damageInfo)
    end

    if headOut then
        local petPstIdCmp = entity:PetPstID()
        local petPstId = petPstIdCmp:GetPstID()
        --对应星灵头像回归原位置
        GameGlobal.EventDispatcher():Dispatch(GameEventType.InOutQueue, petPstId, false)
    end
end
