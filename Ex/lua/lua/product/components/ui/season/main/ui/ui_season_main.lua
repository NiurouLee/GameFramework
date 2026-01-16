---@class UISeasonMainDisableOpenListReason:Object
local UISeasonMainDisableOpenListReason = {
    QuestPlot = 1,
    ShowBubble = 2,
    BuffLevelUp = 3,
    PlayEnterAnim = 4,
}
_enum("UISeasonMainDisableOpenListReason", UISeasonMainDisableOpenListReason)

--
---@class UISeasonMain : UIController
_class("UISeasonMain", UIController)
UISeasonMain = UISeasonMain

---@param res AsyncRequestRes
function UISeasonMain:LoadDataOnEnter(TT, res)
    res:SetSucc(true)
    local module = GameGlobal.GetModule(SeasonModule)
    module:ForceRequestCurSeasonData(TT)
    self._seasonObj = module:GetCurSeasonObj()
    if not self._seasonObj then
        res:SetSucc(false)
        Log.error("无法获取到赛季数据")
        return
    end
    res:SetSucc(true)
    ---@type ActionPointComponent
    self._actionPointCpt = self._seasonObj:GetComponent(ECCampaignSeasonComponentID.ACTION_POINT)
    ---@type SeasonMissionComponentInfo
    self._componentInfo = self._seasonObj:GetComponentInfo(ECCampaignSeasonComponentID.SEASON_MISSION)
end

--初始化
function UISeasonMain:OnShow(uiParams)
    self.showTestFuncEntry = true
    self._disableOpenListReasons = {}
    self:InitWidget()
    self._black:SetActive(false)
    ---@type UISeasonModule
    self._uiModule = GameGlobal.GetUIModule(SeasonModule)
    self._seasonManager = self._uiModule:SeasonManager()
    ---@type UISeasonTopBtn
    local topBtn = self.topBtns:SpawnObject("UISeasonTopBtn")
    local cfg = Cfg.cfg_season_campaign_client[self._seasonObj:GetSeasonID()]
    local entryVideoFunc
    if cfg.EnterVideo then
        entryVideoFunc = function()
            if self._seasonManager:LockUI() then
                return
            end
            self:_PlayEnterVideo()
            self:_TryStopPlayer()
        end
    end
    topBtn:SetData(
        function()
            self._active = false
            self._uiModule:ExitSeasonTo(UIStateType.UIS1Main)
        end,
        function()
            self._active = false
            self._uiModule:ExitSeasonTo(UIStateType.UIMain)
        end,
        function()
            Log.info("隐藏ui")
            self:SetShow(false)
            self:_TryStopPlayer()
        end,
        function()
            if self._seasonManager:LockUI() then
                return
            end
            UISeasonHelper.ShowSeasonHelperBook(UISeasonHelperTabIndex.Main)
            self:_TryStopPlayer()
        end,
        entryVideoFunc
    )
    ---@type UISeasonMainOvalArea
    self._ovalArea = self.ovalAreaPool:SpawnObject("UISeasonMainOvalArea")
    ---@type UISeasonMapArea
    self._seasonMap = self.mapAreaPool:SpawnObject("UISeasonMapArea")
    ---@type UISeasonDaily
    self._seasonDaily = self._daily:SpawnObject("UISeasonDaily") --赛季日常关
    self._seasonDaily:SetData(true)
    self:InitBuffLevelArea()
    self:InitFinalPlotEnterArea()
    self._active = true

    local cur, ceil = self._actionPointCpt:GetItemCount()
    self._pointCount:SetText(string.format("<color=#ff9d32>%s</color>/%s", cur, ceil))
    local actionPointID = self._actionPointCpt:GetItemId()
    local atlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
    self._topTipIcon.sprite = atlas:GetSprite(Cfg.cfg_top_tips[actionPointID].Icon)

    self:SetShow(true)

    self:AttachEvents()

    ---@type UISeasonMainLevelList
    self._levelList = self.levelListPool:SpawnObject("UISeasonMainLevelList")
    self._levelList:SetData(self._seasonObj)

    local infos = self._componentInfo.m_stage_info
    if UISeasonHelper.CheckEnterVideo(self._seasonObj:GetSeasonID()) or table.count(infos) > 0 then
        --看过了
        self:AfterPlayEnterVideo(false)
    else
        --没看过 开播
        UISeasonHelper.AfterShowEnterVideo(self._seasonObj:GetSeasonID())
        self._black:SetActive(true) --黑屏遮住
        self:_PlayEnterVideo(
            function()
                self._black:SetActive(false)
                self:AfterPlayEnterVideo(true)
            end
        )
    end
    self:_ResetCollectionInfo()
    self:_ResetQuestRed()
