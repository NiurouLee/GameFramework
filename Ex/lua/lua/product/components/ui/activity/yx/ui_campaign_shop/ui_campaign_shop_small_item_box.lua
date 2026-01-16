---@class UICampaignShopSmallItemBox : UICustomWidget
_class("UICampaignShopSmallItemBox", UICustomWidget)
UICampaignShopSmallItemBox = UICampaignShopSmallItemBox
function UICampaignShopSmallItemBox:OnShow(uiParams)
    self:InitWidget()
end
function UICampaignShopSmallItemBox:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self._smallItemGen = self:GetGameObject("SmallItemGen")
    self._smallItemsPool = self:GetUIComponent("UISelectObjectPath", "SmallItemGen")
    --generated end--
end
function UICampaignShopSmallItemBox:SetData()
end
function UICampaignShopSmallItemBox:InitData(data)
    local itemList = self._smallItemsPool:SpawnObjects("UICampaignShopItemSmall",#data)
    for index, value in ipairs(itemList) do
        value:InitData(data[index])
    end
end
