---@class UIHauteCoutureDrawChargeMainBLH:UIHauteCoutureDrawChargeBase
_class("UIHauteCoutureDrawChargeMainBLH", UIHauteCoutureDrawChargeBase)
UIHauteCoutureDrawChargeMainBLH = UIHauteCoutureDrawChargeMainBLH

function UIHauteCoutureDrawChargeMainBLH:Constructor()
end

function UIHauteCoutureDrawChargeMainBLH:OnShow(uiParams)
    self:InitWidgets()
    self:_OnValue()
end

function UIHauteCoutureDrawChargeMainBLH:InitWidgets()
    --通用Widgets初始化
    self:InitWidgetsBase()

    --个性化Widgets初始化
end

function UIHauteCoutureDrawChargeMainBLH:_OnValue()
    self:_OnValueBase()
end

--子类实现
function UIHauteCoutureDrawChargeMainBLH:GetItemImpl()
    return "UIHauteCoutureDrawChargeItemBLH"
end
