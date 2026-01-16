---@class UIN20AVGActor:UICustomWidget
_class("UIN20AVGActor", UICustomWidget)
UIN20AVGActor = UIN20AVGActor

function UIN20AVGActor:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = self.mCampaign:GetN20AVGData()
end

function UIN20AVGActor:OnShow()
    ---@type RawImageLoader
    self.imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    ---@type UILocalizationText
    self.txtValue = self:GetUIComponent("UILocalizationText", "txtValue")
end

function UIN20AVGActor:OnHide()
    self.imgIcon:DestoryLastImage()
end

---@param index number 角色索引，0表示为主角
---@param value number 角色数据值
function UIN20AVGActor:Flush(index, value)
    local actor = self.data:GetActorByIndex(index)
    self:FlushIcon(actor)
    local curValue = tonumber(self.txtValue.text)
    if curValue then
        if value < curValue then
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N20HpReduce)
        elseif value > curValue then
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N20HpAdd)
        end
    end
    self.txtValue:SetText(value)
end

function UIN20AVGActor:FlushIcon(actor)
    self.imgIcon:LoadImage(actor.icon)
end

-- 1 = up
-- 2 = down
function UIN20AVGActor:PlayAnim(change)
    if change == 0 then
        return
    end
    local id = change > 0 and 1 or 2
    local animName = {
        "uieff_UIN20AVGActorLeader2_up",
        "uieff_UIN20AVGActorLeader2_down"
    }
    local animTime = {
        2000,
        1500
    }
    UIWidgetHelper.PlayAnimation(self, "anim", animName[id], animTime[id])
end
