---@class UIHauteCoutureDrawVideoMainBLH:UIHauteCoutureDrawVideoBase
_class("UIHauteCoutureDrawVideoMainBLH", UIHauteCoutureDrawVideoBase)
UIHauteCoutureDrawVideoMainBLH = UIHauteCoutureDrawVideoMainBLH

function UIHauteCoutureDrawVideoMainBLH:Constructor()
end

function UIHauteCoutureDrawVideoMainBLH:OnShow(uiParams)
    self:InitWidgets()
    self:_LoadVideo()
end

function UIHauteCoutureDrawVideoMainBLH:InitWidgets()
    --通用Widgets初始化
    self:InitWidgetsBase()

    --个性化Widgets初始化
end
