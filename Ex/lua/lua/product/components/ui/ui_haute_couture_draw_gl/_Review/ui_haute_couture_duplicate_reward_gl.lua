--[[
    贡露高级时装复刻奖励重复变更说明界面
]]
---@class UIHauteCoutureDuplicateRewardGL : UIHauteCoutureDrawDuplicateRewardBase
_class("UIHauteCoutureDuplicateRewardGL", UIHauteCoutureDrawDuplicateRewardBase)
UIHauteCoutureDuplicateRewardGL = UIHauteCoutureDuplicateRewardGL

function UIHauteCoutureDuplicateRewardGL:GetItemClassName()
    return UIHauteCoutureDuplicateItemGL._className
end

function UIHauteCoutureDuplicateRewardGL:GetGetItemUIInfo()
    return "UIHauteCoutureDrawGetItemCellDetailGL.prefab", UIHauteCoutureDrawGetItemCellDetailGL._className
end
