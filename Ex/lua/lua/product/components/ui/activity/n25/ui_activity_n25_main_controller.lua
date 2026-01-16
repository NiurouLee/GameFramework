---@class UIActivityN25MainController: UIController
_class("UIActivityN25MainController", UIController)
UIActivityN25MainController = UIActivityN25MainController

function UIActivityN25MainController:Constructor(ui_root_transform)
    ---@type UIN25EntryBtnBase
    self.normalEntryBtn = nil

    ---@type UIN25EntryBtnHardLevel
    self.hardEntryBtn = nil

    ---@type UIN25EntryBtnIdol
    self.idolEntryBtn = nil

    ---@type UIN25EntryBtnBloodSucker
    self.bloodSuckerEntryBtn = nil
    self.mCampaign = self:GetModule(CampaignModule)

    self.strsLeftTime = {
        "str_n25_left_time_d_h",
        "str_n25_left_time_d",
        "str_n25_left_time_h_m",
        "str_n25_left_time_h",
        "str_n25_left_time_m"
    } --活动剩余时间

    self.strsLineLeftTime = {
        "str_n25_line_left_time_d_h",
        "str_n23_line_left_time_d",
        "str_n25_line_left_time_h_m",
        "str_n25_line_left_time_h",
        "str_n25_line_left_time_m"
    } --线性关结束剩余时间
end

function UIActivityN25MainController:LoadDataOnEnter(TT, res, uiParams)
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)
    ---@type UIActivityN25Const
    self._activityConst = UIActivityN25Const:New()
    self._activityConst:LoadData(TT, res)
end

function UIActivityN25MainController:OnShow(uiParam)
    if uiParam then
        self.inScreenShot  = uiParam[1]
    end
    ---@type H3DUIBlurHelper
    self.screenShot = self:GetUIComponent("H3DUIBlurHelper", "screenShot")
    ---========================== 红点相关 ============================
    self._eventRed = self:GetGameObject("EventRed")
    self._loginRed = self:GetGameObject("LoginRed")
    self.animation = self:GetUIComponent("Animation","animation")
    self.showBtn = self:GetGameObject("ShowBtn")
    self.showBtn:SetActive(false)


    -- self._shopIconLoader = self:GetUIComponent("RawImageLoader", "ShopIcon")
    -- self._shopCountLabel = self:GetUIComponent("UILocalizationText", "ShopCount")
    self._timeLabel = self:GetUIComponent("UILocalizationText", "Time")
    self._btnPanel = self:GetGameObject("BtnPanel")
    self._topBtn = self:GetGameObject("TopBtn")
    ---@type UnityEngine.UI.RawImage
    self.shotImage = self:GetUIComponent("RawImage","ScrrenTex")
    self.shotImageGo = self:GetGameObject("ScrrenTex")
    if self.inScreenShot then
        self.shotImageGo:SetActive(true)
        self.shotImage.texture = self.inScreenShot
    else
        self.shotImageGo:SetActive(false)
    end

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
            self:SetButtonShowStatus(false)
        end
    )

    self:AttachEvent(GameEventType.OnActivityTotalAwardGot, self.ForceUpdate)
    self:AttachEvent(GameEventType.CampaignComponentStepChange, self.ForceUpdate)

    self:InitUI()
    UIActivityN25Const.ClearEnterNewStatus()
end

function UIActivityN25MainController:OnHide()
    self:DetachEvent(GameEventType.OnActivityTotalAwardGot, self.ForceUpdate)
    self:DetachEvent(GameEventType.CampaignComponentStepChange, self.ForceUpdate)
    self:CancelTimerEventNormal()
    if self.screenShot then
        self.screenShot:CleanRenderTexture()
        self.screenShot = nil
    end
end

function UIActivityN25MainController:OnUpdate(deltaTimeMS)
    self:RefreshUI()
end

function UIActivityN25MainController:CloseCoro(TT)
    self:Lock("UIActivityN21CCMainController_CloseCoro")
    self:SwitchState(UIStateType.UIMain)
    self:UnLock("UIActivityN21CCMainController_CloseCoro")
