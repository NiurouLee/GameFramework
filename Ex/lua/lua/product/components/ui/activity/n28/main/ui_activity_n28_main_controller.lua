---@class UIActivityN28MainController: UIController
_class("UIActivityN28MainController", UIController)
UIActivityN28MainController = UIActivityN28MainController

function UIActivityN28MainController:LoadDataOnEnter(TT, res, uiParams)
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)
    ---@type UIActivityN28Const
    self._activityConst = UIActivityN28Const:New()
    self._activityConst:LoadData(TT, res)
    if res and not res:GetSucc() then
        ---@type CampaignModule
        local campModule = GameGlobal.GetModule(CampaignModule)
        campModule:CheckErrorCode(res.m_result, self._activityConst:GetCampaignId(), nil, nil)
    end
end

function UIActivityN28MainController:OnShow(uiParams)
    self:AttachEvent(GameEventType.OnActivityTotalAwardGot, self.RefreshRedData)
    self:AttachEvent(GameEventType.CampaignComponentStepChange, self.RefreshRedData)
    self:AttachEvent(GameEventType.OnN26ActivityMainRedStatusRefresh, self.RefreshRedData)
    --红点和NEW相关
    self._eventRed = self:GetGameObject("EventRed")
    self._loginRed = self:GetGameObject("LoginRed")
    self._normalLevelRed = self:GetGameObject("NormalLevelRed")
    self._normalLevelNew = self:GetGameObject("NormalLevelNew")
    self._hardLevelRed = self:GetGameObject("HardLevelRed")
    self._hardLevelNew = self:GetGameObject("HardLevelNew")
    self._shopNew = self:GetGameObject("ShopNew")
    self._shopRed = self:GetGameObject("ShopRed")
    self._avgGameNew = self:GetGameObject("MiniGameNew")
    self._avgGameRed = self:GetGameObject("MiniGameRed")
    --普通线性关
    self._normalLevelRemainTimePanel = self:GetGameObject("NormalLevelRemainTimePanel")
    self._normalLevelEndPanel = self:GetGameObject("NormalLevelEndPanel")
    self._normalLevelRemainTimeLabel = self:GetUIComponent("UILocalizationText", "NormalLevelRemainTime")
    --困难关
    self._hardLevelEndPanel = self:GetGameObject("HardLevelEndPanel")
    self._hardLevelLockTipsPanel = self:GetGameObject("HardLevelLockTipsPanel")
    self._hardLevelRemainTimePanel = self:GetGameObject("HardLevelRemainTimePanel")
    self._hardLevelRemainTimeLabel = self:GetUIComponent("UILocalizationText", "HardLevelRemainTime")
    self._hardLevelLockTipsLabel = self:GetUIComponent("UILocalizationText", "HardLevelLockTips")
    --商店
    self._shopIconLoader = self:GetUIComponent("RawImageLoader", "ShopIcon")
    self._shopCountLabel = self:GetUIComponent("UILocalizationText", "ShopCount")
    --avg小游戏
    self._minGameEndPanel = self:GetGameObject("MiniGameEndPanel")
    self._minGameRemainTimePanel = self:GetGameObject("MiniGameRemainTimePanel")
    self._miniGameRemainTimeLabel = self:GetUIComponent("UILocalizationText", "MiniGameRemainTime")
    self._miniGameLockTipsPanel = self:GetGameObject("MiniGameLockTipsPanel")
    self._miniGameLockTipsLabel = self:GetUIComponent("UILocalizationText", "MiniGameLockTips")

    self._minGameMask = self:GetGameObject("MiniGameIcon")
    self._normalLevelMask = self:GetGameObject("NormalLevelIcon")
    self._hardLevelMask = self:GetGameObject("HardLevelIcon")
    self._shopIconMask = self:GetGameObject("ShopIcon")

    self._timeLabel = self:GetUIComponent("UILocalizationText", "Time")
    self._btnPanel = self:GetGameObject("BtnPanel")
    self._showBtn = self:GetGameObject("ShowBtn")
    self._showBtn:SetActive(false)
    self._anim = self:GetUIComponent("Animation", "Anim")
    self._shot = self:GetUIComponent("RawImage", "shot")
 
    self._topBtn = self:GetGameObject("TopBtn")
    local btns = self:GetUIComponent("UISelectObjectPath", "TopBtn")
    ---@type UICommonTopButton
    local backBtn = btns:SpawnObject("UICommonTopButton")
    backBtn:SetData(
        function()
            GameGlobal.TaskManager():StartTask(self.CloseCoro, self)
        end,
        nil,
        nil,
        false,
        function()
           -- self:SetButtonShowStatus(false)
            GameGlobal.TaskManager():StartTask(self.SetButtonShowStatus, self,false)
        end
    )

    self:InitUI()

    CutsceneManager.ExcuteCutsceneOut(
        function()
            UIActivityHelper.PlayFirstPlot_Campaign(self._activityConst:GetCampaign())
            -- if self._activityConst:CanPlayPlot() then
            --     self:PlayEnterPlot()
            -- end
        end
    )
    self._activityConst:ClearEnterNew()

    -- if uiParams[1]~=nil then
    --     self._shot.color=Color(255 / 255, 255 / 255, 255 / 255, 1)
    --     self._shot.texture = uiParams[1]
    --     self:PlayEnterAnim()
    -- else
    --     self._shot.color=Color(0 / 255, 0 / 255, 0 / 255, 1)
    --     self:PlayEnterAnim()
    -- end
    CutsceneManager.ExcuteCutsceneOut_Shot()
    self:PlayEnterAnim()

    self:_CheckGuide()
