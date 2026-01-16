---@class UIHauteCoutureDrawChargeMainKR:UIHauteCoutureDrawChargeBase
_class("UIHauteCoutureDrawChargeMainKR", UIHauteCoutureDrawChargeBase)
UIHauteCoutureDrawChargeMainKR = UIHauteCoutureDrawChargeMainKR

function UIHauteCoutureDrawChargeMainKR:Constructor()
end

function UIHauteCoutureDrawChargeMainKR:OnShow(uiParams)
    self:InitWidgets()
    self:_OnValue()
end

function UIHauteCoutureDrawChargeMainKR:InitWidgets()
   --通用Widgets初始化
    self:InitWidgetsBase()

    --个性化Widgets初始化
end

function UIHauteCoutureDrawChargeMainKR:_OnValue()
    self:_OnValueBase()
end

--子类实现
function UIHauteCoutureDrawChargeMainKR:GetItemImpl()
    return "UIHauteCoutureDrawChargeItemKR"
end
