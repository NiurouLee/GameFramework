--- @class UIN6MainController_Review:UIController
_class("UIN6MainController_Review", UIController)
UIN6MainController_Review = UIN6MainController_Review

function UIN6MainController_Review:LoadDataOnEnter(TT, res, uiParams)
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
        ECampaignType.CAMPAIGN_TYPE_REVIEW_N6,
        ECampaignReviewN6ComponentID.BUILD,
        ECampaignReviewN6ComponentID.QUEST,
        ECampaignReviewN6ComponentID.LINE_MISSION,
        ECampaignReviewN6ComponentID.STORY,
        ECampaignReviewN6ComponentID.POINT_PROGRESS
    )

    -- 错误处理
    if res and not res:GetSucc() then
        self._campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
        return
    end
    if not self._campaign then
        return
    end
    ---@type CCampaingN6
    self._localProcess = self._campaign:GetLocalProcess()
    if not self._localProcess then
        return
    end

    -- 错误处理
    if res and not res:GetSucc() then
        self._campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
    end
    --获取组件
    --重建组件
    ---@type CampaignBuildComponent
    self._buildComponent = self._localProcess:GetComponent(ECampaignReviewN6ComponentID.BUILD)
    ---@type BuildComponentInfo
    self._buildComponentInfo = self._localProcess:GetComponentInfo(ECampaignReviewN6ComponentID.BUILD)
    ---任务组件（重建奖励）
    ---@type CampaignQuestComponent
    self._questComponent = self._localProcess:GetComponent(ECampaignReviewN6ComponentID.QUEST)
    ---@type CamQuestComponentInfo
    self._questComponentInfo = self._localProcess:GetComponentInfo(ECampaignReviewN6ComponentID.QUEST)

    --- 线性关卡组件
    ---@type LineMissionComponent
    self._lineMissionComponet = self._localProcess:GetComponent(ECampaignReviewN6ComponentID.LINE_MISSION)
    ---@type LineMissionComponentInfo
    self._lineMissionCompInfo = self._localProcess:GetComponentInfo(ECampaignReviewN6ComponentID.LINE_MISSION)
    ---剧情组件
    ---@type StoryComponent
    self._storyComponent = self._localProcess:GetComponent(ECampaignReviewN6ComponentID.STORY)
    ---@type CStoryComponentInfo
    self._storyComponentInfo = self._localProcess:GetComponentInfo(ECampaignReviewN6ComponentID.STORY)

    --配置
    local cfg_campaign = Cfg.cfg_campaign[self._campaign._id]
    --标题数据
    self._name = StringTable.Get(cfg_campaign.CampaignName)
    self._subName = StringTable.Get(cfg_campaign.CampaignSubtitle)
    --关卡组件结束时间
    local missionEndTime = 0
    if self._lineMissionCompInfo then
        missionEndTime = self._lineMissionCompInfo.m_close_time
    end

    --建筑数据
    local componentId =
        self._buildComponent:GetComponentCfgId(self._campaign._id, self._buildComponentInfo.m_component_id)
    ---@type UIActivityN6ReviewBuildingDatas
    self._buildingDatas = UIActivityN6ReviewBuildingDatas:New(componentId, self._localProcess)
    --剧情
    self._plotId = nil
    local plotIdList = cfg_campaign.FirstEnterStoryID
    if plotIdList and #plotIdList > 0 then
        self._plotId = plotIdList[1]
    end
    self._playPlot = self:IsFirstEnter()
    --刷新数据
    self:RefreshData()
end

function UIN6MainController_Review:IsFirstEnter()
    local key = self:GetFirstEnterKey()
    if not UnityEngine.PlayerPrefs.HasKey(key) then
        return true
    end
    local value = UnityEngine.PlayerPrefs.GetInt(key)
    return value == 0
end

function UIN6MainController_Review:SetFirstEnter()
    local key = self:GetFirstEnterKey()
    local value = UnityEngine.PlayerPrefs.SetInt(key, 1)
