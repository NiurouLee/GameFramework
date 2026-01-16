---@class UIQuestDailyItem:UICustomWidget
_class("UIQuestDailyItem", UICustomWidget)
UIQuestDailyItem = UIQuestDailyItem

function UIQuestDailyItem:OnShow(uiParams)
    ---@type ATransitionComponent
    self._transition = self:GetUIComponent("ATransitionComponent", "UIQuestDailyItem")
    ---@type UnityEngine.CanvasGroup
    self._canvasGroup = self:GetUIComponent("CanvasGroup", "UIQuestDailyItem")
    self._canvasGroup.blocksRaycasts = false

    --每行显示的列数
    self._itemCountPerRow = 1

    self._isFirst = true

    self._dispatchTypeQuest = QuestType.QT_Daily
    self._dispatchTypeActive = QuestType.QT_Daily + 100
    self._dispatchTypeAll = QuestType.QT_Daily + 10000

    self:AttachEvents()
end

function UIQuestDailyItem:UIQuestDailyReset()
    self:ShowDialog("UIRugueLikeResetMsgBoxController", StringTable.Get("str_quest_base_daily_reset_tips")) 
    self:ShowActivityTitle()
end

function UIQuestDailyItem:RefreshDailyQuestList()
    self:RefrenshList()
end

function UIQuestDailyItem:SetData(type)
    self._transition:PlayEnterAnimation(true)
    self._canvasGroup.blocksRaycasts = true

    self._isOpen = true

    self:_GetComponents()

    self._type = type
    self._svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    self._questModule = GameGlobal.GetModule(QuestModule)
    if self._questModule == nil then
        Log.fatal("[quest] error --> questModule is nil !")
        return
    end

    --[[
        close
        self._activePoint = 20
        ]]
    self._questList = self:_GetTaskList()
    self._taskCount = table.count(self._questList)
    self:_OnValue()
end

function UIQuestDailyItem:_GetTaskList()
    local taskList = self._questModule:GetQuestByQuestType(self._type)
    local taskListT = {}
    for i = 1, #taskList do
        local quest = taskList[i]:QuestInfo()
        if quest.status ~= QuestStatus.QUEST_NotStart then
            table.insert(taskListT, taskList[i])
        end
    end
    return taskListT
end

--刷新信息(任务奖励领取后的信息刷新)
function UIQuestDailyItem:RefrenshList()
    self._questList = self:_GetTaskList()

    self._taskCount = table.count(self._questList)

    local contentPos = self._list.ScrollRect.content.localPosition

    self._list:SetListItemCount(self._taskCount)
    self._list:MovePanelToItemIndex(0, 0)

    self._list.ScrollRect.content.localPosition = contentPos

    self:_ShowActivePoint()

    self:DailyQuestTimeRefresh()

    self:ShowWeekAwards()
end
--刷新乎阅读
function UIQuestDailyItem:RefrenshActivePoint()
    self:_ShowActivePoint()
end
function UIQuestDailyItem:GetFillAmount(val)
    local cst = {0.099, 0.327, 0.554, 0.782, 1}
    
    local idx = math.modf(val/20)

    if idx>=#cst then
        return 1
    end

    local rate = cst[idx] or 0

    local next = cst[idx+1]

    local min = rate

    local max = next

    local ret = (val-idx*20)/20*(max-min)+min

    return ret
end
--活跃度
function UIQuestDailyItem:_ShowActivePoint()
    --获取当前活跃度
    self._activePoint = self._questModule:GetDailyQuestVigorous()
    Log.debug("###[UIQuestDailyItem] _ShowActivePoint --> ", self._activePoint)
    self._cfg_vigorous_reward = Cfg.cfg_vigorous_reward {}
    if self._cfg_vigorous_reward == nil then
        Log.fatal("[quest] error --> _cfg_vigorous_reward is nil ! name --> cfg_vigorous_reward")
        return
    end

    local count = table.count(self._cfg_vigorous_reward)
    local upper = self._cfg_vigorous_reward[count].VigPoint
    --local rate = self._activePoint / upper

    self._activePointValue:SetText("<size=54>"..self._activePoint .. "</size><color=#7386ff>/" .. upper .. "</color>")

    local rate = self:GetFillAmount(self._activePoint)

    self._activePointImg.fillAmount = rate

    local width = self._activePointPoolRect.sizeDelta.x

    self._activePointPool:SpawnObjects("UIQuestDailyActivePointItem", count)
    ---@type UIQuestDailyActivePointItem[]
    local aps = self._activePointPool:GetAllSpawnList()

    for i = 1, count do
        local _posX = self._cfg_vigorous_reward[i].VigPoint / upper * width
        aps[i]:SetData(
            i,
            self._cfg_vigorous_reward,
            self._activePoint,
            _posX,
            function(idx)
                self:ActivePointItemClick(idx)
            end
        )
    end
