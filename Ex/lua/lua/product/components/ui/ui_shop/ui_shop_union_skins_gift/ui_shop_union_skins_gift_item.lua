---@class ShopUnionSkinsGiftItem:Object
_class("ShopUnionSkinsGiftItem", Object)
ShopUnionSkinsGiftItem = ShopUnionSkinsGiftItem
function ShopUnionSkinsGiftItem:Constructor(skinData, giftData)
    ---@type SkinsShopItem
    self._skinData = skinData
    ---@type GiftPackShopItem
    self._giftData = giftData

    self._id = 0
    self._order = 0     -- min --> max

    if self._skinData ~= nil then
        self._id = self._skinData:GetId()

        local cfgv = Cfg.cfg_shop_common_goods[self._id]
        if cfgv ~= nil then
            self._order = cfgv.SequenceId
        end
    end

    if self._giftData ~= nil then
        self._id = self._giftData:GetId()

        local cfgv = Cfg.cfg_shop_giftmarket_goods[self._id]
        if cfgv ~= nil then
            self._order = cfgv.SequenceId
        end
    end
end

function ShopUnionSkinsGiftItem:GetId()
    return self._id
end

function ShopUnionSkinsGiftItem:GetOrder()
    return self._order
end

function ShopUnionSkinsGiftItem:IsResident()
    if self._skinData ~= nil then
        return self._skinData:IsResident()
    end

    if self._giftData ~= nil then
        return false
    end

    return false
end

function ShopUnionSkinsGiftItem:HasSoldOut()
    if self._skinData ~= nil then
        return self._skinData:HasSoldOut()
    end

    if self._giftData ~= nil then
        return false
    end

    return false
end

function ShopUnionSkinsGiftItem:GetSkinData()
    return self._skinData
end

function ShopUnionSkinsGiftItem:GetGiftData()
    return self._giftData
end


---@class UIShopUnionSkinsGiftItem : UICustomWidget
_class("UIShopUnionSkinsGiftItem", UICustomWidget)
UIShopUnionSkinsGiftItem = UIShopUnionSkinsGiftItem
function UIShopUnionSkinsGiftItem:Constructor()
    self._dataItem = nil
    self._uiSkinItem = nil
    self._uiGiftItem = nil
end

function UIShopUnionSkinsGiftItem:OnShow(uiParams)
    self._UIShopSkinsItem = self:GetUIComponent("UISelectObjectPath", "UIShopSkinsItem")
    self._UIShopGiftPackItem = self:GetUIComponent("UISelectObjectPath", "UIShopGiftPackItem")
end

function UIShopUnionSkinsGiftItem:OnHide()

end

---@param dataItem ShopUnionSkinsGiftItem
---@param fnSkinFlush function
---@param fnGiftFlush function
function UIShopUnionSkinsGiftItem:Flush(dataItem, fnSkinFlush, fnGiftFlush)
    self._dataItem = dataItem

    local dataSkin = self._dataItem:GetSkinData()
    local dataGift = self._dataItem:GetGiftData()

    if self._uiSkinItem ~= nil then
        self._uiSkinItem:Enable(false)
    end

    if self._uiGiftItem ~= nil then
        self._uiGiftItem:Enable(false)
    end

    if dataSkin ~= nil and fnSkinFlush ~= nil then
        self._uiSkinItem = self._UIShopSkinsItem:SpawnObject("UIShopSkinsItem")
        self._uiSkinItem:Enable(true)
        fnSkinFlush(self._uiSkinItem)
    end

    if dataGift ~= nil and fnGiftFlush ~= nil then
        self._uiGiftItem = self._UIShopGiftPackItem:SpawnObject("UIShopGiftPackItemContainer")
        self._uiGiftItem:Enable(true)
        fnGiftFlush(self._uiGiftItem)
    end
end

function UIShopUnionSkinsGiftItem:JumpItem()
    if self:GetUISkinItem() ~= nil then
        self:GetUISkinItem():bgOnClick()
    end

    if self:GetUIGiftItem() ~= nil then
        self:GetUIGiftItem():OpenUIShopGiftPackDetail()
    end
end

function UIShopUnionSkinsGiftItem:GetDataItem()
    return self._dataItem
end

function UIShopUnionSkinsGiftItem:GetUISkinItem()
    return self._uiSkinItem
end

function UIShopUnionSkinsGiftItem:GetUIGiftItem()
    return self._uiGiftItem
end

