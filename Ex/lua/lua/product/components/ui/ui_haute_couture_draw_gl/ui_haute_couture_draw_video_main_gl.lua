---@class UIHauteCoutureDrawVideoMainGL:UIHauteCoutureDrawVideoBase
_class("UIHauteCoutureDrawVideoMainGL", UIHauteCoutureDrawVideoBase)
UIHauteCoutureDrawVideoMainGL = UIHauteCoutureDrawVideoMainGL

function UIHauteCoutureDrawVideoMainGL:Constructor()
end

function UIHauteCoutureDrawVideoMainGL:OnShow(uiParams)
    self:InitWidgets()
    self:_LoadVideo()
end

function UIHauteCoutureDrawVideoMainGL:InitWidgets()
   --通用Widgets初始化
    self:InitWidgetsBase()

    --个性化Widgets初始化
end
   