end

function UIN6MainController_Review:GetFirstEnterKey()
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = pstId .. "N6MainController_Review"
    return key
end

function UIN6MainController_Review:RefreshData()
    --白夜币数量
    ---@type ItemModule
    local itemModule = GameGlobal.GetModule(ItemModule)
    self._itemCount = itemModule:GetItemCount(UIActivityNPlusSixConst.GetCoinItemId())
    self._showFinalPlot = false
    if self._storyComponent then
        self._showFinalPlot = self._storyComponent:ComponentIsOpen()
    end
end

--是否显示最终剧情红点
function UIN6MainController_Review:IsShowFinalPlotRed()
    if not self._storyComponentInfo then
        return false
    end
    if not self._storyComponent:ComponentIsOpen() then
        return false
    end

    local list = self._storyComponentInfo.m_recieved_reward_story
    if not list then
        return true
    end

    if table.count(list) <= 0 then
        return true
    end

    return false
end

--是否显示建造红点
function UIN6MainController_Review:IsShowBuildingRed()
    if not self:IsBuildingComponentEnable() then
        return false
    end

    --当重建界面有可领取的重建奖励时，重建奖励上显示红点，重建玩法入口显示红点。领完奖励后，重建奖励以及重建玩法入口上的红点消失。
    if self._questComponent:HaveRedPoint() then
        return true
    end

    --当重建界面内存在随机事件时，重建玩法入口上显示红点，【事件】按钮上显示红点。当所有随机事件清空后，事件按钮和重建玩法入口上的红点消失。
    if self._buildComponent:HaveEventRedPoint() then
        return true
    end

    --当玩家拥有的代币数量足够进行当前设施重建时，重建玩法入口上显示红点。代币数量不足进行当前设施重建时，重建玩法入口上的红点消失。
    ---@type ItemModule
    local itemModule = GameGlobal.GetModule(ItemModule)
    if self._buildingDatas:HaveCanBuilding(itemModule:GetItemCount(UIActivityNPlusSixConst.GetCoinItemId())) then
        return true
    end

    --当重建玩法解锁时，重建玩法入口上显示红点，点击进入重建界面后红点消失。
    if self._buildingDatas:IsFirstEnterBuilding() then
        return true
    end

    return false
end

-- function UIN6MainController_Review

--线性关红点
function UIN6MainController_Review:IsShowLevelRed()
    return self._campaign:CheckComponentRed(ECampaignReviewN6ComponentID.LINE_MISSION)
end

--建造组件是否开启
function UIN6MainController_Review:IsBuildingComponentEnable()
    if not self._buildComponent then
        return false
    end
    return self._buildComponent:ComponentIsOpen()
end

--任务组件是否开启
function UIN6MainController_Review:IsQuestComponentEnable()
    if not self._questComponent then
        return false
    end
    return self._questComponent:ComponentIsOpen()
end

--线性关卡组件是否开启
function UIN6MainController_Review:IsMissionComponentEnable()
    if not self._lineMissionComponet then
        return false
    end
    return self._lineMissionComponet:ComponentIsOpen()
end

--剧情组件是否开启
function UIN6MainController_Review:IsStoryComponentEnable()
    if not self._storyComponent then
        return false
    end
    return self._storyComponent:ComponentIsOpen()
end

