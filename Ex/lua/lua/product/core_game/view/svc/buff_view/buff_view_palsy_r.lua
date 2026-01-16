--[[
     瘫痪
]]
---@class BuffViewSetPalsy:BuffViewBase
_class("BuffViewSetPalsy", BuffViewBase)
BuffViewSetPalsy = BuffViewSetPalsy

function BuffViewSetPalsy:PlayView(TT)
    self._entity:SetAnimatorControllerBools({Palsy = true})
end

--[[
     瘫痪移除
]]
---@class BuffViewResetPalsy:BuffViewBase
_class("BuffViewResetPalsy", BuffViewBase)
BuffViewResetPalsy = BuffViewResetPalsy

function BuffViewResetPalsy:PlayView(TT)
    self._entity:SetAnimatorControllerBools({Palsy = false})
end