end

function UIActivityN25MainController:SetButtonShowStatus(isShow)
   -- self._btnPanel:SetActive(isShow)
   self.showBtn:SetActive(not isShow)
    if isShow then
        self.animation:Play("uianim_UIActivityN25MainController_in2")
    else
        self.animation:Play("uianim_UIActivityN25MainController_in1")
    end
end

function UIActivityN25MainController:PlayEnterAnim()
    self:StartTask(self.PlayEnterAnimCoro, self)
end

function UIActivityN25MainController:PlayEnterAnimCoro(TT)
    -- self:Lock("UIActivityN25MainController_PlayEnterAnimCoro")
    -- --todo
    -- self:UnLock("UIActivityN25MainController_PlayEnterAnimCoro")
    self:_CheckGuide()
end

function UIActivityN25MainController:InitUI()
    self:SetSpineAndBgm()
    self:RefreshRedAndNew()
    self:SetNormalLevelBtn()
    self:SetHardLevelBtn()
    self:SetExchangeBtn()
    self:SetIdolBtn()
    self:SetBloodSuckerBtn()

    self:RefreshUI()
    self:RefreshButtonStatus()
    self:PlayEnterAnim()
end

function UIActivityN25MainController:_CheckGuide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIActivityN25MainController)
end

---====================================== 刷新界面 =======================================

function UIActivityN25MainController:RefreshUI()
    self:RefreshActivityRemainTime()
end

function UIActivityN25MainController:RefreshButtonStatus()
    self:FlushRedPointStageNormal()
    self:FlushNormalStage()
end

function UIActivityN25MainController:FlushNormalStage()
    if not self.normalEntryBtn then
        Log.fatal("### FlushNormalStage, btn is nil")
        return
    end
    self.normalEntryBtn:SetLock(true)

    local c, cInfo = self._activityConst:GetLineComponent()
    if not cInfo then
        Log.fatal("### GetLineComponent nil.")
        return
    end
    local componentId = ECampaignN25ComponentID.ECAMPAIGN_N25_LINE_MISSION
    local state = self._activityConst:GetStateNormal()

    if state == UISummerOneEnterBtnState.NotOpen then --未开启；线性关随活动一起开启，不会有这个状态
    elseif state == UISummerOneEnterBtnState.Closed then --已关闭
        self:CancelTimerEventNormal()
        self.normalEntryBtn:SetLeftTime(StringTable.Get("str_activity_finished"))
    elseif state == UISummerOneEnterBtnState.Normal then --进行中
        self.normalEntryBtn:SetLock(false)
        self.normalEntryBtn:SetLeftTimeShow(false)
        local closeTime = cInfo.m_close_time
        local leftSeconds = UICommonHelper.CalcLeftSeconds(closeTime)
        self:RegisterTimeEvent(leftSeconds, componentId)
        -- local leftTimeWiget = self.normalEntryBtn:GetLeftTimeWiget()
        -- UIForge.FlushCDText(leftTimeWiget, closeTime, self.strsLineLeftTime, false)
    else
        Log.fatal("### state=", state)
    end
end

function UIActivityN25MainController:RegisterTimeEvent(seconds, componentId)
    if componentId == ECampaignN25ComponentID.ECAMPAIGN_N25_LINE_MISSION then --普通
        -- elseif componentId == ECampaignN23ComponentID.ECAMPAIGN_N23_PANGOLIN then --奇遇
        --     self:CancelTimerEventAdventure()
        self:CancelTimerEventNormal()
    else
        Log.warn("### RegisterTimeEvent componentId=", componentId)
        return
    end
    if seconds < 60 then
        seconds = 60
    end
    local ms = seconds * 1000
    local te =
        GameGlobal.Timer():AddEvent(
        ms,
        function()
            self:StartTask(
                function(TT)
                    self._activityConst:ForceUpdate(TT)
                    if componentId == ECampaignN25ComponentID.ECAMPAIGN_N25_LINE_MISSION then --普通
                        self:FlushNormalStage()
                    -- elseif componentId == ECampaignN23ComponentID.ECAMPAIGN_N23_PANGOLIN then --奇遇
                    --     self:FlushStateAdventure()
                    end
                end,
                self
            )
        end
    )
    if componentId == ECampaignN25ComponentID.ECAMPAIGN_N25_LINE_MISSION then --普通
        self.teNormal = te
    -- elseif componentId == ECampaignN23ComponentID.ECAMPAIGN_N23_PANGOLIN then --奇遇
    --     self.teAdventure = te
    end