end

function UIActivityN28MainController:PlayEnterAnim()
    self:StartTask(self.PlayEnterAnimCoro, self)
end

function UIActivityN28MainController:PlayEnterAnimCoro(TT)
    self:Lock("UIActivityN26MainController_PlayEnterAnimCoro")
    self._anim:Play("uieff_UIActivityN28MainController_in")
    YIELD(TT,1500)
    self:UnLock("UIActivityN26MainController_PlayEnterAnimCoro")
    self:_CheckGuide()
end

function UIActivityN28MainController:_CheckGuide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIActivityN28MainController)
end


function UIActivityN28MainController:OnUpdate(deltaTimeMS)
    self:RefreshUI()
end

function UIActivityN28MainController:OnHide()
    self._normalLevelButtonStatus:Release()
    self._hardLevelButtonStatus:Release()
    self._avgGameButtonStatus:Release()
    self._normalLevelButtonStatusForTitle:Release()
    self:DetachEvent(GameEventType.OnActivityTotalAwardGot, self.RefreshRedData)
    self:DetachEvent(GameEventType.CampaignComponentStepChange, self.RefreshRedData)
    self:DetachEvent(GameEventType.OnN26ActivityMainRedStatusRefresh, self.RefreshRedData)
end

function UIActivityN28MainController:InitUI()
    self:RefreshShopBtnStatus()
    self:RefreshUI()
    self:RefreshNew()
    self:RefreshRed()
    --普通线性关
    ---@type UIActivityN28ButtonStatus
    self._normalLevelButtonStatus = UIActivityN28ButtonStatus:New(
        function()
            return self._activityConst:GetNormalLineMissionComponentStatus()
        end,
        function(TT)
            self:ReLoadData(TT, "normallevel")
        end,
        function(status, timeStr)
            self._normalLevelRemainTimePanel:SetActive(false)
            self._normalLevelEndPanel:SetActive(false)
            if status == ActivityN28ComponentStatus.Open then
                self._normalLevelMask:SetActive(false)
                self._normalLevelRemainTimePanel:SetActive(false)
                --self._normalLevelRemainTimeLabel:SetText(StringTable.Get("str_n28_activity_normal_level_remain_time", timeStr))
            elseif status == ActivityN28ComponentStatus.Close or status == ActivityN28ComponentStatus.ActivityEnd or status == ActivityN28ComponentStatus.None then
                self._normalLevelEndPanel:SetActive(false)
                self._normalLevelMask:SetActive(true)
            elseif status == ActivityN28ComponentStatus.TimeLock then
                self._normalLevelMask:SetActive(true)
            elseif status == ActivityN28ComponentStatus.MissionLock then
                self._normalLevelMask:SetActive(true)
            end
        end
    )
    --困难线性关
    ---@type UIActivityN28ButtonStatus
    self._hardLevelButtonStatus = UIActivityN28ButtonStatus:New(
        function()
            return self._activityConst:GetHardLineMissionComponentStatus()
        end,
        function(TT)
            self:ReLoadData(TT, "hardlevel")
        end,
        function(status, timeStr)
            self._hardLevelEndPanel:SetActive(false)
            self._hardLevelLockTipsPanel:SetActive(false)
            self._hardLevelRemainTimePanel:SetActive(false)
            if status == ActivityN28ComponentStatus.Open then
                self._hardLevelMask:SetActive(false)
                self._hardLevelRemainTimePanel:SetActive(false)
                --self._haqrdLevelRemainTimeLabel:SetText(StringTable.Get("str_n28_activity_hard_level_remain_time", timeStr))
            elseif status == ActivityN28ComponentStatus.Close or status == ActivityN28ComponentStatus.ActivityEnd or status == ActivityN28ComponentStatus.None then
                self._hardLevelEndPanel:SetActive(false)
                self._hardLevelMask:SetActive(true)
            elseif status == ActivityN28ComponentStatus.TimeLock then
                self._hardLevelLockTipsPanel:SetActive(true)
                self._hardLevelMask:SetActive(true)
                self._hardLevelLockTipsLabel:SetText(StringTable.Get("str_n28_activity_hard_level_lock_time_tips", timeStr))
            elseif status == ActivityN28ComponentStatus.MissionLock then
                self._hardLevelLockTipsPanel:SetActive(true)
                self._hardLevelMask:SetActive(true)
                self._hardLevelLockTipsLabel:SetText(StringTable.Get("str_n28_activity_hard_level_lock_mission_tips"))
            end
        end
    )
    --avg小游戏
    ---@type UIActivityN28ButtonStatus
    self._avgGameButtonStatus = UIActivityN28ButtonStatus:New(
        function()
            return self._activityConst:GetAVGGameComponentStatus()
        end,
        function(TT)
            self:ReLoadData(TT, "minigame")
        end,
        function(status, timeStr)
            self._minGameEndPanel:SetActive(false)
            self._minGameRemainTimePanel:SetActive(false)
            self._miniGameLockTipsPanel:SetActive(false)
            if status == ActivityN28ComponentStatus.Open then
                self._minGameMask:SetActive(false)
                self._minGameRemainTimePanel:SetActive(false)
                --self._miniGameRemainTimeLabel:SetText(StringTable.Get("str_n28_activity_minigame_remain_time", timeStr))
            elseif status == ActivityN28ComponentStatus.Close or status == ActivityN28ComponentStatus.ActivityEnd or status == ActivityN28ComponentStatus.None then
                self._minGameEndPanel:SetActive(false)
                self._minGameMask:SetActive(true)
            elseif status == ActivityN28ComponentStatus.TimeLock then
                self._miniGameLockTipsPanel:SetActive(true)
                self._minGameMask:SetActive(true)
                self._miniGameLockTipsLabel:SetText(StringTable.Get("str_n28_activity_minigame_lock_time_tips", timeStr))
            elseif status == ActivityN28ComponentStatus.MissionLock then
                self._miniGameLockTipsPanel:SetActive(true)
                self._minGameMask:SetActive(true)
                local tips = StringTable.Get("str_n28_activity_minigame_lock_mission_tips")
                self._miniGameLockTipsLabel:SetText(StringTable.Get("str_n28_activity_minigame_lock_mission_tips"))
            end
        end
    )
