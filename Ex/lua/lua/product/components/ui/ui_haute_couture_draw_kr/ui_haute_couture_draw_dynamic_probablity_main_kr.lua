---@class UIHauteCoutureDrawDynamicProbabilityMainKR:UIHauteCoutureDrawDynamicProbablityBase
_class("UIHauteCoutureDrawDynamicProbabilityMainKR", UIHauteCoutureDrawDynamicProbablityBase)
UIHauteCoutureDrawDynamicProbabilityMainKR = UIHauteCoutureDrawDynamicProbabilityMainKR

function UIHauteCoutureDrawDynamicProbabilityMainKR:Constructor()
end

function UIHauteCoutureDrawDynamicProbabilityMainKR:OnShow(uiParams)
    self:InitWidgets()

    self:_OnValue()
end

function UIHauteCoutureDrawDynamicProbabilityMainKR:InitWidgets()
   --通用Widgets初始化
    self:InitWidgetsBase()

    --个性化Widgets初始化
end
   
function UIHauteCoutureDrawDynamicProbabilityMainKR:GetProbablityItemScript()
    return "UIHauteCoutureDrawProbabiltyItemKR"
end