---@class UIShopRechargeGainItem:UICustomWidget
_class("UIShopRechargeGainItem", UICustomWidget)
UIShopRechargeGainItem = UIShopRechargeGainItem

function UIShopRechargeGainItem:OnShow()
    self._root = self:GetGameObject("root")
    self._root:SetActive(false)

    self._txtName = self:GetUIComponent("UILocalizationText", "txtName")
    ---@type RawImageLoader
    self._imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    self._txtCount = self:GetUIComponent("UILocalizationText", "txtCount")
end

function UIShopRechargeGainItem:OnHide()
    self._root = nil
end

---@param item table
-- {
--  item_id,
--  item_count,
--  item_des,
--  icon,
--  item_name,
--  simple_desc,
--  color
-- }
function UIShopRechargeGainItem:ReadyToFlush(item, stamp)
    self:StartTask(
        function(TT)
            YIELD(TT, stamp)
            self:Flush(item)
        end,
        self
    )
end

function UIShopRechargeGainItem:Flush(item)
    if not self._root then
        return
    end
    self._root:SetActive(true)
    self._itemData = item
    self._imgIcon:LoadImage(self._itemData.icon)
    self._txtName:SetText(self._itemData.item_name)
    self._txtCount:SetText(self._itemData.item_count)
end