end

function UISeasonMain:AttachEvents()
    self:AttachEvent(GameEventType.SeasonLeaveToBattle, self.LeaveToBattle)
    self:AttachEvent(GameEventType.SeasonLeaveToMain, self.LeaveToMain)
    self:AttachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest) --奖励弹窗结束后
    self:AttachEvent(GameEventType.AfterUILayerChanged, self.OnAfterUILayerChanged)
    self:AttachEvent(GameEventType.ItemCountChanged, self.OnItemCountChanged)
    self:AttachEvent(GameEventType.OnSeasonCollectionObtained, self._OnGetCollection) --获得收藏品
    self:AttachEvent(GameEventType.OnSeasonActionPointChanged, self._OnActionPointChanged)
    self:AttachEvent(GameEventType.UISeasonS1OnSelectCollageItem, self._ResetCollageNew)
    self:AttachEvent(GameEventType.OnSeasonQuestAwardCollected, self._ResetQuestRed)
    self:AttachEvent(GameEventType.OnSeasonSceneAwardCollected, self._OnGetCollection)           --领取场景在的奖励
    self:AttachEvent(GameEventType.OnSerialAutoFightSweepFinish, self._OnAutoFightSweepFinished) --扫荡结束
    self:AttachEvent(GameEventType.OnSeasonDailyResetSucc, self._OnSeasonDailyResetSucc)         --日常关重置
    self:AttachEvent(GameEventType.UISeasonOnLevelDiffChanged, self._OnDiffChanged)              --难度切换
    self:AttachEvent(GameEventType.OnSeasonMainBottomEftPlay, self._PlayBtmEft)                  --难度切换
end

function UISeasonMain:DisableOpenList(bDisable, reason)
    if not self._disableOpenListReasons then
        self._disableOpenListReasons = {}
    end
    self._disableOpenListReasons[reason] = bDisable
    self:_TryShowOpenList()
end

function UISeasonMain:IsDisableOpenList()
    if self._disableOpenListReasons then
        for key, value in pairs(self._disableOpenListReasons) do
            if value then
                return true
            end
        end
    end
    return false
end

function UISeasonMain:OnAfterUILayerChanged()
    self:_TryShowOpenList()
end

function UISeasonMain:_TryShowOpenList()
    local topui = GameGlobal.UIStateManager():IsTopUI(self:GetName())
    if topui then
        self:ShowOpenList()
    end
end

function UISeasonMain:ShowOpenList()
    if self:IsDisableOpenList() then
        return
    end
    if self:CheckShowExpressBubbleOnEnter() then
        return
    end
    if self:CheckShowSerialRewards() then
        return
    end
    if self:CheckShowCollectionRewardOnEnter() then
        return
    end
    if self:CheckShowCollectionComposePlotOnEnter() then
        return
    end
    if self:CalcBuffLevelOnEnter() then
        return
    end
end

function UISeasonMain:CheckShowExpressBubbleOnEnter()
    ---@type UISeasonModule
    local uiSeasonModule = GameGlobal.GetUIModule(SeasonModule)
    local waitShowBubbles = uiSeasonModule:GetWaitShowBubbleCallbacks()
    if waitShowBubbles then
        if #waitShowBubbles > 0 then
            --local showBubbleCb = waitShowBubbles[1]
            --showBubbleCb:Call()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.SeasonTryShowEventBubble)
            uiSeasonModule:EraseFirstWaitShowBubbleCallback()
            return true
        end
    end
end

function UISeasonMain:OnUIGetItemCloseInQuest(type)
    self:RefreshBuffArea()
end

