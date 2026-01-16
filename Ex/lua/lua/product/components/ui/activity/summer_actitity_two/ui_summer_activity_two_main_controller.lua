---@class UISummerActivityTwoMainController: UIController
_class("UISummerActivityTwoMainController", UIController)
UISummerActivityTwoMainController = UISummerActivityTwoMainController

function UISummerActivityTwoMainController:LoadDataOnEnter(TT, res, uiParams)
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)
    ---@type CampaignModule
    self._campaignModule = GameGlobal.GetModule(CampaignModule)

    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_SUMMER_II,
        ECampaignSummerIIComponentID.ECAMPAIGN_SUMMERII_MISSION,
        ECampaignSummerIIComponentID.ECAMPAIGN_SUMMERII_STORY,
        ECampaignSummerIIComponentID.ECAMPAIGN_SUMMERII_CUMULATIVE_LOGIN,
        ECampaignSummerIIComponentID.ECAMPAIGN_SUMMERII_PERSON_PROGRESS_1,
        ECampaignSummerIIComponentID.ECAMPAIGN_SUMMERII_PERSON_PROGRESS_2,
        ECampaignSummerIIComponentID.ECAMPAIGN_SUMMERII_PERSON_PROGRESS_3,
        ECampaignSummerIIComponentID.ECAMPAIGN_SUMMERII_PERSON_PROGRESS_4,
        ECampaignSummerIIComponentID.ECAMPAIGN_SUMMERII_PERSON_PROGRESS_5,
        ECampaignSummerIIComponentID.ECAMPAIGN_SUMMERII_PERSON_PROGRESS_6
    )
    -- 错误处理
    if res and not res:GetSucc() then
        self._campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
    end
    if not self._campaign then
        return
    end
    ---@type CCampaignSummerII
    self._localProcess = self._campaign:GetLocalProcess()
    if not self._localProcess then
        return
    end
    ---@type SummerIIMissionComponentInfo
    self._missionComponentInfo =
        self._localProcess:GetComponentInfo(ECampaignSummerIIComponentID.ECAMPAIGN_SUMMERII_MISSION)
    -- 个人进度组件1  多个属性积分
    ---@type PersonProgressComponentInfo
    self._personProgress1CompInfo =
        self._localProcess:GetComponentInfo(ECampaignSummerIIComponentID.ECAMPAIGN_SUMMERII_PERSON_PROGRESS_1)

    --关卡组件结束时间
    local missionEndTime = 0
    if self._missionComponentInfo then
        missionEndTime = self._missionComponentInfo.m_close_time
    end
    --活动结束时间
    local sample = self._campaign:GetSample()
    if not sample then
        return
    end
    self._activeEndTime = sample.end_time
    --活动时间
    local nowTime = self._timeModule:GetServerTime() / 1000
    if nowTime > self._activeEndTime then
        Log.error("Time error!")
        return
    end
    -- 1：活动开启，2：停留期
    if nowTime >= missionEndTime then --停留期
        self._status = 2
        self._endTime = self._activeEndTime
    else --活动开启
        self._status = 1
        self._endTime = missionEndTime
    end
    --配置
    local cfg_campaign = Cfg.cfg_campaign[self._campaign._id]
    --剧情数据
    local plotIdList = cfg_campaign.FirstEnterStoryID
    self._plotId = nil
    if plotIdList and #plotIdList > 0 then
        self._plotId = plotIdList[1]
    end
    self._playPlot = self:IsFirstEnter()
    --标题数据
    self._activeTitle1 = StringTable.Get(cfg_campaign.CampaignName)
    self._activeTitle2 = StringTable.Get(cfg_campaign.CampaignSubtitle)
    --关卡数据
    if self._status == 2 then
        self._totalLevelDatas = {}
    else
        self._totalLevelDatas = self._campaignModule:GetSummerTwoLevelData(TT)
    end

    self:LoadDataOnEnter_BattlePass(TT)
end

function UISummerActivityTwoMainController:LoadDataOnEnter_BattlePass(TT)
    local res = AsyncRequestRes:New()
    res:SetSucc(true)

    ---@type UIActivityCampaign
    self._battlepassCampaign = UIActivityCampaign:New()
    self._battlepassCampaign:LoadCampaignInfo(TT, res, ECampaignType.CAMPAIGN_TYPE_BATTLEPASS)
end

function UISummerActivityTwoMainController:RequestLevelData()
    GameGlobal.TaskManager():StartTask(self.RequestLevelDataCoro, self)
