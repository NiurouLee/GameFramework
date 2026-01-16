---@class UIN20AVGActorValueChange:UICustomWidget
_class("UIN20AVGActorValueChange", UICustomWidget)
UIN20AVGActorValueChange = UIN20AVGActorValueChange

function UIN20AVGActorValueChange:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = self.mCampaign:GetN20AVGData()
end

function UIN20AVGActorValueChange:OnShow()
    ---@type RawImageLoader
    self.imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    self.up = self:GetGameObject("up")
    self.down = self:GetGameObject("down")
end

function UIN20AVGActorValueChange:OnHide()
    self.imgIcon:DestoryLastImage()
end

---@param index number 角色索引，0表示为主角
---@param influenceValueChange number 影响值
function UIN20AVGActorValueChange:Flush(index, influenceValueChange)
    local actor = self.data:GetActorByIndex(index)
    self.imgIcon:LoadImage(actor.iconOption)
    if influenceValueChange > 0 then
        self.up:SetActive(true)
        self.down:SetActive(false)
    else
        self.up:SetActive(false)
        self.down:SetActive(true)
    end
end
