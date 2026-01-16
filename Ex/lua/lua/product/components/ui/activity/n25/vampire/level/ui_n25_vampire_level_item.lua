---@class UIN25VampireLevelItem : UICustomWidget
_class("UIN25VampireLevelItem", UICustomWidget)
UIN25VampireLevelItem = UIN25VampireLevelItem

function UIN25VampireLevelItem:Constructor()
    self.mCampaign = self:GetModule(CampaignModule)
end

function UIN25VampireLevelItem:OnShow(uiParams)
    self._atlas = self:GetAsset("UIN25VampireTaskAndLevel.spriteatlas", LoadType.SpriteAtlas)

    ---@type UILocalizationText
    self.titletxt1 = self:GetUIComponent("UILocalizationText", "title1")
    ---@type UILocalizationText
    self.titletxt2 = self:GetUIComponent("UILocalizationText", "title2")

    ---@type UILocalizationText
    self.exptxt1 = self:GetUIComponent("UILocalizationText", "count1")
    ---@type UILocalizationText
    self.exptxt2 = self:GetUIComponent("UILocalizationText", "count2")
    ---@type UILocalizationText
    self.lockGo = self:GetGameObject( "lock")
    self.root = self:GetGameObject( "root")
    self.anim = self:GetUIComponent("Animation", "ani")
    self.bg1 = self:GetGameObject( "bg1")
    self.bg2 = self:GetGameObject( "bg2")

    self.btn = self:GetGameObject( "Btn")
    self.eff = self:GetGameObject( "eff")
    self:AttachEvent(GameEventType.OnVampireChallengeTaskItemClick,self.OnVampireChallengeTaskItemClick)

end

function UIN25VampireLevelItem:OnHide()
    self:DetachEvent(GameEventType.OnVampireChallengeTaskItemClick,self.OnVampireChallengeTaskItemClick)
end
function UIN25VampireLevelItem:Flush(data,manager,activity,sv)
    self.root:SetActive(true)
    self.anim:Play("uieffanim_UIN25VampireLevelItem_in")
    self.manager = manager
    self.data = data
    self.itemId =  data.ID
    ---@type UIActivityN25Const
    self.activityN25Const = activity
   -- self.iconimg.sprite =  self._atlas:GetSprite("N25_mcwf_di1")
    self._scrollRect = sv
    self.exptxt1:SetText(self.data.WaveDesc)
    self.exptxt2:SetText(self.data.WaveDesc)
    self.titletxt1:SetText(StringTable.Get(self.data.MissionName))
    self.titletxt2:SetText(StringTable.Get(self.data.MissionName))
    local lastMissionPassed  = true 
    if self.data.NeedMission then
        lastMissionPassed = self.activityN25Const:CheckBloodSuckerMissionPassed(self.data.NeedMission)
    end  
    local passed = self.activityN25Const:CheckBloodSuckerMissionPassed(self.data.CampaignMissionID)
    self.lockGo:SetActive(not (passed or (lastMissionPassed and (not passed))))
    self.bg2:SetActive(lastMissionPassed and (not passed))
    self.bg1:SetActive(not (lastMissionPassed and (not passed)))
    self.isLock = not (passed or (lastMissionPassed and (not passed))) 
    self.eff:SetActive(not self.isLock )
    if self.btn then
        self.etl = UICustomUIEventListener.Get(self.btn)
        self:AddUICustomEventListener(
            self.etl,
            UIEvent.BeginDrag,
            function(eventData)
                self._draging = true
                self._scrollRect:OnBeginDrag(eventData)
            end
        )
        self:AddUICustomEventListener(
            self.etl,
            UIEvent.Drag,
            function(eventData)
                self._scrollRect:OnDrag(eventData)
            end
        )
        self:AddUICustomEventListener(
            self.etl,
            UIEvent.EndDrag,
            function(eventData)
                self._draging = false
                self._scrollRect:OnEndDrag(eventData)
            end
        )
    
    end
end

function UIN25VampireLevelItem:BtnOnClick(go)
    if self.isLock then
        ToastManager.ShowToast(StringTable.Get("str_n25_level_lock"))
        return 
    end 
    if self.manager then
        self.manager:OnSelectItem(self.itemId)
    end
end

function UIN25VampireLevelItem:OnVampireChallengeTaskItemClick(id)
    self.bg2:SetActive(self.itemId == id)
    self.bg1:SetActive(self.itemId ~= id)
end

function UIN25VampireLevelItem:OnDrag(id)
  
end


function UIN25VampireLevelItem:OnBeginDrag(id)
  
end


function UIN25VampireLevelItem:OnEndDrag(id)

end


