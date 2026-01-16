---@class UIHauteCoutureDuplicateItemGL:UIHauteCoutureDuplicateItem
_class("UIHauteCoutureDuplicateItemGL", UIHauteCoutureDuplicateItem)
UIHauteCoutureDuplicateItemGL = UIHauteCoutureDuplicateItemGL

function UIHauteCoutureDuplicateItemGL:SetBg(cfg)
    if cfg.RewardSortOrder == 10 then
        self.bg:LoadImage("glseniorfk_rule_di01") --最终奖励特殊设置背景图
    else
        self.bg:LoadImage("glseniorfk_rule_di102")
    end
end
