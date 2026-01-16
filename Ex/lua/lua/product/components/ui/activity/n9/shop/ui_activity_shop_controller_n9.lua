--活动商店代码通用，prefab复制修改 20211022 （伊芙醒山、夏活一不是，N9开始
--每个活动商店继承UIActivityShopControllerBase，为了在ui_register中注册
---@class UIActivityShopControllerN9 : UIActivityShopControllerBase
_class("UIActivityShopControllerN9", UIActivityShopControllerBase)
UIActivityShopControllerN9 = UIActivityShopControllerN9
function UIActivityShopControllerN9:DefaultBackFunc()
    self:SwitchState(UIStateType.UIActivityN9MainController)
end