end

function UIActivityN25MainController:FlushRedPointStageNormal()
    if self.normalEntryBtn then
        local red = self._activityConst:CheckRedNormal() or 
            self._activityConst:CheckRedTryPet() or
            self._activityConst:CheckRedShop()
        local new = self._activityConst:CheckNewNormal()
        self.normalEntryBtn:SetNewAndRed(new, red)
    end
end

function UIActivityN25MainController:RefreshActivityRemainTime()
    local endTime = self._activityConst:GetActiveEndTime()
    local nowTime = self._timeModule:GetServerTime() / 1000
    local seconds = math.floor(endTime - nowTime)
    if seconds <= 0 then
        seconds = 0
    end

    if self._activityConst:IsActivityEnd() then --活动结束
        --活动结束
        self._timeLabel:SetText(StringTable.Get("str_n25_activity_end"))
        return
    end

    local status = self._activityConst:GetStatus()
    if seconds == 0 and status == 1 then --1：活动剩余时间
        self._activityConst:SetStatus(2)
        return
    end

    -- 活动未结束时，显示：“活动剩余时间”
    -- 活动已结束但界面 ，显示：“领奖剩余时间”
    -- 遵循通用倒计时显示逻辑：”1天以上显示N天X小时；1小时以上显示N小时X分钟；1分钟以上显示N分钟；1分钟以内显示＜1分钟”
    local timeStr = UIActivityN25Const.GetTimeString(seconds)

    local timeTips = nil
    local c, cInfo = self._activityConst:GetLineComponent()
    if cInfo then
        local lineEndTime = cInfo.m_close_time
        local lineSeconds = math.floor(lineEndTime - nowTime)
        if lineSeconds > 0 then
            local timeStr = UIActivityN25Const.GetTimeString(lineSeconds)
            --timeTips = StringTable.Get("str_n25_activity_linemission_lasttime") .. timeStr
            timeTips = StringTable.Get("str_n25_activity_remain_time", timeStr)
            self._timeLabel:SetText(timeTips)
            return
        end
    end

    -- local status = self._activityConst:GetStatus()
    -- if status == 1 then
    --     timeTips = StringTable.Get("str_n25_activity_remain_time", timeStr)
    -- elseif status == 2 then
    --     timeTips = StringTable.Get("str_n25_activity_remain_get_reward_time", timeStr)
    -- end

    timeTips = StringTable.Get("str_n25_activity_remain_time", timeStr)
    self._timeLabel:SetText(timeTips)
end

function UIActivityN25MainController:CancelTimerEventNormal()
    if self.teNormal then
        GameGlobal.Timer():CancelEvent(self.teNormal)
        self.teNormal = nil
    end
end

--刷新红点和NEW标记
function UIActivityN25MainController:RefreshRedAndNew()
    self._eventRed:SetActive(self._activityConst:IsShowBattlePassRed())
    self._loginRed:SetActive(self._activityConst:CheckRedAward())
    -- self._fishRed:SetActive(self._activityConst:IsShowHomelandTaskRed())
    -- self._shopRed:SetActive(self._activityConst:IsShowShopRed())
end

function UIActivityN25MainController:ForceUpdate(callback)
    self:StartTask(self.ReLoadData, self,callback)
end

