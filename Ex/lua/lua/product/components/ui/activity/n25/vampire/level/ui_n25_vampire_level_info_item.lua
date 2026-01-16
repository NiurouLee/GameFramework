---@class UIN25VampireLevelInfoItem : UICustomWidget
_class("UIN25VampireLevelInfoItem", UICustomWidget)
UIN25VampireLevelInfoItem = UIN25VampireLevelInfoItem

function UIN25VampireLevelInfoItem:Constructor()
    self.mCampaign = self:GetModule(CampaignModule)
end

function UIN25VampireLevelInfoItem:OnShow(uiParams)
    self._atlas = self:GetAsset("UIN25VampireTaskAndLevel.spriteatlas", LoadType.SpriteAtlas)
    ---@type Image
    self.iconimg = self:GetUIComponent("Image", "icon")

    ---@type UILocalizationText
    self.contenttxt = self:GetUIComponent("UILocalizationText", "contenttxt")

end

function UIN25VampireLevelInfoItem:OnHide()

end
function UIN25VampireLevelInfoItem:Flush(data,callback)
    self.callback = callback
    self.data = data
    --self.iconimg.sprite =  self._atlas:GetSprite("N25_mcwf_di1")
    self.contenttxt:SetText(StringTable.Get(self.data.MissionDec))
end

function UIN25VampireLevelInfoItem:IconOnClick(go)
    if self.callback then
        self.callback()
    end
end
