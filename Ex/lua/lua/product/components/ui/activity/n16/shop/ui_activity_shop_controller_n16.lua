--活动商店代码通用，prefab复制修改 20211022 （伊芙醒山、夏活一不是，N16开始
--每个活动商店继承UIActivityShopControllerBase，为了在ui_register中注册
---@class UIActivityShopControllerN16 : UIActivityShopControllerBase
_class("UIActivityShopControllerN16", UIActivityShopControllerBase)
UIActivityShopControllerN16 = UIActivityShopControllerN16
function UIActivityShopControllerN16:DefaultBackFunc()
    self:SwitchState(UIStateType.UIActivityN16MainController)
end


function UIActivityShopControllerN16:_GetFormatString(stamp)
    local timeStr = UIActivityHelper.GetFormatTimerStr(stamp)
    local showStr = StringTable.Get("str_activity_n16_shop_close_at", timeStr)
    return showStr
end
