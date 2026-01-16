--
---@class UIHauteCoutureDrawChargeItemBLH : UIHauteCoutureDrawChargeItemBase
_class("UIHauteCoutureDrawChargeItemBLH", UIHauteCoutureDrawChargeItemBase)
UIHauteCoutureDrawChargeItemBLH = UIHauteCoutureDrawChargeItemBLH

--初始化
function UIHauteCoutureDrawChargeItemBLH:OnShow(uiParams)
    self:InitWidgets()
end

function UIHauteCoutureDrawChargeItemBLH:OnHide()
    self:ClearTimer()
end

function UIHauteCoutureDrawChargeItemBLH:InitWidgets(uiParams)
    self:InitWidgetsBase()
end

function UIHauteCoutureDrawChargeItemBLH:GetCountStrKey()
    return "str_senior_skin_draw_gift_count_blh"
end
