---@class UIHauteCoutureDrawRulesMainKR:UIHauteCoutureDrawRulesBase
_class("UIHauteCoutureDrawRulesMainKR", UIHauteCoutureDrawRulesBase)
UIHauteCoutureDrawRulesMainKR = UIHauteCoutureDrawRulesMainKR

function UIHauteCoutureDrawRulesMainKR:Constructor()
end

function UIHauteCoutureDrawRulesMainKR:OnShow(uiParams)
    self:InitWidgets()
    self:_OnValue()
end

function UIHauteCoutureDrawRulesMainKR:InitWidgets()
   --通用Widgets初始化
    self:InitWidgetsBase()

    --个性化Widgets初始化
end

--子类调用
function UIHauteCoutureDrawRulesMainKR:GetRuleItemPrefab()
    return "UISeniorSKinProItemsKR.prefab"
end

--子类调用
function UIHauteCoutureDrawRulesMainKR:GetRuleItemScript()
    return "UISeniorSKinProItems"
end

function UIHauteCoutureDrawRulesMainKR:CloseBtnOnClick()
    self.controller:CloseDialog()
end
   