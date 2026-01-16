--[[
    设置animator的layerWeight，用于切换动作状态（例：双刀换大剑）
]]
_class("BuffViewChangeAnimatorLayerWeight", BuffViewBase)
---@class BuffViewChangeAnimatorLayerWeight:BuffViewBase
BuffViewChangeAnimatorLayerWeight = BuffViewChangeAnimatorLayerWeight

function BuffViewChangeAnimatorLayerWeight:PlayView(TT)
    ---@type  Entity
    local entity = self._entity
    local changeInfo = self._buffResult:GetChangeInfo()
    if entity and changeInfo then
        entity:SetAnimatorLayerWeight(changeInfo)
        --不设置这个 在光灵隐藏再显示后 状态会丢失
        entity:SetKeepAnimatorLayerWeight(true)
    end
end
