--[[
     恐惧
]]
_class("BuffViewSetFear", BuffViewBase)
BuffViewSetFear = BuffViewSetFear

function BuffViewSetFear:PlayView(TT)
    self._entity:SetAnimatorControllerBools({Fear = true})
end

--[[
     恐惧移除
]]
_class("BuffViewResetFear", BuffViewBase)
BuffViewResetFear = BuffViewResetFear

function BuffViewResetFear:PlayView(TT)
    local targetEntity = self._entity
    targetEntity:SetAnimatorControllerBools({Fear = false})
end