end

function UIQuestDailyItem:ActivePointItemClick(idx)
    self:Lock("UIQuestGet")
    self:StartTask(self.OnActivePointItemClick, self, idx)
end

function UIQuestDailyItem:OnActivePointItemClick(TT, idx)
    local res, msg = self._questModule:TakeVigReward(TT, idx)
    self:UnLock("UIQuestGet")
    if (self.uiOwner == nil) then
        return
    end
    if res:GetSucc() then
        local rewards = msg.rewards
        self:ShowDialog(
            "UIGetItemController",
            rewards,
            function()
                GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIGetItemCloseInQuest, self._dispatchTypeActive)
            end
        )
    end
end

--倒计时
function UIQuestDailyItem:DailyQuestTimeRefresh()
    self._timeStrColor = "ffe701"

    self:ShowSurTime()

    --开启计时
    self:OpenSurSecond()
end

-- 计算剩余时间
function UIQuestDailyItem:CalSurSecond()
    if self._svrTimeModule == nil then
        self._svrTimeModule = self:GetModule(SvrTimeModule)
    end

    local svrTime = math.floor(self._svrTimeModule:GetServerTime() * 0.001)

    if self._questModule == nil then
        self._questModule = self:GetModule(QuestModule)
    end

    local questModule = self._questModule
    local resetTime = questModule:GetQuestDailyRefreshTime(svrTime)

    --剩余秒数
    self._surSecond = resetTime - svrTime
end

function UIQuestDailyItem:Second2TimeStr(second)
    local sec = math.floor(second % 60)
    local min = math.floor(second / 60 % 60)
    local hour = math.floor(second / 60 / 60)

    local secStr
    if sec < 10 then
        secStr = "0" .. sec
    else
        secStr = sec
    end

    local minStr
    if min < 10 then
        minStr = "0" .. min
    else
        minStr = min
    end

    local hourStr
    if hour < 10 then
        hourStr = "0" .. hour
    else
        hourStr = hour
    end

    local str = hourStr .. ":" .. minStr .. ":" .. secStr
    return str
end

function UIQuestDailyItem:OpenSurSecond()
    if self._surTimeEvent then
        GameGlobal.Timer():CancelEvent(self._surTimeEvent)
        self._surTimeEvent = nil
    end
    self._surTimeEvent =
        GameGlobal.Timer():AddEventTimes(
        1000,
        TimerTriggerCount.Infinite,
        function()
            self:ShowSurTime()
        end
    )
end

function UIQuestDailyItem:ShowSurTime()
    local svrTime = math.floor(self._svrTimeModule:GetServerTime() * 0.001)

    local resetTime = self._questModule:GetQuestDailyRefreshTime(svrTime)

    local timeStamp = resetTime - svrTime

    if timeStamp > 0 then
        local timeStr = self:Second2TimeStr(timeStamp)
        local showStr = "<color=#" .. self._timeStrColor .. ">" .. timeStr .. "</color>"
        self._refreshTipTex:SetText(string.format(StringTable.Get("str_quest_base_daily_refresh_tip"), showStr))
    else
        --Log.debug("###[UIQuestDailyItem]UIQuestDailyItem:timeStamp < 0 !")
        --self:_ShowActivePoint()
    end
end

--时间戳转年月日
function UIQuestDailyItem:Time2Day(unixTime)
    local tb = {}
    tb.year = tonumber(os.date("%Y", unixTime))
    tb.month = tonumber(os.date("%m", unixTime))
    tb.day = tonumber(os.date("%d", unixTime))
    tb.hour = tonumber(os.date("%H", unixTime))
    tb.minute = tonumber(os.date("%M", unixTime))
    tb.second = tonumber(os.date("%S", unixTime))
    return tb
end

function UIQuestDailyItem:OnClose()
    self._isOpen = false

    if self._surTimeEvent then
        GameGlobal.Timer():CancelEvent(self._surTimeEvent)
        self._surTimeEvent = nil
    end

    self._transition:PlayLeaveAnimation(true)
    self._canvasGroup.blocksRaycasts = false
end