function UIActivityN25MainController:ReLoadData(TT,callback)
    self:Lock("UIActivityN25MainController_ReLoadData")
    ---@type AsyncRequestRes
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    self._activityConst:LoadData(TT, res)
    self:RefreshRedAndNew()
    self:UnLock("UIActivityN25MainController_ReLoadData")
    if callback and type(callback) == "function" then
        callback()
    end
end

---=======================================================================================

---====================================== 按钮事件 =======================================

function UIActivityN25MainController:ShowBtnOnClick()
    self:SetButtonShowStatus(true)
end

--战斗通行证
function UIActivityN25MainController:EventOnClick()
    self:ShowDialog("UIActivityBattlePassN5MainController")
end

--登录奖励
function UIActivityN25MainController:LoginOnClick()
    if self._activityConst:IsActivityEnd() then
        ToastManager.ShowToast(StringTable.Get("str_n25_activity_end"))
        return
    end

    self:ShowDialog(
        "UIActivityTotalLoginAwardController",
        false,
        ECampaignType.CAMPAIGN_TYPE_N25,
        ECampaignN25ComponentID.ECAMPAIGN_N25_CUMULATIVE_LOGIN
    )
end

function UIActivityN25MainController:SetNormalLevelBtn()
    local normalEntry = self:_SpawnObject("NormalLevelBtn", "UIN25EntryBtnBase")
    self.normalEntryBtn = normalEntry

    local isNew = self._activityConst:CheckNewNormal()
    local isRed =
        self._activityConst:CheckRedNormal() or self._activityConst:CheckRedTryPet() or
        self._activityConst:CheckRedShop()
    local state = self._activityConst:GetStateNormal()
    if state == UISummerOneEnterBtnState.Normal then
        normalEntry:SetLock(false)
    else
        normalEntry:SetLock(true)
    end
    normalEntry:SetData(
        function()
            local s = self._activityConst:GetStateNormal()
            if s == UISummerOneEnterBtnState.Normal then
                self:SwitchState(UIStateType.UIN25Line, self._activityConst)
            else
                self:_ShowBtnErrorMsg(s)
            end
        end
    )
    normalEntry:SetNewAndRed(isNew, isRed)
end

--困难关
function UIActivityN25MainController:SetHardLevelBtn()
    local hardEntry = self:_SpawnObject("HardLevelBtn", "UIN25EntryBtnHardLevel")
    self.hardEntryBtn = hardEntry
    hardEntry:SetData(
        function()
            local s = self._activityConst:GetStateHard()
            if s == UISummerOneEnterBtnState.Normal then
                N25Data.SetPrefsHard()
                self:SwitchState(UIStateType.UIActivtiyN25HardLevelController, {false, false, nil}, self._activityConst)
            elseif s == UISummerOneEnterBtnState.Locked then
                ToastManager.ShowToast(StringTable.Get("str_n25_hardlevel_locktip"))
            else
                self:_ShowBtnErrorMsg(s)
            end
        end
    )
    hardEntry:RefreshState(self._activityConst)
end

function UIActivityN25MainController:_ShowBtnErrorMsg(btnState)
    local errType = 0
    if btnState == UISummerOneEnterBtnState.NotOpen then
        errType = CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_NO_OPEN
    elseif btnState == UISummerOneEnterBtnState.Closed then
        errType = CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_FINISHED
    end
    self.mCampaign:ShowErrorToast(errType, true)
end

