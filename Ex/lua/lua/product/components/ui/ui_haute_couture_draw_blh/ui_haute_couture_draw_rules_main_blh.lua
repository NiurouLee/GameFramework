---@class UIHauteCoutureDrawRulesMainBLH:UIHauteCoutureDrawRulesBase
_class("UIHauteCoutureDrawRulesMainBLH", UIHauteCoutureDrawRulesBase)
UIHauteCoutureDrawRulesMainBLH = UIHauteCoutureDrawRulesMainBLH

function UIHauteCoutureDrawRulesMainBLH:Constructor()
end

function UIHauteCoutureDrawRulesMainBLH:OnShow(uiParams)
    self:InitWidgets()
    self:_OnValue()
end

function UIHauteCoutureDrawRulesMainBLH:InitWidgets()
    --通用Widgets初始化
    self:InitWidgetsBase()

    --个性化Widgets初始化
end

--子类调用
function UIHauteCoutureDrawRulesMainBLH:GetRuleItemPrefab()
    return "UISeniorSKinProItemsBLH.prefab"
end

--子类调用
function UIHauteCoutureDrawRulesMainBLH:GetRuleItemScript()
    return "UISeniorSKinProItems"
end

function UIHauteCoutureDrawRulesMainBLH:CloseBtnOnClick()
    self.controller:CloseDialog()
end