function UIQuestDailyItem:OnHide()
    if self._surTimeEvent then
        GameGlobal.Timer():CancelEvent(self._surTimeEvent)
        self._surTimeEvent = nil
    end
    self:RemoveEvents()
end

function UIQuestDailyItem:_GetComponents()
    self._list = self:GetUIComponent("UIDynamicScrollView", "taskList")

    self._activePointPool = self:GetUIComponent("UISelectObjectPath", "activePoint")

    self._activePointPoolRect = self:GetUIComponent("RectTransform", "activePoint")

    self._activePointImg = self:GetUIComponent("Image", "activePointImg")

    self._activePointValue = self:GetUIComponent("UILocalizationText", "activePointValue")

    self._refreshTipTex = self:GetUIComponent("UILocalizationText", "refreshTipTex")

    self._activityTitle = self:GetGameObject("activityTitle")

    self._weekAwards = self:GetUIComponent("Image","WeekAwards")
    self._weekAwardsTex = self:GetUIComponent("UILocalizationText","weekAwardsTex")

    self._atlas = self:GetAsset("UIQuest.spriteatlas", LoadType.SpriteAtlas)
end

function UIQuestDailyItem:_OnValue()
    if self._isFirst then
        -- body
        self._list:InitListView(
            self._taskCount,
            function(scrollView, index)
                return self:_InitDailyTaskList(scrollView, index)
            end
        )
        self._isFirst = false

        self:_ShowActivePoint()

        self:DailyQuestTimeRefresh()

    else
        self:RefrenshList()
    end
    self:ShowActivityTitle()
    self:ShowWeekAwards()
end
function UIQuestDailyItem:ShowWeekAwards()
    local weekQuestList = self._questModule:GetQuestByQuestType(QuestType.QT_Week)
    if weekQuestList and #weekQuestList > 0 then
        ---@type Quest
        self._weekQuest = weekQuestList[1]
        Log.debug("###[UIQuestDailyItem] ShowWeekAwards get quest succ !")
        self._weekQuestInfo = self._weekQuest:QuestInfo()
    
        local weekActiveVal = self._weekQuestInfo.cur_progress
        local weekActiveGetVal = self._weekQuestInfo.total_progress
        self._weekAwardStatus = self._weekQuestInfo.status

        Log.debug("###[UIQuestDailyItem] ShowWeekAwards _weekAwardStatus:",self._weekAwardStatus)

        local sprite
        if self._weekAwardStatus == QuestStatus.QUEST_Taken then
            sprite = "task_richang_icon_week_3"
        elseif self._weekAwardStatus == QuestStatus.QUEST_Completed then
            sprite = "task_richang_icon_week_2"
        else
            sprite = "task_richang_icon_week_1"
        end

        self._weekAwardsTex:SetText(weekActiveVal.."/"..weekActiveGetVal)
        self._weekAwards.sprite = self._atlas:GetSprite(sprite)
    else
        Log.exception("###[UIQuestDailyItem] 没有获取到周任务，查看任务配置")
    end
end
function UIQuestDailyItem:WeekAwardsOnClick(go)
    Log.debug("###[UIQuestDailyItem] WeekAwardsOnClick !")

    if self._weekAwardStatus == QuestStatus.QUEST_Completed then
        --领奖
        self:GetQuestItemAward(self._weekQuestInfo.quest_id)
    elseif self._weekAwardStatus == QuestStatus.QUEST_Taken then
        --提示
        local tips = StringTable.Get("str_quest_base_dayli_tips_awards_got")
        ToastManager.ShowToast(tips)
    else
        --弹奖励界面
        local awards = self._weekQuestInfo.rewards
        local total = self._weekQuestInfo.total_progress
        local endTime = self._questModule:GetWeekRefreshTime()
        self:ShowDialog("UIQuestDailyWeekAwards",awards,endTime,total)
    end
end
function UIQuestDailyItem:ShowActivityTitle()
    --检查活动有没有开启
    local isOpen = false
    local cfg = UIQuestDailyExtraEnter.GetOpenCfg()
    if not cfg then
        Log.fatal("###[UIQuestDailyItem] cfg is nil ! id --> ",1)
    else
        local loginModule = GameGlobal.GetModule(LoginModule)
        local svrTime = self._svrTimeModule:GetServerTime() * 0.001
        local startTimeStr = cfg.StartTime
        local endTimeStr = cfg.EndTime
        local openTime = loginModule:GetTimeStampByTimeStr(startTimeStr,Enum_DateTimeZoneType.E_ZoneType_ServerTimeZone)
        local closeTime = loginModule:GetTimeStampByTimeStr(endTimeStr,Enum_DateTimeZoneType.E_ZoneType_ServerTimeZone)
        if svrTime >= openTime and svrTime < closeTime then
            isOpen = true
        end
    end
    self._activityTitle:SetActive(isOpen)
    if isOpen then
        self._activityTitle.transform:GetChild(0):GetComponent("RectTransform").pivot = Vector2(0, 0.5)
    end
