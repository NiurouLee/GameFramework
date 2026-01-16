---@class UIN28AVGActor:UICustomWidget
_class("UIN28AVGActor", UICustomWidget)
UIN28AVGActor = UIN28AVGActor

function UIN28AVGActor:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = self.mCampaign:GetN28AVGData()

    self.effAnimTask = 0
end

function UIN28AVGActor:OnShow()
    ---@type RawImageLoader
    self.imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    self.anim = self:GetUIComponent("Animation", "anim")
    self.htRoot = self:GetGameObject( "value")
    --Leader使用
    if self.htRoot then
        self.htObjList = {}
        for i = 0, self.htRoot.transform.childCount - 1 do
            local trans = self.htRoot.transform:GetChild(i)
            table.insert(self.htObjList, trans:Find("full").gameObject)
        end
    end
    --Parter使用
    self.txtValue = self:GetUIComponent("UILocalizationText", "txtValue")
    self.eff = self:GetGameObject("eff")
end

function UIN28AVGActor:OnHide()
    self.imgIcon:DestoryLastImage()
    if self.effAnimTask > 0 then
        GameGlobal.TaskManager():KillTask(self.effAnimTask)
    end
end

---@param index number 角色索引，0表示为主角
---@param value number 角色数据值
function UIN28AVGActor:Flush(index, value, anim)
    local actor = self.data:GetActorByIndex(index)
    self:FlushIcon(actor)
    --Parter使用
    if self.txtValue then
        local curValue = tonumber(self.txtValue.text)
        if curValue then
            if value < curValue then
                --AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N28AVGHpReduce)
            elseif value > curValue then
                --AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N20HpAdd)
            end
        end
        self.txtValue:SetText(value)
    end
    --Leader使用
    if self.htRoot then
        for i = 1, #self.htObjList do
            local hasHeart = i <= value
            local heartObj = self.htObjList[i]
            if not hasHeart and heartObj.activeSelf and anim then
                self.eff.transform.position = heartObj.transform.position
                self.eff:SetActive(true)
                self.anim:Play("uieff_UIN28AVGActorLeader2_heart_root")
                AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N28AVGHpReduce)
                self.effAnimTask = self:StartTask(
                    function(TT)
                        YIELD(TT, 500)
                        self.eff:SetActive(false)
                        self.effAnimTask = 0
                    end,
                    self
                )
            end
            heartObj:SetActive(hasHeart) 
        end
    end
end



function UIN28AVGActor:FlushIcon(actor)
    self.imgIcon:LoadImage(actor.icon)
end

-- 1 = up
-- 2 = down
function UIN28AVGActor:PlayAnim(change)
    if change == 0 then
        return
    end
    local id = change > 0 and 1 or 2
    local animName = {
        "uieff_UIN28AVGActorLeader2_up",
        "uieff_UIN28AVGActorLeader2_down"
    }
    local animTime = {
        2000,
        1500
    }
    UIWidgetHelper.PlayAnimation(self, "anim", animName[id], animTime[id])
end