end

function UISummerActivityTwoMainController:RequestLevelDataCoro(TT)
    self:Lock("UISummerActivityTwoMainController_RequestLevelDataCoro")
    if self._status == 2 then
        self._totalLevelDatas = {}
    else
        self._totalLevelDatas = self._campaignModule:GetSummerTwoLevelData(TT)
    end
    self:RefreshLevelRed()
    self:UnLock("UISummerActivityTwoMainController_RequestLevelDataCoro")
end

function UISummerActivityTwoMainController:OnShow(uiParams)
    local showBtn = self:GetGameObject("ShowBtn")
    showBtn:SetActive(false)
    --夏活2的new，有没有进过主界面
    local open_id = GameGlobal.GameLogic():GetOpenId()
    local save_key = "summer_two_new_" .. open_id
    if not LocalDB.HasKey(save_key) then
        LocalDB.SetInt(save_key, 0)
    end
    ---@type UISelectObjectPath
    local btns = self:GetUIComponent("UISelectObjectPath", "TopBtn")
    ---@type UICommonTopButton
    self._backBtn = btns:SpawnObject("UICommonTopButton")
    self._backBtn:SetData(
        function()
            GameGlobal.TaskManager():StartTask(self.CloseCoro, self)
        end,
        nil,
        nil,
        false,
        function()
            self:HideBtnOnClick()
        end
    )

    self._plotRed = self:GetGameObject("plotRed")
    self._loginRed = self:GetGameObject("loginRed")
    self._battlepassRed = self:GetGameObject("_battlepassRed")

    self._title1Label = self:GetUIComponent("UILocalizationText", "Title1")
    self._title1ShadowLabel = self:GetUIComponent("UILocalizationText", "Title1Shadow")
    self._title2Label = self:GetUIComponent("UILocalizationText", "Title2")
    self._title2ShadowLabel = self:GetUIComponent("UILocalizationText", "Title2Shadow")
    self._timeLabel = self:GetUIComponent("UILocalizationText", "Time")
    self._scoreRedGo = self:GetGameObject("ScoreRed")
    self._anim = self:GetUIComponent("Animation", "Anim")

    if self._playPlot and self._plotId and self._plotId > 0 then
        self:Lock("summeriiplaystory")
        GameGlobal.Timer():AddEvent(
            1333,
            function()
                self:UnLock("summeriiplaystory")
                self:ShowDialog(
                    "UIStoryController",
                    self._plotId,
                    function()
                        GameGlobal.EventDispatcher():Dispatch(
                            GameEventType.GuideOpenUI,
                            GuideOpenUI.UISummerActivityTwoMainController
                        )
                    end
                )
            end
        )
    end
    self:SetFirstEnter()
    self._title1Label.text = self._activeTitle1
    self._title1ShadowLabel.text = self._activeTitle1
    self._title2Label.text = self._activeTitle2
    self._title2ShadowLabel.text = self._activeTitle2
    self:InitRemainTime()
    self:AttachEvent(GameEventType.SummerTwoRewardRefresh, self.RefreshRewardRedStatus)
    self:AttachEvent(GameEventType.OnSummerActivityTwoLevelUIClose, self.RequestLevelData)

    self:RefreshRewardRedStatus()
    self:RefreshLevelRed()

    self:AttachEvent(GameEventType.SummerTwoLoginRed, self.LoginRed)
    self:AttachEvent(GameEventType.SummerTwoPlotRed, self.PlotRed)
    self:AttachEvent(GameEventType.CampaignComponentStepChange, self.BattlePassRed)

    self:SetRed()

    self:InitButtonClickAnim("BattleCardBtn", "BattleCardBtnClicked")
    self:InitButtonClickAnim("BtnScoreBtn", "ScoreBtnClicked")
    self:InitButtonClickAnim("LoginRewardBtn", "LoginRewardBtnClicked")
    self:InitButtonClickAnim("PlotReviewBtn", "PlotReviewBtnClicked")
    self:InitButtonClickAnim("PlotBtn", "PlotBtnClicked")
    self:InitButtonClickAnim("ShuiBtn", "battleBtnClick")

    ---@type H3DUIBlurHelper
    self._shot = self:GetUIComponent("H3DUIBlurHelper", "screenShot")
end

