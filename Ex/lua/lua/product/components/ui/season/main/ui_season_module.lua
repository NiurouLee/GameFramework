---@class UISeasonModule:UIModule
_class("UISeasonModule", UIModule)
UISeasonModule = UISeasonModule

function UISeasonModule:Constructor()
    ---@type SeasonManager
    self._seasonManager = SeasonManager:New()
end

function UISeasonModule:EnterSeasonGame(params)
    self._running = true
    self:ClearWaitShowBubbleCallbacks()
    local curSeasonID = GameGlobal.GetModule(SeasonModule):GetCurSeasonID()
    self._levelDiffKey = GameGlobal.GetModule(RoleModule):GetPstId() .. "_" .. curSeasonID .. "_" .. "LevelDiff"
    self._seasonManager:Init(curSeasonID, params)
end

function UISeasonModule:ExitSeasonGame()
    self._seasonManager:Dispose()
    self._levelDiffKey = nil
    self._running = false
end

--返回主界面
---@param exitParam function|UIStateType 退出赛季后支持两种参数 执行一个回调或者 打开状态ui
function UISeasonModule:ExitSeasonTo(exitParam)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.SeasonLeaveToMain)
    -- uiState = uiState or UIStateType.UIMain --不指定就回主界面
    GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Season_Exit, "UI", exitParam)
end

function UISeasonModule:Update(curTick)
    if self._running then
        self._seasonManager:Update(GameGlobal:GetInstance():GetDeltaTime())
    end
end

function UISeasonModule:SeasonManager()
    return self._seasonManager
end

function UISeasonModule:InSeasaonRunning()
    return self._running
end

--打开当期的收藏品界面
function UISeasonModule:OpenCollectionPanel()

end

--进入赛季系统UI（虚实之扉）
function UISeasonModule:EnterSeasonSystemUI()
    local seasonModule = self:GetModule(SeasonModule)
    if seasonModule:CheckExtMask(ESeasonExtInfo.SeasonFirstPlotReadState) then
        GameGlobal.UIStateManager():SwitchState(UIStateType.UISeasonExploreMainController)
    else
        TaskManager:GetInstance():StartTask(
            function(TT)
                local mask = seasonModule:AppendExtMaskData(ESeasonExtInfo.SeasonFirstPlotReadState)
                seasonModule:ReqCEventSeasonStory(TT, mask)
                --show plot
                local plotId = Cfg.cfg_global["season_system_first_plot"].IntValue
                GameGlobal.UIStateManager():ShowDialog("UIStoryController", plotId,
                    function()
                        GameGlobal.UIStateManager():SwitchState(UIStateType.UISeasonExploreMainController)
                    end)
            end
        )
    end
end

--打开当前赛季主题
function UISeasonModule:OpenSeasonThemeUI(...)
    GameGlobal.UIStateManager():ShowDialog("UIS1MainController", ...)
end

--进入当前赛季界面
function UISeasonModule:EnterCurrentSeasonMainUI()
    local seasonModule = self:GetModule(SeasonModule)
    ---@type campaign_sample
    local sample = seasonModule:GetCurSeasonSample()
    local svrTime = GameGlobal.GetModule(SvrTimeModule):GetServerTime() * 0.001
    if sample and sample:IsShow(svrTime) then
        --open
    else
        --close
        local tips = StringTable.Get("str_activity_error_109")
        ToastManager.ShowToast(tips)
        return
    end

    local cfg = Cfg.cfg_season_map[seasonModule:GetCurSeasonID()]
    if cfg and cfg.MapRes then
        GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Season_Enter, cfg.MapRes)
    end
end

--检查当前赛季是否显示任务页签（任务界面用）
function UISeasonModule:GetCurSeasonQuestContent()
    local seasonModule = self:GetModule(SeasonModule)
    local id = seasonModule:GetCurSeasonID()
    return UISeasonCfgHelper.GetCurSeasonQuestContent(id)
end

--打开兑换商店历史商店页签
function UISeasonModule:EnterExchangeShopSeasonTab()
    GameGlobal.UIStateManager():ShowDialog("UIShopController", 2, ShopMainTabType.Exchange, MarketType.Shop_Season)
end

---@return UISeasonLevelDiff 当前赛季关卡难度
function UISeasonModule:GetCurrentSeasonLevelDiff()
    return LocalDB.GetInt(self._levelDiffKey, UISeasonLevelDiff.Hard)
end

---@param diff UISeasonLevelDiff 设置当前赛季关卡难度
function UISeasonModule:SetCurrentSeasonLevelDiff(diff)
    LocalDB.SetInt(self._levelDiffKey, diff)
    self._seasonManager:SwitchDiff(diff)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UISeasonOnLevelDiffChanged, diff)
end

---@return UISeasonCollageData 赛季收藏品数据
function UISeasonModule:GetCollageData()
    if not self._seasonCollageData then
        self._seasonCollageData = UISeasonCollageData:New(GameGlobal.GetModule(SeasonModule):GetCurSeasonID())
    end
    return self._seasonCollageData
end

--region new and red
--获取当前赛季的new标签和红点
--可能每个赛季都需要单独写自己的
--这次先加上S1的
function UISeasonModule:GetCurrentSeasonNew()
    return self:GetS1SeasonNew()
end

function UISeasonModule:GetCurrentSeasonRed()
    return self:GetS1SeasonRed()
end

function UISeasonModule:GetS1SeasonNew()
    local new = false
    local sample = self:GetModule(SeasonModule):GetCurSeasonSample()
    local svrTime = self:GetModule(SvrTimeModule):GetServerTime() * 0.001
    if sample and sample:IsShow(svrTime) then
        new = not UISeasonLocalDBHelper.SeasonBtn_Has("UIS1MainEnter", "New")
    end
    return new
end

function UISeasonModule:GetS1SeasonRed()
    local red = false
    local sample = self:GetModule(SeasonModule):GetCurSeasonSample()
    local svrTime = self:GetModule(SvrTimeModule):GetServerTime() * 0.001
    if sample and sample:IsShow(svrTime) then
        red = sample:GetStepStatus(ECampaignStep.CAMPAIGN_STEP_SEASONQUEST_REWARD)
    end
    --进入梦境
    if not red then
        local lastTime = UISeasonLocalDBHelper.SeasonBtn_Get("UIS1GoBtn", "Red")
        red = HelperProxy:IsCrossDayTo(lastTime)
    end
    return red
end

--endregion

--处理时间点弹气泡与赛季主界面弹窗列表
function UISeasonModule:AppendWaitShowBubbleCallback(callback)
    if not self._waitShowBubbleCallbacks then
        self._waitShowBubbleCallbacks = {}
    end
    table.insert(self._waitShowBubbleCallbacks, callback)
end

function UISeasonModule:EraseFirstWaitShowBubbleCallback()
    if not self._waitShowBubbleCallbacks then
        self._waitShowBubbleCallbacks = {}
    end
    table.remove(self._waitShowBubbleCallbacks, 1)
end

function UISeasonModule:ClearWaitShowBubbleCallbacks()
    self._waitShowBubbleCallbacks = {}
end

function UISeasonModule:GetWaitShowBubbleCallbacks()
    return self._waitShowBubbleCallbacks
end
