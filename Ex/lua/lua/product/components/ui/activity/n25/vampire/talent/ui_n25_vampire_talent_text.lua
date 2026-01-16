---@class UIN25VampireTalentText : UICustomWidget
_class("UIN25VampireTalentText", UICustomWidget)
UIN25VampireTalentText = UIN25VampireTalentText

function UIN25VampireTalentText:Constructor()
    self.mCampaign = self:GetModule(CampaignModule)
    self.data = self.mCampaign:GetN25Data()
end

function UIN25VampireTalentText:OnShow(uiParams)
    ---@type UnityEngine.UI.Image
    self.imgTen = self:GetUIComponent("Image", "imgTen")
    ---@type UnityEngine.UI.Image
    self.imgOne = self:GetUIComponent("Image", "imgOne")

    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlas = self:GetAsset("UIN25Vampire.spriteatlas", LoadType.SpriteAtlas)
end

function UIN25VampireTalentText:OnHide()
end

---@param num number
---@param prefix string 前缀
function UIN25VampireTalentText:Flush(num, prefix)
    local str = tostring(num)
    local one = string.sub(str, -1)
    local ten = string.sub(str, -2, -2)
    self.imgOne.sprite = self.atlas:GetSprite(prefix .. one)
    if string.isnullorempty(ten) then
        self.imgTen.gameObject:SetActive(false)
    else
        self.imgTen.gameObject:SetActive(true)
        self.imgTen.sprite = self.atlas:GetSprite(prefix .. ten)
    end
end