function UISummerActivityTwoMainController:CloseCoro(TT)
    self:Lock("UISummerActivityTwoMainController_CloseCoro")
    self._anim:Play("uieff_Summer2_Main_Out")
    YIELD(TT, 300)
    self:SwitchState(UIStateType.UIMain)
    self:UnLock("UISummerActivityTwoMainController_CloseCoro")
end

function UISummerActivityTwoMainController:Dispose()
    if self._shot then
        self._shot:CleanRenderTexture()
        self._shot = nil
    end
    UISummerActivityTwoMainController.super:Dispose()
end

function UISummerActivityTwoMainController:Shot()
    self._shot.OwnerCamera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
    local shotRect = self:GetUIComponent("RectTransform", "screenShot")
    self._shot.width = shotRect.rect.width
    self._shot.height = shotRect.rect.height
    self._shot.blurTimes = 0
    self._shot:CleanRenderTexture()
    self._rt = self._shot:RefreshBlurTexture()
end

--红点
function UISummerActivityTwoMainController:SetRed()
    self:LoginRed()
    self:PlotRed()
    self:BattlePassRed()
end

function UISummerActivityTwoMainController:LoginRed()
    local red =
        self:_CheckRedPoint(self._redLoginRewardBtn, ECampaignSummerIIComponentID.ECAMPAIGN_SUMMERII_CUMULATIVE_LOGIN)
    self._loginRed:SetActive(red)
end

function UISummerActivityTwoMainController:_CheckRedPoint(obj, ...)
    local bShow = self._campaign:CheckComponentRed(...)
    return bShow
end

function UISummerActivityTwoMainController:PlotRed()
    -- local _story_component = self._campaign:GetLocalProcess()._storyComponent
    -- local _story_componentinfo = self._campaign:GetLocalProcess()._storyComponentInfo
    -- local _componentID = _story_component:GetComponetCfgId(self._campaign._id, _story_componentinfo.m_component_id)
    -- local cfg_component_story = Cfg.cfg_component_story[_componentID]
    -- if not cfg_component_story then
    --     Log.error("###[UISummerActivityTwoMainController] cfg_component_story is nil ! id --> ", _componentID)
    -- end
    -- local storyIDList = cfg_component_story.StoryID
    -- local red = false
    -- for i = 1, #storyIDList do
    --     local storyid = storyIDList[i]
    --     local cfg_campaign_story = Cfg.cfg_campaign_story[storyid]
    --     if not cfg_campaign_story then
    --         Log.error("###[UISummerActivityTwoMainController] cfg_campaign_story is nil ! id --> ", storyid)
    --     end
    --     local unlock = false
    --     if cfg_campaign_story.PreStoryID then
    --         --检查剧情
    --         local recv_list = _story_component:GetAlreadyReceivedStoryIdList()
    --         if table.icontains(recv_list, cfg_campaign_story.PreStoryID) then
    --             unlock = true
    --         end
    --     else
    --         unlock = true
    --     end
    --     if unlock then
    --         local missionUnLock = self:CheckMissionCondition(storyid)
    --         if missionUnLock then
    --             local recv_list = _story_component:GetAlreadyReceivedStoryIdList()
    --             local got = table.icontains(recv_list, storyid)
    --             red = not got
    --         end
    --     end
    --     if red then
    --         break
    --     end
    -- end
    local red = self:_CheckRedPoint(self._redLoginRewardBtn, ECampaignSummerIIComponentID.ECAMPAIGN_SUMMERII_STORY)
    self._plotRed:SetActive(red)
end

function UISummerActivityTwoMainController:BattlePassRed()
    local bShow = UIActivityHelper.CheckCampaignSampleRedPoint(self._battlepassCampaign)
    self._battlepassRed:SetActive(bShow)
end

function UISummerActivityTwoMainController:CheckMissionCondition(storyid)
    local unlock = true
    local cfg_campaign_story = Cfg.cfg_campaign_story[storyid]
    if not cfg_campaign_story then
        Log.error("###[UISummerActivityTwoMainController] cfg_campaign_story is nil ! id --> ", storyid)
    end
    if cfg_campaign_story and cfg_campaign_story.ComponentID then
        --检查关卡
        local com = self._campaignModule:GetComponentByComponentId(cfg_campaign_story.ComponentID)
        if com then
            for i = 1, #cfg_campaign_story.NeedMissionList do
                local missionid = cfg_campaign_story.NeedMissionList[i]
                local pass = com:IsPassCamMissionID(missionid)
                if not pass then
                    unlock = false
                    break
                end
            end
        else
            unlock = false
        end
    end
    return unlock