function UIN6MainController_Review:OnShow(uiParams)
    self._levelUnOpen = self:GetGameObject("LevelUnOpen")
    self._loginUnOpen = self:GetGameObject("LoginUnOpen")
    self._atlas = self:GetAsset("NPlusSix.spriteatlas", LoadType.SpriteAtlas)
    self._topBgLoader = self:GetUIComponent("RawImageLoader", "TopBg")
    self._bottomBgLoader = self:GetUIComponent("RawImageLoader", "BottomBg")
    self._levelBtnBg = self:GetUIComponent("Image", "LevelBtnBg")
    self._buildingBtnBg = self:GetUIComponent("Image", "BuildingBtnBg")
    self._eventBtnBg = self:GetUIComponent("Image", "EventBtnBg")
    self._bgLoader = self:GetUIComponent("RawImageLoader", "BG")
    ---@type SpineLoader
    self._spine = self:GetUIComponent("SpineLoader", "spine")
    self._showBtn = self:GetGameObject("ShowBtn")
    self._showBtn:SetActive(false)
    self._scoreLabel = self:GetUIComponent("UILocalizationText", "Score")
    self._finalPlotBtn = self:GetGameObject("FinalPlotBtn")
    self._finalPlotRed = self:GetGameObject("FinalPlotRed")
    self._buildingRed = self:GetGameObject("BuildingRed")
    self._eventRed = self:GetGameObject("EventRed")
    self._levelRed = self:GetGameObject("LevelRed")
    self._unLockTips = self:GetGameObject("UnLockTips")
    self._timeUnLockBtn = self:GetGameObject("TimeUnLockBtn")
    self._buildingUnLock = self:GetGameObject("BuildingUnLock")
    local btns = self:GetUIComponent("UISelectObjectPath", "TopBtn")
    self._buildingLockTips = self:GetGameObject("BuildingLockTips")
    self._buildingLockTipsLabel = self:GetUIComponent("UILocalizationText", "BuildingLockTipsLabel")
    self._desLabel = self:GetUIComponent("UILocalizationText", "Des")
    -- self._awardProgress = self:GetUIComponent("UISelectObjectPath", "UIN6ReviewProgress")
    -- self._progress = self._awardProgress:SpawnObject("UIN5ReviewProgress")

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
    self._finalPlotRed:SetActive(false)
    self._buildingRed:SetActive(false)
    self._eventRed:SetActive(false)
    self:AttachEvent(GameEventType.NPlusSixMainRefresh, self.HandleRefreshEvent)

    self:AttachEvent(GameEventType.CampaignComponentStepChange, self.OnComponentStepChange)
    self._iconLoader = self:GetUIComponent("RawImageLoader", "Icon")
    local iconName = UIActivityNPlusSixConst.GetItemIconName()
    if iconName then
        self._iconLoader:LoadImage(iconName)
    end

    local rt = uiParams[1]
    local dragonFly = self:GetGameObject("uieff_n6_in")
    if rt then
        dragonFly:SetActive(true)
        local bg = self:GetUIComponent("RawImage", "eff_smoke_In")
        local mat = bg.material
        mat:SetTexture("_MainTex", rt)
    else
        dragonFly:SetActive(false)
    end

    if self._playPlot and self._plotId and self._plotId > 0 then
        self:Lock("nplussixplaystory")
        GameGlobal.Timer():AddEvent(
            1033,
            function()
                self:UnLock("nplussixplaystory")
                self:ShowDialog(
                    "UIStoryController",
                    self._plotId,
                    function()
                        self:_TriggerGuide(false)
                    end
                )
            end
        )
    else
        self:_TriggerGuide(true)
    end
    self:SetFirstEnter()
    self:RefreshUI()
    self:RefreshButtonStatus()
end

function UIN6MainController_Review:RefreshButtonStatus()
    self._levelUnOpen:SetActive(not self:IsMissionComponentEnable())
end

function UIN6MainController_Review:_TriggerGuide(needYield)
    self:StartTask(
        function(TT)
            self:Lock("UIN6MainController_Review")
            if needYield then
                YIELD(TT, 533)
            end
            GameGlobal.EventDispatcher():Dispatch(
                GameEventType.GuideOpenUI,
                GuideOpenUI.UIN6MainController_Review
            )
            self:_CheckBuildingGuide()
            self:UnLock("UIN6MainController_Review")
        end,
        self
    )
end

function UIN6MainController_Review:_CheckBuildingGuide()
    if self._lineMissionCompInfo.m_cur_mission > 0 then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.GuideOpenUI,
            GuideOpenUI.UIN6MainController_ReviewBuilding
        )
    end
end

