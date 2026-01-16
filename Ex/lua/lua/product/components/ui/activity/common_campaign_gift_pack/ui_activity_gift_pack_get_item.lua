---@class UIActivityGiftPackGetItem:UICustomWidget
_class("UIActivityGiftPackGetItem", UICustomWidget)
UIActivityGiftPackGetItem = UIActivityGiftPackGetItem

function UIActivityGiftPackGetItem:OnShow()
    ---@type RawImageLoader
    self._imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    ---@type UILocalizationText
    self._txtName = self:GetUIComponent("UILocalizationText", "txtName")
    ---@type UILocalizationText
    self._txtCount = self:GetUIComponent("UILocalizationText", "txtCount")
end

---@param award GiftPackShopItemAward
function UIActivityGiftPackGetItem:Flush(award)
    if not award then
        Log.fatal("### award is nil.")
        return
    end
    self._imgIcon:LoadImage(award:GetIcon())
    self._txtName:SetText(award:GetName())
    self._txtCount:SetText("x" .. award:GetCount())

    self.ra = RoleAsset:New()
    self.ra.assetid = award:GetTemplateId()
    self.ra.count = award:GetCount()
end

function UIActivityGiftPackGetItem:BgOnClick(go)
    if self.ra.assetid >= RoleAssetID.RoleAssetPetSkinBegin and self.ra.assetid <= RoleAssetID.RoleAssetPetSkinEnd then
        --cfg_item 表中id处于4000000~4999999之间的为时装id
        self:ShowDialog("UIPetSkinsMainController", PetSkinUiOpenType.PSUOT_TIPS, self.ra.assetid - 4000000)
    else
        self:ShowDialog("UIItemTips", self.ra, go, "UIActivityGiftPackDetail")
    end
end
