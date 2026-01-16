---@class UIHauteCoutureDrawVideoMainKR:UIHauteCoutureDrawVideoBase
_class("UIHauteCoutureDrawVideoMainKR", UIHauteCoutureDrawVideoBase)
UIHauteCoutureDrawVideoMainKR = UIHauteCoutureDrawVideoMainKR

function UIHauteCoutureDrawVideoMainKR:Constructor()
end

function UIHauteCoutureDrawVideoMainKR:OnShow(uiParams)
    self:InitWidgets()
    self:_LoadVideo()
end

function UIHauteCoutureDrawVideoMainKR:InitWidgets()
   --通用Widgets初始化
    self:InitWidgetsBase()

    --个性化Widgets初始化
end
   