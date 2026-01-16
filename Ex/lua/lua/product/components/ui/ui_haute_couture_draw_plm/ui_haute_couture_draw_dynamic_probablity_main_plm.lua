---@class UIHauteCoutureDrawDynamicProbabilityMainPLM:UIHauteCoutureDrawDynamicProbablityBase
_class("UIHauteCoutureDrawDynamicProbabilityMainPLM", UIHauteCoutureDrawDynamicProbablityBase)
UIHauteCoutureDrawDynamicProbabilityMainPLM = UIHauteCoutureDrawDynamicProbabilityMainPLM

function UIHauteCoutureDrawDynamicProbabilityMainPLM:Constructor()
end

function UIHauteCoutureDrawDynamicProbabilityMainPLM:OnShow(uiParams)
    self:InitWidgets()

    self:_OnValue()
end

function UIHauteCoutureDrawDynamicProbabilityMainPLM:InitWidgets()
   --通用Widgets初始化
    self:InitWidgetsBase()

    --个性化Widgets初始化
end
   
function UIHauteCoutureDrawDynamicProbabilityMainPLM:GetProbablityItemScript()
    return "UIHauteCoutureDrawProbabiltyItemPLM"
end