--[[
    伯利恒高级时装复刻奖励重复变更说明界面
]]
---@class UIHauteCoutureDuplicateRewardBLH : UIHauteCoutureDrawDuplicateRewardBase
_class("UIHauteCoutureDuplicateRewardBLH", UIHauteCoutureDrawDuplicateRewardBase)
UIHauteCoutureDuplicateRewardBLH = UIHauteCoutureDuplicateRewardBLH

function UIHauteCoutureDuplicateRewardBLH:GetItemClassName()
    return UIHauteCoutureDuplicateItemBLH._className
end

function UIHauteCoutureDuplicateRewardBLH:GetGetItemUIInfo()
    return "UIHauteCoutureDrawGetItemCellDetailBLH.prefab", UIHauteCoutureDrawGetItemCellDetailBLH._className
end