end

function UISummerActivityTwoMainController:InitButtonClickAnim(btnName, clickedGoName)
    local btnGo = self:GetGameObject(btnName)
    local clickedGo = self:GetGameObject(clickedGoName)
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(btnGo),
        UIEvent.Press,
        function(go)
            clickedGo:SetActive(true)
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(btnGo),
        UIEvent.Release,
        function(go)
            clickedGo:SetActive(false)
        end
    )
end

function UISummerActivityTwoMainController:OnHide()
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
    self:DetachEvent(GameEventType.SummerTwoRewardRefresh, self.RefreshRewardRedStatus)
    self:DetachEvent(GameEventType.OnSummerActivityTwoLevelUIClose, self.RequestLevelData)
end

function UISummerActivityTwoMainController:RefreshRewardRedStatus()
    local status1 = self:HasCanGetReward(self._personProgress1CompInfo)
    if status1 then
        self._scoreRedGo:SetActive(true)
    else
        self._scoreRedGo:SetActive(false)
    end
end

---@param progressComponentInfo PersonProgressComponentInfo
function UISummerActivityTwoMainController:HasCanGetReward(progressComponentInfo)
    local _scoreDatas = UISummerActivityTwoScoreData:New(progressComponentInfo)
    local rewards_red = _scoreDatas:HasCanGetReward()
    return rewards_red
end

function UISummerActivityTwoMainController:InitRemainTime()
    self:RefreshRemainTime()
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
    self._timerHandler =
        GameGlobal.Timer():AddEventTimes(
        1000,
        TimerTriggerCount.Infinite,
        function()
            self:RefreshRemainTime()
        end
    )
end

function UISummerActivityTwoMainController:RefreshRemainTime()
    local nowTime = self._timeModule:GetServerTime() / 1000
    local seconds = math.floor(self._endTime - nowTime)
    if seconds < 0 then
        seconds = 0
    end
    if seconds == 0 and self._status == 2 then --2：停留期
        --活动结束
        self:SwitchState(UIStateType.UIMain)
        return
    end
    if seconds == 0 and self._status == 1 then --1：活动开启
        self._endTime = self._activeEndTime
        self._status = 2
        return
    end

    local timeStr = ""
    -- 剩余时间超过24小时，显示N天XX小时。
    -- 剩余时间超过1分钟，显示N小时XX分钟。
    -- 剩余时间小于1分数，显示＜1分钟。
    local day = math.floor(seconds / 3600 / 24)
    if day > 0 then
        seconds = seconds - day * 3600 * 24
        local hour = math.floor(seconds / 3600)
        timeStr = StringTable.Get("str_summer_activity_two_day", day)
        if hour > 0 then
            timeStr = timeStr .. StringTable.Get("str_summer_activity_two_hour", hour)
        end
    else
        if seconds >= 60 then
            local hour = math.floor(seconds / 3600)
            seconds = seconds - hour * 3600
            if hour > 0 then
                timeStr = StringTable.Get("str_summer_activity_two_hour", hour)
            end
            local minus = math.floor(seconds / 60)
            if minus then
                timeStr = timeStr .. StringTable.Get("str_summer_activity_two_minus", minus)
            end
        else
            timeStr = StringTable.Get("str_summer_activity_two_less_minus")
        end
    end

    local timeTips = ""
    if self._status == 1 then
        timeTips = StringTable.Get("str_summer_activity_two_time_tips1", timeStr)
    elseif self._status == 2 then
        timeTips = StringTable.Get("str_summer_activity_two_time_tips2", timeStr)
    end

    self._timeLabel.text = timeTips
end

function UISummerActivityTwoMainController:IsFirstEnter()
    local key = self:GetFirstEnterKey()
    if not UnityEngine.PlayerPrefs.HasKey(key) then
        return true
    end
    local value = UnityEngine.PlayerPrefs.GetInt(key)
    return value == 0
end

function UISummerActivityTwoMainController:SetFirstEnter()
    local key = self:GetFirstEnterKey()
    local value = UnityEngine.PlayerPrefs.SetInt(key, 1)
end

function UISummerActivityTwoMainController:GetFirstEnterKey()
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = pstId .. "SummerActivityTwoFirstEnter"
    return key
end

function UISummerActivityTwoMainController:IsActivityOpen()
    return self._status == 1
end

--战斗通行证
function UISummerActivityTwoMainController:BattleCardBtnOnClick()
    UIActivityBattlePassHelper.ShowBattlePassDialog(self._battlepassCampaign)