end

function UIActivityN28MainController:RefreshRedData()
    self:StartTask(function(TT)
        self:Lock("UIActivityN28MainController_ReLoadData")
        self:ReLoadData(TT, "Refresh")
        self:RefreshRed()
        self:RefreshShopBtnStatus()
        self:UnLock("UIActivityN28MainController_ReLoadData")
    end)
end

function UIActivityN28MainController:RefreshNew()
    self._normalLevelNew:SetActive(self._activityConst:IsShowNormalLineNew())
    self._hardLevelNew:SetActive(self._activityConst:IsShowHardLineNew())
    self._shopNew:SetActive(self._activityConst:IsShowShopNew())
    self._avgGameNew:SetActive(self._activityConst:IsShowAVGGameNew())
end

function UIActivityN28MainController:RefreshRed()
    self._eventRed:SetActive(self._activityConst:IsShowBattlePassRed())
    self._loginRed:SetActive(self._activityConst:IsShowLoginRed())
    self._normalLevelRed:SetActive(self._activityConst:IsShowNormalLineRed())
    self._hardLevelRed:SetActive(self._activityConst:IsShowHardLineRed())
    self._shopRed:SetActive(self._activityConst:IsShowShopRed())
    self._avgGameRed:SetActive(self._activityConst:IsShowAVGGameRed())