--商店兑换
function UIActivityN25MainController:SetExchangeBtn()
    local componentId = ECampaignN25ComponentID.ECAMPAIGN_N25_SHOP
    local obj = self:_SpawnObject("ExchangeBtn", "UIActivityCommonComponentEnter")
    local campain = self._activityConst:GetCampaign()
    local red = self._activityConst:CheckRedShop()
    obj:SetRed(
        "red",
        function()
            return campain:CheckComponentOpen(componentId) and campain:CheckComponentRed(componentId)
            -- return red
        end
    )

    ---@type ExchangeItemComponent
    local component, componentInfo = self._activityConst:GetShopComponent()
    local icon, count = component:GetCostItemIconText()
    if icon then
        obj:SetIcon("icon", icon)
    end
    -- local preZero = UIActivityHelper.GetZeroStrFrontNum(7, count)
    local fmtStr = UIActivityN20MainController.GetItemCountStr(count, "#847D7D", "#ffe671")
    obj:SetText("text", fmtStr)
    obj:SetText("txtNumbg", UIActivityN20MainController.GetItemCountStr(count, "#312E1B", "#312E1B"))
    obj:SetData(
        campain,
        function()
            ClientCampaignShop.OpenCampaignShop(
                campain._type,
                campain._id,
                function()
                    campain._campaign_module:CampaignSwitchState(
                        true,
                        UIStateType.UIActivityN25MainController,
                        UIStateType.UIMain,
                        nil,
                        campain._id,
                        componentId
                    )
                end,
                self._activityConst
            )
        end
    )
end

--偶像活动
function UIActivityN25MainController:SetIdolBtn()
    local idolEntry = self:_SpawnObject("IdolBtn", "UIN25EntryBtnIdol")
    self.idolEntryBtn = idolEntry

    idolEntry:SetData(
        function()
            local s = self._activityConst:GetStateGameIdol()
            if s == UISummerOneEnterBtnState.Normal then
                local c, cInfo = self._activityConst:GetIdolComponent()
                if  cInfo.m_b_unlock then
                    self:OpenIdol()
                else
                    --forceupdate
                    self:ForceUpdate(function ()
                        self:OpenIdol()
                    end)
                end
            else
                self:_ShowBtnErrorMsg(s)
            end
        end
    )
    idolEntry:RefreshState(self._activityConst)
end

--打开偶像活动
function UIActivityN25MainController:OpenIdol()
    N25Data.SetPrefsGameIdol()
    UIActivityHelper.PlayFirstPlot_Component(
        self._activityConst._campaign,
        ECampaignN25ComponentID.ECAMPAIGN_N25_IDOL,
        function()
            self:SwitchState(UIStateType.UIN25IdolLogin, self._activityConst)
        end
    )
end

--打开吸血鬼
function UIActivityN25MainController:SetBloodSuckerBtn()
    local bloodSuckerEntry = self:_SpawnObject("BloodSuckerBtn", "UIN25EntryBtnBloodSucker")
    self.bloodSuckerEntryBtn = bloodSuckerEntry

    bloodSuckerEntry:SetData(
        function()
            local s = self._activityConst:GetStateGameBloodSucker()
            if s == UISummerOneEnterBtnState.Normal then
                self:OpenBloodSucker()
            else
                self:_ShowBtnErrorMsg(s)
            end
        end
    )
    bloodSuckerEntry:RefreshState(self._activityConst)
end

--打开吸血鬼
function UIActivityN25MainController:OpenBloodSucker()
    UIActivityHelper.Snap(
        self.screenShot,
        self:GetUIComponent("RectTransform", "SafeArea").rect.size,
        GameGlobal.UIStateManager():GetControllerCamera(self:GetName()),
        function(cache_rt)
            N25Data.SetPrefsGameBloodSucker()
            self:SwitchState(UIStateType.UIN25VampireMain, cache_rt)
        end
    )
end

--详情
function UIActivityN25MainController:InfoBtnOnClick()
    self:ShowDialog("UIIntroLoader", "UIN25Intro")
end

function UIActivityN25MainController:_SpawnObject(widgetName, className)
    ---@type UICustomWidgetPool
    local pool = self:GetUIComponent("UISelectObjectPath", widgetName)
    local obj = pool:SpawnObject(className)
    return obj
end
---=======================================================================================

--设置Spine、Bgm
function UIActivityN25MainController:SetSpineAndBgm()
    ---@type SpineLoader
    self._spine = self:GetUIComponent("SpineLoader", "Spine")
    local spine, bgm = self._activityConst:GetSpineAndBgm()
    if spine then
        self._spine:LoadSpine(spine)
    end
    if bgm then
        AudioHelperController.PlayBGM(bgm, AudioConstValue.BGMCrossFadeTime)
    end
end
