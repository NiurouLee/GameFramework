---@class UIHauteCoutureDrawDynamicProbabilityMainGL:UIHauteCoutureDrawDynamicProbablityBase
_class("UIHauteCoutureDrawDynamicProbabilityMainGL", UIHauteCoutureDrawDynamicProbablityBase)
UIHauteCoutureDrawDynamicProbabilityMainGL = UIHauteCoutureDrawDynamicProbabilityMainGL

function UIHauteCoutureDrawDynamicProbabilityMainGL:Constructor()
end

function UIHauteCoutureDrawDynamicProbabilityMainGL:OnShow(uiParams)
    self:InitWidgets()

    self:_OnValue()
end

function UIHauteCoutureDrawDynamicProbabilityMainGL:InitWidgets()
   --通用Widgets初始化
    self:InitWidgetsBase()

    --个性化Widgets初始化
end
   
function UIHauteCoutureDrawDynamicProbabilityMainGL:GetProbablityItemScript()
    return "UIHauteCoutureDrawProbabiltyItemGL"
end