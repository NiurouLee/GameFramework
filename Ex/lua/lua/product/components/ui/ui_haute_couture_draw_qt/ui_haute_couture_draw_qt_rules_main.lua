require("ui_haute_couture_draw_rules_base")

---@class UIHauteCoutureDraw_QT_RulesMain:UIHauteCoutureDrawRulesBase
_class("UIHauteCoutureDraw_QT_RulesMain", UIHauteCoutureDrawRulesBase)
UIHauteCoutureDraw_QT_RulesMain = UIHauteCoutureDraw_QT_RulesMain

function UIHauteCoutureDraw_QT_RulesMain:Constructor()
end

function UIHauteCoutureDraw_QT_RulesMain:OnShow(uiParams)
    self:InitWidgets()
    self:_OnValue()
end

function UIHauteCoutureDraw_QT_RulesMain:InitWidgets()
    --通用Widgets初始化
    self:InitWidgetsBase()

    --个性化Widgets初始化
end

--子类调用
function UIHauteCoutureDraw_QT_RulesMain:GetRuleItemPrefab()
    return "UIHauteCoutureDraw_QT_RulesItem.prefab"
end

--子类调用
function UIHauteCoutureDraw_QT_RulesMain:GetRuleItemScript()
    return "UISeniorSKinProItems"
end

function UIHauteCoutureDraw_QT_RulesMain:CloseBtnOnClick()
    self.controller:CloseDialog()
end