end

function UIActivityN28MainController:ReLoadData(TT, key)
    self:Lock("UIActivityN28MainController_ReLoadData" .. key)
    ---@type AsyncRequestRes
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    self._activityConst:LoadData(TT, res)
    self:UnLock("UIActivityN28MainController_ReLoadData" .. key)
end

function UIActivityN28MainController:CloseCoro(TT)
    self:Lock("UIActivityN21CCMainController_CloseCoro")
    self:SwitchState(UIStateType.UIMain)
    self:UnLock("UIActivityN21CCMainController_CloseCoro")
end

function UIActivityN28MainController:RefreshUI()
    self:RefreshActivityRemainTime()
end

function UIActivityN28MainController:RefreshActivityRemainTime()
    if self._activityConst:IsActivityEnd() then --活动结束
        --活动结束
        self._timeLabel:SetText(StringTable.Get("str_n28_activity_end"))
        return
    end
    -- self._activityConst
    local timeTips
    local endTime = self._activityConst:GetActiveEndTime()
    local nowTime = self._timeModule:GetServerTime() / 1000
    local seconds = math.floor(endTime - nowTime)
    if seconds <= 0 then
        seconds = 0
    end
    
    local ActivetimeStr = UIActivityN28Helper.GetTimeString(seconds)
    --当线性关开启时显示  "作战剩余时间："  当线性关关闭的时候显示  "活动剩余时间："
    ---@type UIActivityN28ButtonStatus
    self._normalLevelButtonStatusForTitle = UIActivityN28ButtonStatus:New(
        function()
            return self._activityConst:GetNormalLineMissionComponentStatus()
        end,
        function(TT)
            self:ReLoadData(TT, "normallevel")
        end,
        function(status, timeStr)
            if status == ActivityN28ComponentStatus.Open then
                timeTips = StringTable.Get("str_n28_activity_remain_time_line")..timeStr
            else
                timeTips = StringTable.Get("str_n28_activity_remain_time", ActivetimeStr)
            end
        end
    )

    self._timeLabel:SetText(timeTips)
end

function UIActivityN28MainController:SetButtonShowStatus(TT,isShow)
    self._showBtn:SetActive(not isShow)
    self._topBtn:SetActive(isShow)
    local aniName = "uieff_UIActivityN28MainController_show_out"
    if isShow then 
        aniName =   "uieff_UIActivityN28MainController_show_in"
    end 
    self:Lock("UIActivityN28MainController_SetButtonShowStatus")
    self._anim:Play(aniName)
    YIELD(TT,1500)
    self:UnLock("UIActivityN28MainController_SetButtonShowStatus")
end

function UIActivityN28MainController:PlayEnterPlot()
    self:ShowDialog("UIStoryController", self._activityConst:GetPlotId())
    self._activityConst:SetPlayPlotStatus()
end

function UIActivityN28MainController:RefreshShopBtnStatus()
    ---@type ExchangeItemComponent
    local shopCom, info = self._activityConst:GetShopComponent()

    local icon, count = shopCom:GetCostItemIconText()
    self._shopIconLoader:LoadImage(icon)
    self._shopCountLabel:SetText(UIActivityN28Helper.GetItemCountStr(7, count, "#b07f08", "#ffffff"))
end

