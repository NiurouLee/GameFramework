--
---@class UIMedalListItem : UICustomWidget
_class("UIMedalListItem", UICustomWidget)
UIMedalListItem = UIMedalListItem

function UIMedalListItem:Constructor()
    ---@type UIMedalItemData
    self.itemData = nil
    self.callBack = nil
    self._atlas = self:GetAsset("UIMedal.spriteatlas", LoadType.SpriteAtlas)
end

--初始化
function UIMedalListItem:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIMedalListItem:InitWidget()
    ---@type UnityEngine.GameObject
    self.select = self:GetGameObject("select")
    ---@type UnityEngine.GameObject
    self.red = self:GetGameObject("red")
    ---@type UnityEngine.GameObject
    self.lock = self:GetGameObject("lock")
    ---@type UnityEngine.UI.Image
    self.icon = self:GetUIComponent("Image", "icon")
    ---@type UnityEngine.RectTransform
    self.iconRt = self:GetUIComponent("RectTransform", "icon")
end

function UIMedalListItem:GetData()
    return self.itemData
end

function UIMedalListItem:GetID()
    return self.itemData:GetTemplID()
end

--设置数据
---@param itemData UIMedalItemData
function UIMedalListItem:SetData(itemData, isSelect, callback)
    self.itemData = itemData
    self.callBack = callback

    self.select:SetActive(isSelect)
    self.lock:SetActive(not itemData:IsReceive())
    local cfgMedal = itemData:GetTempl()
    local iconSp = self._atlas:GetSprite(cfgMedal.Icon)
    if iconSp then
        local rect = iconSp.rect
        self.icon.sprite = iconSp
        self.iconRt.sizeDelta = Vector2(rect.width * 0.4, rect.height * 0.4)
    end
    self.red:SetActive(itemData:IsNew())
end

function UIMedalListItem:SetSelect(bSelect)
    self.select:SetActive(bSelect)
end

--按钮点击
function UIMedalListItem:BgOnClick(go)
    if self.callBack then
        self.callBack(self)
    end
end

function UIMedalListItem:SetNewReviewed()
    self.red:SetActive(false)
end
