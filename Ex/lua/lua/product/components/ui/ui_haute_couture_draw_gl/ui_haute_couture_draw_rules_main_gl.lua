---@class UIHauteCoutureDrawRulesMainGL:UIHauteCoutureDrawRulesBase
_class("UIHauteCoutureDrawRulesMainGL", UIHauteCoutureDrawRulesBase)
UIHauteCoutureDrawRulesMainGL = UIHauteCoutureDrawRulesMainGL

function UIHauteCoutureDrawRulesMainGL:Constructor()
end

function UIHauteCoutureDrawRulesMainGL:OnShow(uiParams)
    self:InitWidgets()
    self:_OnValue()
end

function UIHauteCoutureDrawRulesMainGL:InitWidgets()
    --通用Widgets初始化
    self:InitWidgetsBase()

    --个性化Widgets初始化
end

--子类调用
function UIHauteCoutureDrawRulesMainGL:GetRuleItemPrefab()
    return "UISeniorSKinProItemsGL.prefab"
end

--子类调用
function UIHauteCoutureDrawRulesMainGL:GetRuleItemScript()
    return "UISeniorSKinProItems"
end
--复刻时界面上修改奖励内容文本
function UIHauteCoutureDrawRulesMainGL:SetReviewRewardContenText()
    self:GetUIComponent("UILocalizationText", "RewardContent"):SetText(
        StringTable.Get("str_senior_skin_draw_rule_reward_detail_gl_review")
    )
end

function UIHauteCoutureDrawRulesMainGL:CloseBtnOnClick()
    self.controller:CloseDialog()
end