function UISeasonMain:OnUpdate(dtMS)
    if (IsPc() or IsUnityEditor()) and GameGlobal.EngineInput().GetKeyDown(UnityEngine.KeyCode.BackQuote) then
        self.showTestFuncEntry = not self.showTestFuncEntry
        self:SwitchTestFuncEntry(self.showTestFuncEntry)
    end
    if not self._active then
        return
    end

    if self._ovalArea then
        self._ovalArea:Update(dtMS)
    end

    if self._seasonMap then
        self._seasonMap:Update(dtMS)
    end
end

function UISeasonMain:OnHide()
    self._active = false
    if self._afterEnterAnimTimer then
        GameGlobal.Timer():CancelEvent(self._afterEnterAnimTimer)
        self._afterEnterAnimTimer = nil
    end
end

--获取ui组件
function UISeasonMain:InitWidget()
    --generated--
    ---@type UnityEngine.Animation
    self._animation = self:GetUIComponent("Animation", "SafeArea")
    ---@type UICustomWidgetPool
    self.buffLevelGen = self:GetUIComponent("UISelectObjectPath", "BuffLevelArea")
    ---@type UICustomWidgetPool
    self.finalPlotEnterGen = self:GetUIComponent("UISelectObjectPath", "FinalPlotEnterArea")
    ---@type UILocalizationText
    self.collectionCount = self:GetUIComponent("UILocalizationText", "CollectionCount")
    ---@type UICustomWidgetPool
    self.topBtns = self:GetUIComponent("UISelectObjectPath", "TopBtns")
    --generated end--

    ---region 测试功能
    if EngineGameHelper.IsDevelopmentBuild() or HelperProxy:GetInstance():GetConfig("EnableTestFunc", "false") == "true" then
        ---@type UICustomWidgetPool
        local testFuncPool = self:GetUIComponent("UISelectObjectPath", "TestFunc")
        if testFuncPool then
            ---@type UISeasonTestFunc
            self._testFunc = testFuncPool:SpawnObject("UISeasonTestFunc")
        end
    end
    ---region end 测试功能
    ---@type UICustomWidgetPool
    self.levelListPool = self:GetUIComponent("UISelectObjectPath", "LevelList")
    ---@type UICustomWidgetPool
    self.ovalAreaPool = self:GetUIComponent("UISelectObjectPath", "OvalArea")
    ---@type UICustomWidgetPool
    self.mapAreaPool = self:GetUIComponent("UISelectObjectPath", "MapArea")
    ---@type UICustomWidgetPool
    self._levelInfos = self:GetUIComponent("UISelectObjectPath", "LevelInfos")

    self.root = self:GetGameObject("Root")
    self.showUI = self:GetGameObject("ShowUI")
    self._levelBtn = self:GetGameObject("LevelBtn")
    self._pointCount = self:GetUIComponent("UILocalizationText", "PointCount")
    self._collageNew = self:GetGameObject("CollageNew")
    self._questRed = self:GetGameObject("QuestRed")
    self._topTipIcon = self:GetUIComponent("Image", "TopTipIcon")
    self._black = self:GetGameObject("Black")
    ---@type UICustomWidgetPool
    self._daily = self:GetUIComponent("UISelectObjectPath", "Daily")

    self._bottomEftAnim = self:GetUIComponent("Animation", "eff_scale")
end

function UISeasonMain:InitBuffLevelArea()
    ---@type UISeasonBuffMainArea
    self._buffLevelArea = self.buffLevelGen:SpawnObject("UISeasonBuffMainArea")
    if self._buffLevelArea then
        self._buffLevelArea:SetData(self._seasonObj)
    end
end

function UISeasonMain:InitFinalPlotEnterArea()
    if not self.finalPlotEnterGen then
        return
    end
    ---@type UISeasonFinalPlotEnter
    self._finalPlotEnterArea = self.finalPlotEnterGen:SpawnObject("UISeasonFinalPlotEnter")
    if self._finalPlotEnterArea then
        self._finalPlotEnterArea:SetData(self._seasonObj)
    end
end

function UISeasonMain:SwitchTestFuncEntry(show)
    if self._testFunc ~= nil then
        self._testFunc:Switch(show)
    end
end