end
function UIQuestDailyItem:_InitDailyTaskList(scrollView, index)
    if index < 0 then
        return nil
    end
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UIQuestDailyListItem", self._itemCountPerRow)
    end
    ---@type UIQuestDailyListItem[]
    local rowList = rowPool:GetAllSpawnList()
    for i = 1, self._itemCountPerRow do
        local heartItem = rowList[i]
        local itemIndex = index * self._itemCountPerRow + i
        self:_ShowDailyItem(heartItem, itemIndex)
    end
    return item
end
---@param heartItem UIQuestDailyListItem
function UIQuestDailyItem:_ShowDailyItem(heartItem, index)
    local quest = self._questList[index]
    heartItem:GetGameObject():SetActive(true)
    if (quest ~= nil) then
        heartItem:SetData(
            index,
            quest,
            function(questInfo)
                self:QuestItemClick(questInfo)
            end,
            function(matid, pos)
                GameGlobal.EventDispatcher():Dispatch(GameEventType.QuestAwardItemClick, matid, pos)
            end
        )
    end
end

function UIQuestDailyItem:QuestItemClick(questInfo)
    if questInfo.status <= QuestStatus.QUEST_Accepted then --未完成
        ---@type UIJumpModule
        local jumpModule = self._questModule.uiModule
        if jumpModule == nil then
            Log.fatal("[quest] error --> uiModule is nil ! --> jumpModule")
            return
        end
        --FromUIType.NormalUI
        local fromParam = {}
        table.insert(fromParam, QuestType.QT_Daily)
        jumpModule:SetFromUIData(FromUIType.NormalUI, "UIQuestController", UIStateType.UIMain, fromParam)
        local jumpType = questInfo.JumpID
        local jumpParams = questInfo.JumpParam
        jumpModule:SetJumpUIData(jumpType, jumpParams)
        jumpModule:Jump()
    elseif questInfo.status == QuestStatus.QUEST_Completed then --未领取
        self:GetQuestItemAward(questInfo.quest_id)
    end
end

function UIQuestDailyItem:GetQuestItemAward(id)
    GameGlobal.GetModule(PetModule):GetAllPetsSnapshoot()
    self:Lock("UIQuestGet")
    self:StartTask(self._GetQuestItemAwardReq, self, id)
end
function UIQuestDailyItem:_GetQuestItemAwardReq(TT, id)
    local res, msg = self._questModule:TakeQuestReward(TT, id)
    self:UnLock("UIQuestGet")
    if (self.uiOwner == nil) then
        return
    end
    if res:GetSucc() then
        local tempPets = {}
        local pets = msg.rewards
        self._tempMsgRewards = msg.rewards

        if #pets > 0 then
            for i = 1, #pets do
                local ispet = GameGlobal.GetModule(PetModule):IsPetID(pets[i].assetid)
                if ispet then
                    table.insert(tempPets, pets[i])
                end
            end
        end
        if #tempPets > 0 then
            self:ShowDialog(
                "UIPetObtain",
                tempPets,
                function()
                    GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
                    GameGlobal.EventDispatcher():Dispatch(
                        GameEventType.OnUIPetObtainCloseInQuest,
                        self._dispatchTypeQuest
                    )
                end
            )
        else
            self:ShowDialog(
                "UIGetItemController",
                msg.rewards,
                function()
                    GameGlobal.EventDispatcher():Dispatch(
                        GameEventType.OnUIGetItemCloseInQuest,
                        self._dispatchTypeQuest
                    )
                end
            )
        end
    end
end

function UIQuestDailyItem:AttachEvents()
    self:AttachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
    self:AttachEvent(GameEventType.OnUIPetObtainCloseInQuest, self.OnUIPetObtainCloseInQuest)
    self:AttachEvent(GameEventType.UIQuestDailyReset, self.UIQuestDailyReset)
    self:AttachEvent(GameEventType.UIQuestDailyVigorous, self.UIQuestDailyVigorous)
    self:AttachEvent(GameEventType.OnWeekRewardChanged, self.ShowWeekAwards)
