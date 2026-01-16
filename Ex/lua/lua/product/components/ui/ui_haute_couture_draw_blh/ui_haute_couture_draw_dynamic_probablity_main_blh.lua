---@class UIHauteCoutureDrawDynamicProbabilityMainBLH:UIHauteCoutureDrawDynamicProbablityBase
_class("UIHauteCoutureDrawDynamicProbabilityMainBLH", UIHauteCoutureDrawDynamicProbablityBase)
UIHauteCoutureDrawDynamicProbabilityMainBLH = UIHauteCoutureDrawDynamicProbabilityMainBLH

function UIHauteCoutureDrawDynamicProbabilityMainBLH:Constructor()
end

function UIHauteCoutureDrawDynamicProbabilityMainBLH:OnShow(uiParams)
    self:InitWidgets()

    self:_OnValue()
end

function UIHauteCoutureDrawDynamicProbabilityMainBLH:InitWidgets()
    --通用Widgets初始化
    self:InitWidgetsBase()

    --个性化Widgets初始化
end

function UIHauteCoutureDrawDynamicProbabilityMainBLH:GetProbablityItemScript()
    return "UIHauteCoutureDrawProbabiltyItemBLH"
end