function UIN6MainController_Review:OnHide()
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
    self:DetachEvent(GameEventType.NPlusSixMainRefresh, self.HandleRefreshEvent)
end

function UIN6MainController_Review:OnUpdate(deltaTimeMS)
    if self:IsBuildingComponentEnable() then
        self._unLockTips:SetActive(false)
        self._timeUnLockBtn:SetActive(false)
        self._buildingUnLock:SetActive(false)
    else
        self._unLockTips:SetActive(true)
        self._timeUnLockBtn:SetActive(true)
        self._buildingUnLock:SetActive(true)
    end
    self:RefreshButtonStatus()
end

function UIN6MainController_Review:CloseCoro(TT)
    self:Lock("UIN6MainController_Review_CloseCoro")
    self:SwitchState(UIStateType.UIActivityReview)
    self:UnLock("UIN6MainController_Review_CloseCoro")
end

function UIN6MainController_Review:HandleRefreshEvent()
    GameGlobal.TaskManager():StartTask(self.RequestComponentData, self)
end

function UIN6MainController_Review:RequestComponentData(TT)
    self:Lock("UIN6MainController_Review_RequestComponentData")
    ---@type CampaignModule
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    -- 获取活动 以及本窗口需要的组件
    local res = AsyncRequestRes:New()
    res.m_result = 0
    res.m_call_err = CallResultType.Normal

    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_REVIEW_N6,
        ECampaignReviewN6ComponentID.BUILD,
        ECampaignN6ComponentID.LINE_MISSION,
        ECampaignN6ComponentID.STORY
    )

    --请求完了再获取就一定是最新的了
    self._campaign:ReLoadCampaignInfo_Force(TT, res)

    -- 错误处理
    if res and not res:GetSucc() then
        campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
    end
    self:RefreshData()
    self:RefreshUI()
    self:UnLock("UIN6MainController_Review_RequestComponentData")
end

function UIN6MainController_Review:RefreshUI()
    self._scoreLabel.text = self:GetItemCountStr(self._itemCount)
    self._finalPlotBtn:SetActive(self._showFinalPlot)
    if self._showFinalPlot then
        self._desLabel:SetText(
            HelperProxy:GetInstance():ReplacePlayerName(StringTable.Get("str_n_plus_six_activity_des2"))
        )
    else
        self._desLabel:SetText(
            HelperProxy:GetInstance():ReplacePlayerName(StringTable.Get("str_n_plus_six_activity_des1"))
        )
    end

    self:RefreshImageStyle()
    self:RefreshRed()
end

function UIN6MainController_Review:RefreshImageStyle()
    if self._buildingDatas:IsAllBuildingComplete() then
        self._bgLoader:LoadImage("n6_home_bg_complete")
        self._spine:LoadSpine("event_n6_2_spine_idle")
        self._topBgLoader:LoadImage("n6_home_bg1_kv2")
        self._bottomBgLoader:LoadImage("n6_home_bg2_kv2")
        self._levelBtnBg.sprite = self._atlas:GetSprite("n6_home_btn_battle1")
        self._buildingBtnBg.sprite = self._atlas:GetSprite("n6_home_btn_rebuild1")
        self._eventBtnBg.sprite = self._atlas:GetSprite("n6_home_btn_book1")
    else
        self._bgLoader:LoadImage("n6_home_bg")
        self._spine:LoadSpine("event_n6_1_spine_idle")
        self._topBgLoader:LoadImage("n6_home_bg1")
        self._bottomBgLoader:LoadImage("n6_home_bg2")
        self._levelBtnBg.sprite = self._atlas:GetSprite("n6_home_btn_battle")
        self._buildingBtnBg.sprite = self._atlas:GetSprite("n6_home_btn_rebuild")
        self._eventBtnBg.sprite = self._atlas:GetSprite("n6_home_btn_book")
    end
end

