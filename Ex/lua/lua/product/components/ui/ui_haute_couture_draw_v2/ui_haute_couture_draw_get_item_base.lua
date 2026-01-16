---@class UIHauteCoutureDrawGetItemBase:UICustomWidget
---@field controller UIHauteCoutureDrawGetItemV2Controller 控制器
_class("UIHauteCoutureDrawGetItemBase", UICustomWidget)
UIHauteCoutureDrawGetItemBase = UIHauteCoutureDrawGetItemBase

function UIHauteCoutureDrawGetItemBase:Constructor()
    self.controller = nil
end


function UIHauteCoutureDrawGetItemBase:InitWidgetsBase()
    self.controller = self.uiOwner

   
end


function UIHauteCoutureDrawGetItemBase:BgOnClick()
    self.controller:CloseDialog()
end