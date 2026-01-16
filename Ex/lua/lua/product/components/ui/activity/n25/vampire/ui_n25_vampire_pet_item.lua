---@class UIN25VampirePetItem : UICustomWidget
_class("UIN25VampirePetItem", UICustomWidget)
UIN25VampirePetItem = UIN25VampirePetItem

function UIN25VampirePetItem:Constructor()
    self.mCampaign = self:GetModule(CampaignModule)
    self.data = self.mCampaign:GetN25Data()
end

function UIN25VampirePetItem:OnShow(uiParams)
    ---@type RawImageLoader
    self.Icon = self:GetUIComponent("RawImageLoader", "Icon")
end

function UIN25VampirePetItem:OnHide()
    self.Icon:DestoryLastImage()
end
function UIN25VampirePetItem:Flush(tplId, callback)
    self.callback = callback
    local pet = self.data:GetPetByTplId(tplId)
    -- self.Icon:LoadImage(pet:GetPetItemIcon(PetSkinEffectPath.ITEM_ICON_PET_DETAIL))
    self.Icon:LoadImage(pet:Icon())
end

function UIN25VampirePetItem:IconOnClick(go)
    if self.callback then
        self.callback()
    end
end