function UISeasonMain:SetShow(show)
    self.root:SetActive(show)
    self.showUI:SetActive(not show)
end

--按钮点击
function UISeasonMain:PlayerIconOnClick(go)
    self._seasonManager:SeasonCameraManager():SwitchMode(SeasonCameraMode.Follow)
end

--按钮点击
function UISeasonMain:ArchieveBtnOnClick(go)
    if self._seasonManager:LockUI() then
        return
    end
    self:_TryStopPlayer()
    UISeasonHelper.ShowCurSeasonQuest()
end

--按钮点击
function UISeasonMain:CollectionBtnOnClick(go)
    if self._seasonManager:LockUI() then
        return
    end
    self:_TryStopPlayer()
    UISeasonHelper.ShowCurSeasonCollage()
end

function UISeasonMain:TopTipOnClick(go)
    if self._seasonManager:LockUI() then
        return
    end
    self:_TryStopPlayer()
    self:ShowDialog("UISeasonActionPointTip", self._actionPointCpt, go.transform.anchoredPosition)
end

function UISeasonMain:RefreshBuffArea()
    if self._buffLevelArea then
        self._buffLevelArea:RefreshInfo()
    end
end

--从风船进局前析构所有逻辑
function UISeasonMain:LeaveToBattle()
    self._active = false --todo
    self._uiModule:ExitSeasonGame()
end

function UISeasonMain:LeaveToMain()
    self._active = false
end

function UISeasonMain:ShowUIOnClick()
    self:SetShow(true)
end

function UISeasonMain:AfterPlayEnterVideo(played)
    if UISeasonHelper.CheckEnterStory(self._seasonObj:GetSeasonID()) then
        --看过了
        self:AfterPlayEnterStory(false)
    else
        --没看过 开播
        local cfg = Cfg.cfg_season_campaign_client[self._seasonObj:GetSeasonID()]
        -- self:ShowDialog("UIStoryController",
        --     cfg.EnterStory,
        --     function()
        --         self:AfterPlayEnterStory(true)
        --     end
        -- )

        UISeasonHelper.PlayStoryInSeasonScence(
            cfg.EnterStory,
            function()
                self:AfterPlayEnterStory(true)
            end
        )
    end
end

function UISeasonMain:AfterPlayEnterStory(played)
    if played then --播过之后标记
        UISeasonHelper.AfterPlayEnterStory(self._seasonObj:GetSeasonID())
    end
    --开始新手引导
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UISeasonMain)
    self:_PlayEnterAnim()
end

--连续自动战斗 弹窗
function UISeasonMain:ShowSerialRewards()
    self._isWaitShowSerialRewards = true
    --self:ShowDialog("UISerialAutoFightInfo", OpenUISerialFightInfoState.Finished)
end

function UISeasonMain:CheckShowSerialRewards()
    if self._isWaitShowSerialRewards then
        self:ShowDialog("UISerialAutoFightInfo", OpenUISerialFightInfoState.Finished)
        self._isWaitShowSerialRewards = false
        return true
    end
end

function UISeasonMain:CheckShowCollectionRewardOnEnter()
    ---@type SeasonModule
    local seasonModule = self:GetModule(SeasonModule)
    local waitShowRewards = seasonModule:GetWaitShowCollectionRewards()
    if waitShowRewards then
        if #waitShowRewards > 0 then
            local showRewards = { waitShowRewards[1] }
            UISeasonHelper.ShowUIGetRewards(showRewards) --逐个触发，避免后续弹窗（buff升级等）与奖励弹窗重叠
            seasonModule:EraseFirstWaitShowCollectionRewards()
            return true
        end
    end
end

function UISeasonMain:CalcBuffLevelOnEnter()
    ---@type SeasonModule
    local seasonModule = self:GetModule(SeasonModule)
    local componentID = self._seasonObj:GetSeasonMissionComponentCfgID()
    local curLevel, curProgress = UISeasonHelper.CalcBuffLevel(componentID)
    local oldLevel, oldProgress = seasonModule:GetRecordBuffLevel()
    if oldLevel == -1 then
        seasonModule:RecordBuffLevel(curLevel, curProgress)
    else
        if curLevel ~= oldLevel then
            self:DisableOpenList(true, UISeasonMainDisableOpenListReason.BuffLevelUp)
            --需要播动画
            self:ShowDialog(
                "UISeasonBuffLevelUp",
                oldLevel,
                curLevel,
                componentID,
                function()
                    self:DisableOpenList(false, UISeasonMainDisableOpenListReason.BuffLevelUp)
                end
            )
            --self._waitPlayBuffLevelUp = true
            seasonModule:RecordBuffLevel(curLevel, curProgress)
            return true
        end
    end
