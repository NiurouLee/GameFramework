--
---@class UIHomeGiftSelector : UIController
_class("UIHomeGiftSelector", UIController)
UIHomeGiftSelector = UIHomeGiftSelector
--初始化
function UIHomeGiftSelector:OnShow(uiParams)
    self:InitWidget()
    ---@type UIHomeStorehouseOperator
    local selector = self.operator:SpawnObject("UIHomeStorehouseOperator")
    selector:SetData(
        function(id, count)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.UIHomeVisitAddGift, id, count)
            self:CloseDialog()
        end
    )
end
--获取ui组件
function UIHomeGiftSelector:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self.operator = self:GetUIComponent("UISelectObjectPath", "Operator")
    --generated end--
end
--按钮点击
function UIHomeGiftSelector:CloseOnClick(go)
    self:CloseDialog()
end
