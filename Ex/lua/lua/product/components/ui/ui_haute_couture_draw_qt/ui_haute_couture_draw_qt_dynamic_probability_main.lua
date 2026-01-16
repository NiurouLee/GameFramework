require("ui_haute_couture_draw_dynamic_probablity_base")

---@class UIHauteCoutureDraw_QT_DynamicProbabilityMain:UIHauteCoutureDrawDynamicProbablityBase
_class("UIHauteCoutureDraw_QT_DynamicProbabilityMain", UIHauteCoutureDrawDynamicProbablityBase)
UIHauteCoutureDraw_QT_DynamicProbabilityMain = UIHauteCoutureDraw_QT_DynamicProbabilityMain

function UIHauteCoutureDraw_QT_DynamicProbabilityMain:Constructor()
end

function UIHauteCoutureDraw_QT_DynamicProbabilityMain:OnShow(uiParams)
    self:InitWidgets()

    self:_OnValue()
end

function UIHauteCoutureDraw_QT_DynamicProbabilityMain:InitWidgets()
    --通用Widgets初始化
    self:InitWidgetsBase()

    --个性化Widgets初始化
end

function UIHauteCoutureDraw_QT_DynamicProbabilityMain:GetProbablityItemScript()
    return "UIHauteCoutureDraw_QT_DynamicProbabilityItem"
end
