--时装get item cell
---@class UIHauteCoutureDrawGetItemCellGL : UICustomWidget
_class("UIHauteCoutureDrawGetItemCellGL", UICustomWidget)
UIHauteCoutureDrawGetItemCellGL = UIHauteCoutureDrawGetItemCellGL

function UIHauteCoutureDrawGetItemCellGL:Constructor()
    self._atlas = self:GetAsset("UIHauteCoutureGL.spriteatlas", LoadType.SpriteAtlas)
end

function UIHauteCoutureDrawGetItemCellGL:OnShow()
    --generated--
    ---@type UnityEngine.UI.Image
    self.qualitybg = self:GetUIComponent("Image", "qualitybg")
    ---@type RawImageLoader
    self.imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    ---@type UILocalizationText
    self.txtCount = self:GetUIComponent("UILocalizationText", "txtCount")
    ---@type UILocalizationText
    self.name = self:GetUIComponent("UILocalizationText", "name")
    ---@type UnityEngine.GameObject
    self.select = self:GetGameObject("select")
    ---@type UnityEngine.UI.Image
    self.bg = self:GetUIComponent("Image", "bg")
    --generated end--
end

function UIHauteCoutureDrawGetItemCellGL:SetData(itemInfo, showName, clickCallback)
    --id
    self._item_id = itemInfo.item_id

    --index
    self._item_index = itemInfo.item_index
    --name
    if showName then
        self.name:SetText(StringTable.Get(itemInfo.item_name))
    else
        self.name:SetText("")
    end
    --count
    self.txtCount:SetText(itemInfo.item_count)
    --icon
    local icon = itemInfo.icon
    self.imgIcon:LoadImage(icon)
    --quality
    local quality = itemInfo.color
    self.qualitybg.sprite = self._atlas:GetSprite("N17_produce_bg_item_" .. quality)

    self._clickCallback = clickCallback
end

function UIHauteCoutureDrawGetItemCellGL:EnableInteract(enable)
   -- self.bg.interactable = enable
end

function UIHauteCoutureDrawGetItemCellGL:BgOnClick(go)
    if self._clickCallback then
        self._clickCallback(self._item_index, go.transform.position)
    end
end