end

--登陆奖励
function UISummerActivityTwoMainController:LoginRewardBtnOnClick()
    self:ShowDialog(
        "UIActivityTotalLoginAwardController",
        false,
        ECampaignType.CAMPAIGN_TYPE_SUMMER_II,
        ECampaignSummerIIComponentID.ECAMPAIGN_SUMMERII_CUMULATIVE_LOGIN
    )
end

--梦境后谈
function UISummerActivityTwoMainController:PlotBtnOnClick()
    self:ShowDialog(
        "UISummerActivityTwoPlotDetailController",
        ECampaignType.CAMPAIGN_TYPE_SUMMER_II,
        ECampaignSummerIIComponentID.ECAMPAIGN_SUMMERII_STORY
    )
end

--梦境积分
function UISummerActivityTwoMainController:BtnScoreBtnOnClick()
    self:ShowDialog("UISummerActivityTwoScoreController")
end

--剧情回顾
function UISummerActivityTwoMainController:PlotReviewBtnOnClick()
    local canReviewStages = {}
    local cfgs = Cfg.cfg_component_summer_ii_plot_review {}
    if cfgs then
        for i = 1, #cfgs do
            local cfg = cfgs[i]
            ---@type DiscoveryStage
            local curStage = DiscoveryStage:New()
            curStage.id = cfg.ID
            curStage.longDesc = StringTable.Get(cfg.Des)
            curStage.name = StringTable.Get(cfg.Name)
            curStage.stageIdx = StringTable.Get(cfg.StageIndexTitle)
            curStage.fullname = StringTable.Get(cfg.FullName)

            local storyList = DiscoveryStoryList:New()
            local slist = {}
            storyList.stageId = cfg.ID
            local storyListCfg = cfg.StoryList
            for i = 1, #storyListCfg do
                local story = DiscoveryStory:New()
                story:Init(storyListCfg[i][1], storyListCfg[i][2])
                table.insert(slist, story)
            end
            storyList.list = slist
            curStage.story = storyList
            curStage.state = DiscoveryStageState.Nomal

            table.insert(canReviewStages, curStage)
        end
    end
    local tempStage = canReviewStages[1]
    --打开剧情界面

    self:ShowDialog(
        "UIPlot",
        tempStage,
        canReviewStages,
        false,
        true,
        StringTable.Get("str_summer_activity_two_plot_review_stage_title"),
        UISummerActivityTwoConst.PlotReviewBg
    )
end

--水属性关卡
function UISummerActivityTwoMainController:ShuiBtnOnClick()
    if not self:IsActivityOpen() then
        self:RefreshLevelRed()
        ToastManager.ShowToast(StringTable.Get("str_summer_activity_two_level_entrance_closed"))
        return
    end
    self:Shot()
    self:ShowDialog("UISummerActivityTwoLevelController", {false, self._rt})
end

--说明
function UISummerActivityTwoMainController:intrBtnOnClick(go)
    --说明界面
    self:ShowDialog("UIActivityIntroController", "UISummerTwo")
end

function UISummerActivityTwoMainController:RefreshLevelRed()
    local levelRed = self:GetGameObject("LevelRed")
    if not self:IsActivityOpen() then
        levelRed:SetActive(false)
        return
    end
    levelRed:SetActive(self._totalLevelDatas:GetLevelRedStatus())
end

function UISummerActivityTwoMainController:HideBtnOnClick()
    local topBtn = self:GetGameObject("TopBtn")
    local showBtn = self:GetGameObject("ShowBtn")
    topBtn:SetActive(false)
    showBtn:SetActive(true)
    local anim = self:GetUIComponent("Animation", "HideAnim")
    local state = anim:get_Item("uieff_UISummerActivityTwoMainController_enjoy")
    state.speed = 1
    anim:Play("uieff_UISummerActivityTwoMainController_enjoy")
end

function UISummerActivityTwoMainController:ShowBtnOnClick()
    local topBtn = self:GetGameObject("TopBtn")
    local showBtn = self:GetGameObject("ShowBtn")
    topBtn:SetActive(true)
    showBtn:SetActive(false)
    local anim = self:GetUIComponent("Animation", "HideAnim")
    local state = anim:get_Item("uieff_UISummerActivityTwoMainController_enjoy")
    state.time = state.clip.length
    state.speed = -1
    anim:Play("uieff_UISummerActivityTwoMainController_enjoy")
end