end

--收藏品合成
function UISeasonMain:CheckShowCollectionComposePlotOnEnter()
    ---@type CampaignQuestComponent
    if not self.questCmpt then
        self.questCmpt = self._seasonObj:GetComponent(ECCampaignSeasonComponentID.QUEST_STORY)
    end
    if self.questCmpt then
        if self.questCmpt then
            ---@type list<Quest>
            self._questList = self.questCmpt:GetQuestInfo()
            local questStatus = self.questCmpt:GetCampaignQuestStatus(self._questList)
            local completedQuest = nil

            --排除掉最终剧情任务，这个要手动点按钮触发
            local seasonId = self._seasonObj:GetSeasonID()
            local finalStoryQuestId = nil
            local seasonClientCfg = Cfg.cfg_season_campaign_client[seasonId]
            if seasonClientCfg then
                finalStoryQuestId = seasonClientCfg.FinalStoryQuestID
            end
            for quest, v in pairs(questStatus) do
                if v == CampaignQuestStatus.CQS_Completed then
                    if finalStoryQuestId and quest._questInfo.quest_id == finalStoryQuestId then
                    else
                        completedQuest = quest
                        break
                    end
                end
            end
            if completedQuest then
                self:DisableOpenList(true, UISeasonMainDisableOpenListReason.QuestPlot)
                local cb = function() self:OnCollectionComposePlotEnd(completedQuest) end
                local composeStoryID = nil
                local cfgs = Cfg.cfg_item_season_collection { ComposeQuestID = completedQuest._questInfo.quest_id }
                if #cfgs > 0 then
                    local cfg = cfgs[1]
                    composeStoryID = cfg.ComposeStoryID
                end
                if composeStoryID then
                    -- self:ShowDialog("UIStoryController", composeStoryID, cb)
                    self._animation:Stop() --播剧情之前必须停掉入场动画 否则剧情界面打开时会关闭之前的所有界面 导致入场动画中途打断 残留在屏幕上
                    UISeasonHelper.PlayStoryInSeasonScence(composeStoryID, cb)
                    return true
                end
            end
        end
    end
end

function UISeasonMain:OnCollectionComposePlotEnd(completedQuest)
    if not self.questCmpt then
        self:DisableOpenList(false, UISeasonMainDisableOpenListReason.QuestPlot)
        return
    end
    ---@type CampaignQuestStatus
    local questStatus = self.questCmpt:CheckCampaignQuestStatus(completedQuest._questInfo)
    if questStatus == CampaignQuestStatus.CQS_Completed then
        --领奖
        self.questCmpt:Start_HandleQuestTake(completedQuest._questInfo.quest_id,
            function(res, rewards)
                --self:_OnRecvRewardsWithAnim(res, rewards)
                if not self.view then
                    return
                end
                if res and res:GetSucc() then
                    UISeasonHelper.ShowUIGetRewards(rewards)
                else
                end
                self:DisableOpenList(false, UISeasonMainDisableOpenListReason.QuestPlot)
            end
        )
    else
    end
end

function UISeasonMain:_OnGetCollection()
    self:_ResetCollectionInfo()
    self:_TryShowOpenList()
end

function UISeasonMain:_ResetCollectionInfo()
    local data = self._uiModule:GetCollageData()
    data:FlushAllCollages()
    local count = data:GetCollectionProgress()
    self.collectionCount:SetText(count)
    self:_ResetCollageNew()
end

function UISeasonMain:_ResetCollageNew()
    local data = self._uiModule:GetCollageData()
    self._collageNew:SetActive(data:CollectionHasNew())
end