function UIN6MainController_Review:GetItemCountStr(count)
    local dight = 0
    local tmpCount = count
    while tmpCount > 0 do
        tmpCount = math.floor(tmpCount / 10)
        dight = dight + 1
    end
    local pre = ""
    for i = 1, 7 - dight do
        pre = pre .. "0"
    end
    if count > 0 then
        return string.format("<color=#5e5e5e>%s</color><color=#f2c641>%s</color>", pre, count)
    else
        return string.format("<color=#5e5e5e>%s</color>", pre)
    end
end

function UIN6MainController_Review:RefreshRed()
    self._finalPlotRed:SetActive(self:IsShowFinalPlotRed())
    self._buildingRed:SetActive(self:IsShowBuildingRed())
    self._levelRed:SetActive(self:IsShowLevelRed())
end

function UIN6MainController_Review:PlayButtonAnim(btnName, animName, callback)
    GameGlobal.TaskManager():StartTask(
        function(TT)
            self:Lock("PlayButtonAnim" .. btnName)
            local animation = self:GetUIComponent("Animation", btnName)
            animation:Play(animName)
            YIELD(TT, 264)
            if callback then
                callback()
            end
            self:UnLock("PlayButtonAnim" .. btnName)
        end,
        self
    )
end

--战斗关卡
function UIN6MainController_Review:LevelBtnOnClick()
    if not self:IsMissionComponentEnable() then
        ToastManager.ShowToast(StringTable.Get("str_n_plus_six_mission_component_close_tips"))
        return
    end

    self:PlayButtonAnim(
        "LevelBtn",
        "uieff_N6_Main_Btn",
        function()
            self._campaignModule:CampaignSwitchState(
                true,
                UIStateType.UIActivityN6LineMissionReview,
                UIStateType.UIMain,
                nil,
                self._campaign._id
            )
        end
    )
end

--建造空谷
function UIN6MainController_Review:BuildingBtnOnClick()
    if not self:IsBuildingComponentEnable() then
        return
    end

    self:PlayButtonAnim(
        "BuildingBtn",
        "uieff_N6_Main_Btn",
        function()
            self:ShowDialog("UIActivityN6ReviewBuildingMainController", self._buildingDatas)
        end
    )
end

--最终剧情
function UIN6MainController_Review:FinalPlotBtnOnClick()
    if not self:IsStoryComponentEnable() then
        ToastManager.ShowToast(StringTable.Get("str_n_plus_six_final_plot_component_close_tips"))
        return
    end
    local componentId =
        self._storyComponent:GetComponentCfgId(self._campaign._id, self._storyComponentInfo.m_component_id)
    local cfg_component_story = Cfg.cfg_component_story[componentId]
    if not cfg_component_story then
        Log.error("cfg_component_story is nil")
        return
    end
    local storyIdList = cfg_component_story.StoryID
    if storyIdList == nil or table.count(storyIdList) <= 0 then
        Log.error("story list is nil")
    end

    self:ShowDialog(
        "UIStoryController",
        storyIdList[1],
        function()
            GameGlobal.TaskManager():StartTask(self.CompleteFinalPlot, self, storyIdList[1])
        end
    )
end

function UIN6MainController_Review:CompleteFinalPlot(TT, storyId)
    self:Lock("UIN6MainController_Review_CompleteFinalPlot")
    local request = AsyncRequestRes:New()
    local rewards = self._storyComponent:HandleStoryTake(TT, request, storyId)
    if request:GetSucc() then
        if rewards and table.count(rewards) > 0 then
            self:ShowRewards(rewards)
        end
    else
        Log.error("CompleteFinalPlot")
    end
    self._finalPlotRed:SetActive(self:IsShowFinalPlotRed())
    self:UnLock("UIN6MainController_Review_CompleteFinalPlot")
end

