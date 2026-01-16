---@class UICampaignShopItemGroupCell : UICustomWidget
_class("UICampaignShopItemGroupCell", UICustomWidget)
UICampaignShopItemGroupCell = UICampaignShopItemGroupCell
function UICampaignShopItemGroupCell:OnShow(uiParams)
    self:InitWidget()
end
function UICampaignShopItemGroupCell:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self._smallBoxGen = self:GetUIComponent("UISelectObjectPath", "SmallBoxGen")
    ---@type UICustomWidgetPool
    self._bigItemGen = self:GetUIComponent("UISelectObjectPath", "BigItemGen")
    self._rootLayout = self:GetUIComponent("LayoutElement", "Root")
    --generated end--
end
function UICampaignShopItemGroupCell:SetData()
end
function UICampaignShopItemGroupCell:InitData(data)
    local item = nil
    if data.GetIsSpecial and data:GetIsSpecial() then
        item = self._bigItemGen:SpawnObject("UICampaignShopItemBig")
        self._rootLayout.minWidth = 400
        self._rootLayout.preferredWidth = 400
    else
        item = self._smallBoxGen:SpawnObject("UICampaignShopSmallItemBox")
        self._rootLayout.minWidth = 350
        self._rootLayout.preferredWidth = 350
    end
    if item then
        item:InitData(data)
        --UIHelper.RefreshLayout(item:GetComponent("RectTransform"))
    end
    --UIHelper.RefreshLayout(self:GetGameObject():GetComponent("RectTransform"))
end
