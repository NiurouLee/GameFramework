---@class UIHauteCoutureDrawRulesMainPLM:UIHauteCoutureDrawRulesBase
_class("UIHauteCoutureDrawRulesMainPLM", UIHauteCoutureDrawRulesBase)
UIHauteCoutureDrawRulesMainPLM = UIHauteCoutureDrawRulesMainPLM

function UIHauteCoutureDrawRulesMainPLM:Constructor()
end

function UIHauteCoutureDrawRulesMainPLM:OnShow(uiParams)
    self:InitWidgets()
    self:_OnValue()
end

function UIHauteCoutureDrawRulesMainPLM:InitWidgets()
    --通用Widgets初始化
    self:InitWidgetsBase()

    --个性化Widgets初始化
end

--子类调用
function UIHauteCoutureDrawRulesMainPLM:GetRuleItemPrefab()
    return "UISeniorSKinProItemsPLM.prefab"
end

--子类调用
function UIHauteCoutureDrawRulesMainPLM:GetRuleItemScript()
    return "UISeniorSKinProItems"
end
--复刻时界面上修改奖励内容文本
function UIHauteCoutureDrawRulesMainPLM:SetReviewRewardContenText()
    self:GetUIComponent("UILocalizationText", "RewardContent"):SetText(
        StringTable.Get("str_senior_skin_draw_rule_reward_detail_gl_review")
    )
end

function UIHauteCoutureDrawRulesMainPLM:CloseBtnOnClick()
    self.controller:CloseDialog()
end
