--[[
    高级时装复刻奖励重复变更说明界面
]]
---@class UIHauteCoutureDuplicateRewardKR : UIHauteCoutureDrawDuplicateRewardBase
_class("UIHauteCoutureDuplicateRewardKR", UIHauteCoutureDrawDuplicateRewardBase)
UIHauteCoutureDuplicateRewardKR = UIHauteCoutureDuplicateRewardKR

function UIHauteCoutureDuplicateRewardKR:GetItemClassName()
    return UIHauteCoutureDuplicateItemKR._className
end

function UIHauteCoutureDuplicateRewardKR:GetGetItemUIInfo()
    return "UIHauteCoutureDrawGetItemCellDetailKR.prefab", UIHauteCoutureDrawGetItemCellDetailKR._className
end
