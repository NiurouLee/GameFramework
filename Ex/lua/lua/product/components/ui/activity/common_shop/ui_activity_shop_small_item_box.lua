---@class UIActivityShopSmallItemBox : UICustomWidget
_class("UIActivityShopSmallItemBox", UICustomWidget)
UIActivityShopSmallItemBox = UIActivityShopSmallItemBox
function UIActivityShopSmallItemBox:OnShow(uiParams)
    self:InitWidget()
end
function UIActivityShopSmallItemBox:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self._smallItemGen = self:GetGameObject("SmallItemGen")
    self._smallItemsPool = self:GetUIComponent("UISelectObjectPath", "SmallItemGen")
    --generated end--
end
function UIActivityShopSmallItemBox:SetData()
end
function UIActivityShopSmallItemBox:InitData(data)
    local itemList = self._smallItemsPool:SpawnObjects("UIActivityShopItemSmall",#data)
    for index, value in ipairs(itemList) do
        value:InitData(data[index])
    end
end
