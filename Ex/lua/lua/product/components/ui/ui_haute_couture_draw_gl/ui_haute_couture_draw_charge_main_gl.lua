---@class UIHauteCoutureDrawChargeMainGL:UIHauteCoutureDrawChargeBase
_class("UIHauteCoutureDrawChargeMainGL", UIHauteCoutureDrawChargeBase)
UIHauteCoutureDrawChargeMainGL = UIHauteCoutureDrawChargeMainGL

function UIHauteCoutureDrawChargeMainGL:Constructor()
end

function UIHauteCoutureDrawChargeMainGL:OnShow(uiParams)
    self:InitWidgets()
    self:_OnValue()
end

function UIHauteCoutureDrawChargeMainGL:InitWidgets()
   --通用Widgets初始化
    self:InitWidgetsBase()

    --个性化Widgets初始化
end

function UIHauteCoutureDrawChargeMainGL:_OnValue()
    self:_OnValueBase()
end

--子类实现
function UIHauteCoutureDrawChargeMainGL:GetItemImpl()
    return "UIHauteCoutureDrawChargeItemGL"
end
