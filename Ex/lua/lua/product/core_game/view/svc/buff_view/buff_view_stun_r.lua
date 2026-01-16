--[[
     眩晕
]]
_class("BuffViewSetStun", BuffViewBase)
BuffViewSetStun = BuffViewSetStun

function BuffViewSetStun:PlayView(TT)
    self._entity:SetAnimatorControllerBools({Stun = true})
end

--[[
     眩晕移除
]]
_class("BuffViewResetStun", BuffViewBase)
BuffViewResetStun = BuffViewResetStun

function BuffViewResetStun:PlayView(TT)
    local targetEntity = self._entity
    targetEntity:SetAnimatorControllerBools({Stun = false})

    ---眩晕结束，需要看玩家身上是否有Idle特效，有的话，需要显示
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    if effectService ~= nil then
        effectService:ShowIdleEffect(targetEntity, true)
        --如果有虚弱特效，就可以删除了
        effectService:DestroyWeakEffect(targetEntity)
    end
end