---====================================== 按钮事件 =======================================

--详情
function UIActivityN28MainController:InfoBtnOnClick()
    self:ShowDialog("UIIntroLoader", "UIN28Intro")
end

--战斗通行证
function UIActivityN28MainController:EventOnClick()
    self:ShowDialog("UIActivityBattlePassN5MainController")
end

--登录奖励
function UIActivityN28MainController:LoginOnClick()
    local status, time = self._activityConst:GetLoginComponentStatus()
    if status == ActivityN28ComponentStatus.Close or status == ActivityN28ComponentStatus.ActivityEnd then
        ToastManager.ShowToast(StringTable.Get("str_n28_activity_end"))
        return
    end

    self:ShowDialog(
        "UIActivityTotalLoginAwardController",
        false,
        ECampaignType.CAMPAIGN_TYPE_N28,
        ECampaignN28ComponentID.ECAMPAIGN_N28_CUMULATIVE_LOGIN
    )
end

function UIActivityN28MainController:ShowBtnOnClick()
    --self:SetButtonShowStatus(true)
    GameGlobal.TaskManager():StartTask(self.SetButtonShowStatus, self,true)
end

function UIActivityN28MainController:PilotBtnOnClick()
    self:PlayEnterPlot()
end

function UIActivityN28MainController:NormalLevelOnClick()
    local status, time = self._activityConst:GetNormalLineMissionComponentStatus()
    if status == ActivityN28ComponentStatus.Close or status == ActivityN28ComponentStatus.ActivityEnd then
        ToastManager.ShowToast(StringTable.Get("str_n28_activity_end"))
        return
    end
    self._activityConst:ClearNormalLineNew()
    self:RefreshNew()

    -- Log.error("NormalLevelOnClick")
    self:SwitchState("UIN28Line")

end

function UIActivityN28MainController:HardLevelOnClick()
    local status, time = self._activityConst:GetHardLineMissionComponentStatus()
    if status == ActivityN28ComponentStatus.Close or status == ActivityN28ComponentStatus.ActivityEnd then
        ToastManager.ShowToast(StringTable.Get("str_n28_activity_end"))
        return
    elseif status == ActivityN28ComponentStatus.TimeLock then
        ToastManager.ShowToast(StringTable.Get("str_n28_activity_hard_level_lock_time_tips", UIActivityN28Helper.GetTimeString(time)))
        return
    elseif status == ActivityN28ComponentStatus.MissionLock then
        ToastManager.ShowToast(StringTable.Get("str_n28_activity_hard_level_lock_mission_tips"))
        return
    end
    self._activityConst:ClearHardLineNew()
    self:RefreshNew()

    -- Log.error("HardLevelOnClick")
    self:ShowDialog("UIN28HardLevel")
end

function UIActivityN28MainController:ShopOnClick()
    local status, time = self._activityConst:GetShopComponentStatus()
    if status == ActivityN28ComponentStatus.Close or status == ActivityN28ComponentStatus.ActivityEnd then
        ToastManager.ShowToast(StringTable.Get("str_n28_activity_end"))
        return
    end
    self._activityConst:ClearShopNew()
    self:RefreshNew()
    self:ShowDialog("UIActivityN28Shop")
end

function UIActivityN28MainController:AVGGameOnClick()
    local status, time = self._activityConst:GetAVGGameComponentStatus()
    if status == ActivityN28ComponentStatus.Close or status == ActivityN28ComponentStatus.ActivityEnd then
        ToastManager.ShowToast(StringTable.Get("str_n28_activity_end"))
        return
    elseif status == ActivityN28ComponentStatus.TimeLock then
        ToastManager.ShowToast(StringTable.Get("str_n28_activity_minigame_lock_time_tips", UIActivityN28Helper.GetTimeString(time)))
        return
    elseif status == ActivityN28ComponentStatus.MissionLock then
        ToastManager.ShowToast(StringTable.Get("str_n28_activity_minigame_lock_mission_tips"))
        return
    end
    self._activityConst:ClearAVGGameNew()
    self:RefreshNew()

    self:SwitchState(UIStateType.UIN28AVGMain)
end

---=======================================================================================
