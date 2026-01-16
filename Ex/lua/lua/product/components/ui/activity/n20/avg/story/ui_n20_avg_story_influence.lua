---@class UIN20AVGStoryInfluence:UICustomWidget
_class("UIN20AVGStoryInfluence", UICustomWidget)
UIN20AVGStoryInfluence = UIN20AVGStoryInfluence

function UIN20AVGStoryInfluence:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = self.mCampaign:GetN20AVGData()
    AudioHelperController.RequestUISoundSync(CriAudioIDConst.N20Heartbeat)
    self.animNames = {
        "uieff_UIN20AVGStoryInfluence_influence_in", --2800
        "uieff_UIN20AVGStoryInfluence_influence_loop", --3933
        "uieff_UIN20AVGStoryInfluence_ring_in", --2000
        "uieff_UIN20AVGStoryInfluence_ring_loop" --2000
    }
    self.animOutNames = {
        "uieff_UIN20AVGStoryInfluence_influence_out", --333
        "uieff_UIN20AVGStoryInfluence_ring_out" --1300
    }
    self.taskIdPress = 0
    self.taskIdRelease = 0
end

function UIN20AVGStoryInfluence:OnShow()
    ---@type UnityEngine.Animation
    self.anim = self:GetUIComponent("Animation", "root")
    ---@type UnityEngine.Animation
    self.animOut = self:GetUIComponent("Animation", "out")
    self.imgInfluence = self:GetGameObject("imgInfluence")
    self.imgInfluence:SetActive(false)
    self.imgInfluenceNormal = self:GetGameObject("imgInfluenceNormal")
    self.imgInfluencePress = self:GetGameObject("imgInfluencePress")
    self.imgInfluencePress:SetActive(false)
    ---@type UnityEngine.UI.Image
    self.imgBtnInfluence = self:GetUIComponent("Image", "btnInfluence")
    self.btnInfluence = self:GetGameObject("btnInfluence")
    ---@type UICustomWidgetPool
    self.poolOptions = self:GetUIComponent("UISelectObjectPath", "options")
    self.options = self:GetGameObject("options")
    self.options:SetActive(false)

    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlas = self:GetAsset("UIAVG.spriteatlas", LoadType.SpriteAtlas)
    self:RegisterUICustomUIEventListener()
    self._audioCount = 0
end

function UIN20AVGStoryInfluence:OnHide()
    self.anim = nil
    self.animOut = nil
    self.taskIdPress = 0
    self.taskIdRelease = 0
    self:UnRegisterUICustomUIEventListener()
    AudioHelperController.ReleaseUISoundById(CriAudioIDConst.N20Heartbeat)
end

-- function UIN20AVGStoryInfluence:OnUpdate()
-- end

--region UICustomUIEventListener
function UIN20AVGStoryInfluence:RegisterUICustomUIEventListener()
    local etl = UICustomUIEventListener.Get(self.btnInfluence)
    self:AddUICustomEventListener(
        etl,
        UIEvent.Press,
        function(ped)
            self.imgInfluence:SetActive(true)
            self.imgInfluenceNormal:SetActive(false)
            self.imgInfluencePress:SetActive(true)
            self.imgBtnInfluence.sprite = self.atlas:GetSprite("N20_avg_dh_icon16")
            self.options:SetActive(true)
            if self._audioCount == 0 then
                self._soundPlayingID = AudioHelperController.PlayUISoundResource(CriAudioIDConst.N20Heartbeat, true)
                self._audioCount = self._audioCount + 1
            end
            GameGlobal.EventDispatcher():Dispatch(GameEventType.AVGShowHideOptionInfluence, true)
            self:PlayAnimPress()
        end
    )
    self:AddUICustomEventListener(
        etl,
        UIEvent.Release,
        function(ped)
            self.imgInfluence:SetActive(false)
            self.imgInfluenceNormal:SetActive(true)
            self.imgInfluencePress:SetActive(false)
            self.imgBtnInfluence.sprite = self.atlas:GetSprite("N20_avg_dh_icon08")
            self.options:SetActive(false)
            if self._audioCount == 1 then
                if self._soundPlayingID then
                    AudioHelperController.StopUISound(self._soundPlayingID)
                end
                self._audioCount = self._audioCount - 1
            end
            GameGlobal.EventDispatcher():Dispatch(GameEventType.AVGShowHideOptionInfluence, false)
            self:PlayAnimRelease()
        end
    )
