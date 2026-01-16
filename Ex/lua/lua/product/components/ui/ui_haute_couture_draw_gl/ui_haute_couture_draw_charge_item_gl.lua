--
---@class UIHauteCoutureDrawChargeItemGL : UIHauteCoutureDrawChargeItemBase
_class("UIHauteCoutureDrawChargeItemGL", UIHauteCoutureDrawChargeItemBase)
UIHauteCoutureDrawChargeItemGL = UIHauteCoutureDrawChargeItemGL

--初始化
function UIHauteCoutureDrawChargeItemGL:OnShow(uiParams)
    self:InitWidgets()
end

function UIHauteCoutureDrawChargeItemGL:OnHide()
    self:ClearTimer()
end

function UIHauteCoutureDrawChargeItemGL:InitWidgets(uiParams)
    self:InitWidgetsBase()
end

function UIHauteCoutureDrawChargeItemGL:GetCountStrKey()
    return "str_senior_skin_draw_gift_count_gl"
end