function UISeasonMain:_ResetQuestRed()
    --- @type CampaignQuestComponent
    local cpt = self._seasonObj:GetComponent(ECCampaignSeasonComponentID.QUEST)
    self._questRed:SetActive(cpt:HaveRedPoint())
end

function UISeasonMain:_PlayEnterVideo(onEnd)
    local seasonAudio = self._seasonManager:SeasonAudioManager():GetSeasonAudio()
    seasonAudio:StopSeasonSounds()
    local cfg = Cfg.cfg_season_campaign_client[self._seasonObj:GetSeasonID()]
    local leftBg, rightBg
    if cfg.EnterVideoBG then
        leftBg = cfg.EnterVideoBG[1]
        rightBg = cfg.EnterVideoBG[2]
    end
    if CriWare.CriManaMovieControllerForUI then
        self:ShowDialog("UICriVideoController",
            cfg.EnterVideo,
            leftBg,
            function()
                seasonAudio:ResumeSeasonSounds()
                if onEnd then
                    onEnd()
                end
            end,
            rightBg
        )
    else
        self:ShowDialog("UICriVideoControllerNowrap",
            cfg.EnterVideo,
            leftBg,
            function()
                seasonAudio:ResumeSeasonSounds()
                if onEnd then
                    onEnd()
                end
            end,
            rightBg
        )
    end
end

function UISeasonMain:_OnActionPointChanged()
    local cur, ceil = self._actionPointCpt:GetItemCount()
    self._pointCount:SetText(string.format("<color=#ff9d32>%s</color>/%s", cur, ceil))
end

function UISeasonMain:_OnAutoFightSweepFinished()
    self:_OnActionPointChanged()
    self:_ResetCollectionInfo()
    self:_ResetQuestRed()
end

function UISeasonMain:_TryStopPlayer()
    self._seasonManager:SeasonPlayerManager():GetPlayer():Stop(false)
end

--入场动画
function UISeasonMain:_PlayEnterAnim()
    self._animation:Play("uieffanim_UISeasonMain_in")
    self._seasonManager:SeasonCameraManager():DoEnterAnim()

    self:DisableOpenList(true, UISeasonMainDisableOpenListReason.PlayEnterAnim)
    if self._afterEnterAnimTimer then
        GameGlobal.Timer():CancelEvent(self._afterEnterAnimTimer)
        self._afterEnterAnimTimer = nil
    end
    local enterAnimTime = 1000
    self._afterEnterAnimTimer = GameGlobal.Timer():AddEvent(
        enterAnimTime,
        function()
            self:_OnEnterAnimEnd()
        end
    )
end
function UISeasonMain:_OnEnterAnimEnd()
    self:DisableOpenList(false, UISeasonMainDisableOpenListReason.PlayEnterAnim)
end
--赛季日常关重置
function UISeasonMain:_OnSeasonDailyResetSucc()
    if self._seasonDaily then
        self._seasonDaily:SetData()
    end
end

function UISeasonMain:_OnDiffChanged(curDiff)
    self._bottomEftAnim:Stop()
    if curDiff == UISeasonLevelDiff.Normal then
        self:_PlayBtmEftOut()
    elseif curDiff == UISeasonLevelDiff.Hard then
        self:_PlayBtmEftIn()
    else
    end
end

function UISeasonMain:_PlayBtmEft(isIn)
    if isIn then
        self:_PlayBtmEftIn()
    else
        self:_PlayBtmEftOut()
    end
end

function UISeasonMain:_PlayBtmEftIn()
    self._bottomEftAnim:Stop()
    self._bottomEftAnim:PlayQueued("uieff_UISeasonMain_bowen_in")
end

function UISeasonMain:_PlayBtmEftOut()
    self._bottomEftAnim:Stop()
    self._bottomEftAnim:Play("uieff_UISeasonMain_bowen_out")
    self._bottomEftAnim:PlayQueued("uieff_UISeasonMain_bowen_loop")
end

---主界面播放进入动画
function UISeasonMain:IsPlayAnimation()
    if self._animation then
        local name = "uieffanim_UISeasonMain_in"
        if self._animation:IsPlaying(name) then
            ---@type UnityEngine.AnimationState
            local state = self._animation:get_Item(name)
            return true, state.length
        end
    end
    return false
end