function UIN6MainController_Review:ShowRewards(rewards)
    local petIdList = {}
    ---@type PetModule
    local petModule = GameGlobal.GetModule(PetModule)
    for _, reward in pairs(rewards) do
        if petModule:IsPetID(reward.assetid) then
            table.insert(petIdList, reward)
        end
    end
    if table.count(petIdList) > 0 then
        self:ShowDialog(
            "UIPetObtain",
            petIdList,
            function()
                GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
                self:ShowDialog("UIGetItemController", rewards)
            end
        )
        return
    end
    self:ShowDialog("UIGetItemController", rewards)
end

function UIN6MainController_Review:TimeUnLockBtnOnClick()
    self:ShowBuildingLockTips()
end

function UIN6MainController_Review:BuildingLockTipsOnClick()
    self._buildingLockTips:SetActive(false)
end

function UIN6MainController_Review:GetBuildingUnLockTimeStr()
    local seconds = 0
    if self._buildComponentInfo then
        local openTime = self._buildComponentInfo.m_unlock_time
        local nowTime = self._timeModule:GetServerTime() / 1000
        seconds = openTime - nowTime
        if seconds < 0 then
            seconds = 0
        end
    end
    -- 同时在入口上增加一个时钟，点击则显示tips“x天后自动解锁”
    -- 时间显示规则：
    -- 超过24小时显示x天
    -- 超过1小时显示x小时
    -- 超过1分钟显示x分钟
    -- 最小单位是分钟即可最小显示“1分钟后解锁”。
    local timeStr = ""
    if seconds >= 3600 * 24 then
        local day = math.ceil(seconds / 3600 / 24)
        timeStr = StringTable.Get("str_n_plus_six_day", day)
    else
        if seconds >= 3600 then
            local hour = math.ceil(seconds / 3600)
            timeStr = StringTable.Get("str_n_plus_six_hour", hour)
        else
            local minus = math.ceil(seconds / 60)
            if minus <= 0 then
                minus = 1
            end
            timeStr = StringTable.Get("str_n_plus_six_minus", minus)
        end
    end
    return timeStr
end

function UIN6MainController_Review:ShowBuildingLockTips()
    self._buildingLockTips:SetActive(true)
    local seconds = 0
    if self._buildComponentInfo then
        local openTime = self._buildComponentInfo.m_unlock_time
        local nowTime = self._timeModule:GetServerTime() / 1000
        seconds = openTime - nowTime
        if seconds < 0 then
            seconds = 0
        end
    end
    -- 同时在入口上增加一个时钟，点击则显示tips“x天后自动解锁”
    -- 时间显示规则：
    -- 超过24小时显示x天
    -- 超过1小时显示x小时
    -- 超过1分钟显示x分钟
    -- 最小单位是分钟即可最小显示“1分钟后解锁”。
    local timeStr = ""
    if seconds >= 3600 * 24 then
        local day = math.ceil(seconds / 3600 / 24)
        timeStr = StringTable.Get("str_n_plus_six_day", day)
    else
        if seconds >= 3600 then
            local hour = math.ceil(seconds / 3600)
            timeStr = StringTable.Get("str_n_plus_six_hour", hour)
        else
            local minus = math.ceil(seconds / 60)
            if minus <= 0 then
                minus = 1
            end
            timeStr = StringTable.Get("str_n_plus_six_minus", minus)
        end
    end
    self._buildingLockTipsLabel.text = StringTable.Get("str_n_plus_six_unlock_rebuilding_time_tips", timeStr)
end

--显示所有按钮
function UIN6MainController_Review:ShowBtnOnClick()
    local topBtn = self:GetGameObject("TopBtn")
    topBtn:SetActive(true)
    self._showBtn:SetActive(false)
    local anim = self:GetUIComponent("Animation", "Anim")
    anim:Play("uieff_N6_Main_Show")
end

function UIN6MainController_Review:HideBtnOnClick()
    local topBtn = self:GetGameObject("TopBtn")
    topBtn:SetActive(false)
    self._showBtn:SetActive(true)
    local anim = self:GetUIComponent("Animation", "Anim")
    anim:Play("uieff_N6_Main_Hide")
end

function UIN6MainController_Review:OnComponentStepChange(campaign_id, component_id, component_step)
end