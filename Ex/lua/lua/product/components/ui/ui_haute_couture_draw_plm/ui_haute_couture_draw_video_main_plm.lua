---@class UIHauteCoutureDrawVideoMainPLM:UIHauteCoutureDrawVideoBase
_class("UIHauteCoutureDrawVideoMainPLM", UIHauteCoutureDrawVideoBase)
UIHauteCoutureDrawVideoMainPLM = UIHauteCoutureDrawVideoMainPLM

function UIHauteCoutureDrawVideoMainPLM:Constructor()
end

function UIHauteCoutureDrawVideoMainPLM:OnShow(uiParams)
    self:InitWidgets()
    self:_LoadVideo()
end

function UIHauteCoutureDrawVideoMainPLM:InitWidgets()
   --通用Widgets初始化
    self:InitWidgetsBase()

    --个性化Widgets初始化
end
   