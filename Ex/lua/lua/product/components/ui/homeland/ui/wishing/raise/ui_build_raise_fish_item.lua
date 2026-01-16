---@class UIBuildRaiseFishItem:UICustomWidget
_class("UIBuildRaiseFishItem", UICustomWidget)
UIBuildRaiseFishItem = UIBuildRaiseFishItem

function UIBuildRaiseFishItem:OnShow(uiParams)
    self._iconLoader = self:GetUIComponent("RawImageLoader", "Icon")
    self._countLabel = self:GetUIComponent("UILocalizationText", "Count")
    self._quatyImg = self:GetUIComponent("Image", "Quaty")
    self._quatyGo = self:GetGameObject("Quaty")
    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlas = self:GetAsset("UIHomelandBackpack.spriteatlas", LoadType.SpriteAtlas)
end

function UIBuildRaiseFishItem:OnHide()
    self.atlas = nil
end

---@param raiseFish UIBuildRaiseFish
---@param raiseFishData UIBuildRaiseFishData
function UIBuildRaiseFishItem:Refresh(raiseFish, raiseFishData)
    ---@type UIBuildRaiseFishData
    self._raiseFishData = raiseFishData
    self._iconLoader:LoadImage(raiseFishData:GetIcon())
    self._countLabel:SetText(raiseFishData:GetCount())
    self._quatyImg.sprite = self.atlas:GetSprite("n17_shop_kuang0" .. raiseFishData:GetColor())
    ---@type UIBuildRaiseFish
    self._raiseFish = raiseFish
end

function UIBuildRaiseFishItem:BtnOnClick(go)
    self._raiseFish:RaiseFish(self._raiseFishData)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.HomelandAudioFishJumpIntoWater)
end
