require("ui_haute_couture_draw_charge_base")

---@class UIHauteCoutureDraw_QT_ChargeMain:UIHauteCoutureDrawChargeBase
_class("UIHauteCoutureDraw_QT_ChargeMain", UIHauteCoutureDrawChargeBase)
UIHauteCoutureDraw_QT_ChargeMain = UIHauteCoutureDraw_QT_ChargeMain

function UIHauteCoutureDraw_QT_ChargeMain:Constructor()
end

function UIHauteCoutureDraw_QT_ChargeMain:OnShow(uiParams)
    self:InitWidgets()
    self:_OnValue()
end

function UIHauteCoutureDraw_QT_ChargeMain:InitWidgets()
    --通用Widgets初始化
    self:InitWidgetsBase()

    --个性化Widgets初始化
end

function UIHauteCoutureDraw_QT_ChargeMain:_OnValue()
    self:_OnValueBase()
end

--子类实现
function UIHauteCoutureDraw_QT_ChargeMain:GetItemImpl()
    return "UIHauteCoutureDraw_QT_ChargeItem"
end
