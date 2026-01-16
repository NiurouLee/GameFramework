---@class UIXH1ShopItemGroupCell : UICustomWidget
_class("UIXH1ShopItemGroupCell", UICustomWidget)
UIXH1ShopItemGroupCell = UIXH1ShopItemGroupCell
function UIXH1ShopItemGroupCell:OnShow(uiParams)
    self:InitWidget()
end
function UIXH1ShopItemGroupCell:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self._smallBoxGen = self:GetUIComponent("UISelectObjectPath", "SmallBoxGen")
    ---@type UICustomWidgetPool
    self._bigItemGen = self:GetUIComponent("UISelectObjectPath", "BigItemGen")
    self._rootLayout = self:GetUIComponent("LayoutElement", "Root")
    --generated end--
end
function UIXH1ShopItemGroupCell:SetData()
end
function UIXH1ShopItemGroupCell:InitData(data)
    local item = nil
    if data.GetIsSpecial and data:GetIsSpecial() then
        item = self._bigItemGen:SpawnObject("UIXH1ShopItemBig")
        self._rootLayout.minWidth = 366
        self._rootLayout.preferredWidth = 366
    else
        item = self._smallBoxGen:SpawnObject("UIXH1ShopSmallItemBox")
        self._rootLayout.minWidth = 366
        self._rootLayout.preferredWidth = 366
    end
    if item then
        item:InitData(data)
    --UIHelper.RefreshLayout(item:GetComponent("RectTransform"))
    end
    --UIHelper.RefreshLayout(self:GetGameObject():GetComponent("RectTransform"))
end