end

function UIN20AVGStoryInfluence:UnRegisterUICustomUIEventListener()
    self:RemoveAllCustomEventListener()
end

--endregion

---@param options AVGStoryOption[]
function UIN20AVGStoryInfluence:Flush(options)
    local len = table.count(options)
    self.poolOptions:SpawnObjects("UIN20AVGStoryInfluenceItem", len)
    ---@type UIN20AVGStoryInfluenceItem[]
    local uis = self.poolOptions:GetAllSpawnList()
    for i, option in ipairs(options) do
        local ui = uis[i]
        ui:Flush(option)
    end
    self:PlayAnimRelease()
end

--region Anim
function UIN20AVGStoryInfluence:PlayAnimPress()
    if not self.anim then
        return
    end
    self:StopAnim()
    self:StopAnimOut()
    self:PlayAnimOfItem("PlayAnimIn")
    self:KillTaskPress()
    self:KillTaskRelease()
    self.taskIdPress =
        self:StartTask(
        function(TT)
            self:PlayAnimOutRing()
            if self.anim then
                self.anim:Play(self.animNames[1])
            end
            YIELD(TT, 2800)
            if self.anim then
                self.anim:Play(self.animNames[2])
            end
            self.taskIdPress = 0
        end,
        self
    )
end
function UIN20AVGStoryInfluence:PlayAnimRelease()
    if not self.anim then
        return
    end
    self:StopAnim()
    self:StopAnimOut()
    self:PlayAnimOfItem("PlayAnimOut")
    self:KillTaskPress()
    self:KillTaskRelease()
    self.taskIdRelease =
        self:StartTask(
        function(TT)
            self:PlayAnimOutInfluence()
            if self.anim then
                self.anim:Play(self.animNames[3])
            end
            YIELD(TT, 2000)
            if self.anim then
                self.anim:Play(self.animNames[4])
            end
            self.taskIdRelease = 0
        end,
        self
    )
end
function UIN20AVGStoryInfluence:PlayAnimOutRing()
    if not self.animOut then
        return
    end
    self.animOut:Play(self.animOutNames[2])
end
function UIN20AVGStoryInfluence:PlayAnimOutInfluence()
    if not self.animOut then
        return
    end
    self.animOut:Play(self.animOutNames[1])
end
function UIN20AVGStoryInfluence:StopAnim()
    if not self.anim then
        return
    end
    for index, animName in ipairs(self.animNames) do
        ---@type UnityEngine.AnimationState
        local state = self.anim:get_Item(animName)
        state.normalizedTime = 0
    end
    self.anim:Stop()
end
function UIN20AVGStoryInfluence:StopAnimOut()
    if not self.animOut then
        return
    end
    for index, animName in ipairs(self.animOutNames) do
        ---@type UnityEngine.AnimationState
        local state = self.animOut:get_Item(animName)
        state.normalizedTime = 0
    end
    self.animOut:Stop()
end
function UIN20AVGStoryInfluence:PlayAnimOfItem(animName)
    ---@type UIN20AVGStoryInfluenceItem[]
    local uis = self.poolOptions:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        if ui[animName] then
            ui[animName](ui)
        end
    end
end
function UIN20AVGStoryInfluence:KillTaskPress()
    -- if GameGlobal.TaskManager():FindTask(self.taskIdPress) then
    if self.taskIdPress > 0 then
        GameGlobal.TaskManager():KillTask(self.taskIdPress)
    end
end
function UIN20AVGStoryInfluence:KillTaskRelease()
    -- if GameGlobal.TaskManager():FindTask(self.taskIdRelease) then
    if self.taskIdRelease > 0 then
        GameGlobal.TaskManager():KillTask(self.taskIdRelease)
    end
end
--endregion