end
function UIQuestDailyItem:RemoveEvents()
    self:DetachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
    self:DetachEvent(GameEventType.OnUIPetObtainCloseInQuest, self.OnUIPetObtainCloseInQuest)
    self:DetachEvent(GameEventType.UIQuestDailyReset, self.UIQuestDailyReset)
    self:DetachEvent(GameEventType.UIQuestDailyVigorous, self.UIQuestDailyVigorous)
    self:DetachEvent(GameEventType.OnWeekRewardChanged, self.ShowWeekAwards)
end

function UIQuestDailyItem:UIQuestDailyVigorous()
    Log.debug("###[UIQuestDailyItem] UIQuestDailyVigorous!")
    self:_ShowActivePoint()
end

function UIQuestDailyItem:OnUIGetItemCloseInQuest(type)
    if self._isOpen then
        if type == self._dispatchTypeQuest then
            self:RefrenshList()
        elseif type == self._dispatchTypeActive then
            self:RefrenshActivePoint()
        elseif type == self._dispatchTypeAll then
            self:RefrenshList()
            self:RefrenshActivePoint()
        end
    end
end
function UIQuestDailyItem:OnUIPetObtainCloseInQuest(type)
    if self._isOpen then
        if type == self._dispatchTypeQuest then
            self:ShowDialog(
                "UIGetItemController",
                self._tempMsgRewards,
                function()
                    GameGlobal.EventDispatcher():Dispatch(
                        GameEventType.OnUIGetItemCloseInQuest,
                        self._dispatchTypeQuest
                    )
                end
            )
        elseif type == self._dispatchTypeAll then
            self:ShowDialog(
                "UIGetItemController",
                self._tempMsgRewards,
                function()
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIGetItemCloseInQuest, self._dispatchTypeAll)
                end
            )
        end
    end
end

function UIQuestDailyItem:getAllBtnOnClick()
    local canClick = self:_CheckCanOneKeyReward()

    if canClick then
        self:Lock("UIQuestGet")
        self:StartTask(self.OngetAllBtnOnClick, self)
    end
end

function UIQuestDailyItem:_CheckCanOneKeyReward()
    local canClick = false

    for key, value in pairs(self._questList) do
        local questInfo = value
        if questInfo:QuestInfo().status == QuestStatus.QUEST_Completed then
            canClick = true
            break
        end
    end

    if not canClick then
        ---@type UIQuestDailyActivePointItem[]
        local aps = self._activePointPool:GetAllSpawnList()
        for i = 1, table.count(aps) do
            local canGetActive = aps[i]:GetActiveState()
            if canGetActive then
                canClick = true
                break
            end
        end
    end

    if not canClick then
        if self._weekQuest then
            if self._weekAwardStatus == QuestStatus.QUEST_Completed then
                canClick = true
            end
        end
    end

    return canClick
end

function UIQuestDailyItem:OngetAllBtnOnClick(TT)
    local res, msg = self._questModule:TakeOneKeyReward(TT, self._type)
    self:UnLock("UIQuestGet")
    if (self.uiOwner == nil) then
        return
    end
    if res:GetSucc() then
        local tempPets = {}
        local pets = msg.rewards
        self._tempMsgRewards = msg.rewards

        if #pets > 0 then
            for i = 1, #pets do
                local ispet = GameGlobal.GetModule(PetModule):IsPetID(pets[i].assetid)
                if ispet then
                    table.insert(tempPets, pets[i])
                end
            end
        end
        if #tempPets > 0 then
            self:ShowDialog(
                "UIPetObtain",
                tempPets,
                function()
                    GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
                    GameGlobal.EventDispatcher():Dispatch(
                        GameEventType.OnUIPetObtainCloseInQuest,
                        self._dispatchTypeAll
                    )
                end
            )
        else
            if table.count(msg.rewards) > 0 then
                self:ShowDialog(
                    "UIGetItemController",
                    msg.rewards,
                    function()
                        GameGlobal.EventDispatcher():Dispatch(
                            GameEventType.OnUIGetItemCloseInQuest,
                            self._dispatchTypeAll
                        )
                    end
                )
            else
                --临时只有体力这么处理
                --多个任务有的领取失败
                --@lixuesen @liusiyuan
                local tips = StringTable.Get("str_physicalpower_error_phy_add_full")
                ToastManager.ShowToast(tips)
            end
        end
    end
end
