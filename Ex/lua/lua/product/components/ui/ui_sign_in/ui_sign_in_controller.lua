---@class UISignInController:UIController
_class("UISignInController", UIController)
UISignInController = UISignInController

function UISignInController:LoadDataOnEnter(TT, res, uiParams)
    ---@type SignInModule
    self._module = self:GetModule(SignInModule)

    if uiParams[1] then
        self._showType = uiParams[1]
    else
        self._showType = UISignInShowType.EVERYDAY
    end

    self._str2anim = {
        ["OnShow"] = "uieff_SignIn_In",
        ["OnHide"] = "uieff_SignIn_Out",
        ["ShowEveryDayInfo"] = "uieff_SignIn_SwitchToDaily",
        ["ShowTotalInfo"] = "uieff_SignIn_SwitchToTotal"
    }

    local resState
    local result, msg = self._module:GetCurMonthData(TT)
    if result:GetSucc() then
        resState = true
        ---@type SignInBaseInfo
        self._data = msg.sign_in_base_info
        self._currentDay = self._data.RoleSignInState.sign_in_days
        self._currentDaySignIn = self._module:IsSignInToday()
    else
        resState = false
    end

    if resState then
        local res2, msg2 = self._module:TotalLoginReq(TT)
        if res2:GetSucc() then
            ---@type table<number,TotalLoginInfo>
            self._totalData = msg2.total_login_info
            self._currentTotalDay = msg2.nTotalLoginDays

            resState = true
        else
            resState = false
        end
    end

    res:SetSucc(resState)
end

function UISignInController:OnShow(uiParams)
    self:_GetComponents()

    self._error2str = {
        [SIGN_IN_RESULT_CODE.SIGN_IN_INVALID] = "str_sign_in_SIGN_IN_INVALID",
        [SIGN_IN_RESULT_CODE.SIGN_IN_MON_SIGN_DATA_INVALID] = "str_sign_in_SIGN_IN_MON_SIGN_DATA_INVALID",
        [SIGN_IN_RESULT_CODE.SIGN_IN_TODAY_IS_SIGN] = "str_sign_in_SIGN_IN_TODAY_IS_SIGN",
        [SIGN_IN_RESULT_CODE.SIGN_IN_FULL] = "str_sign_in_SIGN_IN_FULL",
        [SIGN_IN_RESULT_CODE.SIGN_IN_NOT_SIGN_CANT_RE_SIGN] = "str_sign_in_SIGN_IN_NOT_SIGN_CANT_RE_SIGN",
        [SIGN_IN_RESULT_CODE.SIGN_IN_RE_SIGN_VIG_POINT] = "str_sign_in_SIGN_IN_RE_SIGN_VIG_POINT",
        [SIGN_IN_RESULT_CODE.SIGN_IN_TOTAL_LOGIN_DAYS_INVALID] = "str_sign_in_SIGN_IN_TOTAL_LOGIN_DAYS_INVALID",
        [SIGN_IN_RESULT_CODE.SIGN_IN_TOTAL_LOGIN_IS_RECVED] = "str_sign_in_SIGN_IN_TOTAL_LOGIN_IS_RECVED",
        [SIGN_IN_RESULT_CODE.SIGN_IN_TOTAL_LOGIN_NOT_ENOUGH] = "str_sign_in_SIGN_IN_TOTAL_LOGIN_NOT_ENOUGH",
        [SIGN_IN_RESULT_CODE.SIGN_IN_IS_RE_SIGNED] = "str_sign_in_SIGN_IN_IS_RE_SIGNED"
    }

    local atlas = self:GetAsset("UISignIn.spriteAtlas", LoadType.SpriteAtlas)

    self._everyDayBg1 = atlas:GetSprite("sign_qiandao_frame1")
    self._everyDayBg2 = atlas:GetSprite("sign_qiandao_frame8")

    self._petModule = GameGlobal.GetModule(PetModule)
    self._svrTimeModule = self:GetModule(SvrTimeModule)
    self._itemCountPerRow = 1
    self.type2btnStr = {
        [UISignInShowType.EVERYDAY] = "str_sign_in_btn_str_sign_in",
        [UISignInShowType.TOTAL] = "str_sign_in_btn_str_total"
    }
    self._activeMakeUpValue = self._module:ReSignInNeedVigPoint()

    if self._showType == UISignInShowType.EVERYDAY then
        -- 今日是否已经签到了
        self._currentDaySignIn = self._module:IsSignInToday()
        self:ShowEveryDayInfo()

        --先刷下时间
        local nextSignInTime = self._module:GetNextSignInTime()
        local currTime = math.floor(self._svrTimeModule:GetServerTime() * 0.001)
        local timeStamp = nextSignInTime - currTime
        if timeStamp < 0 then
            timeStamp = 0
        end
        local timeStr = HelperProxy:GetInstance():FormatTime(timeStamp)
        self._timeDownText:SetText(timeStr)

        if self._currentDaySignIn then
            self:TimeDown()
        else
            --检查签到
            self:CheckAndSignIn()
        end
    else
        self:TimeDown()

        self:ShowTotalInfo()
    end

    self:_OnValue()

    self:BtnState()

    self:Lock("UISignInController:OnShow")
    self._anim:Play(self._str2anim["OnShow"])
    self:StartTask(
        function(TT)
            YIELD(TT, 433)
            self:UnLock("UISignInController:OnShow")
        end,
        self
    )
    self:ShowActBox()
end
--
function UISignInController:ShowActBox()
    local startTime,endTime = self:GetCheckTimeStr(self._currentDay)
    if startTime then
        self._startTime = startTime
        self._endTime = endTime

        self._actBox:SetActive(true)
        local month = self._data.nMonth

        local tips = StringTable.Get("str_sign_in_act_box_tips",StringTable.Get("str_sign_in_month_by_num_"..month))
        self._actBoxTips:SetText(tips)
    else
        self._actBox:SetActive(false)
    end
end
--
function UISignInController:GetCheckTimeStr(dday)
    local day = dday
    if day <= 0 then
        day = 1
    end
    local month = self._data.nMonth
    local year = self._data.nYear
    local time = "12:00:00"
    local concatList = {year,"-",month,"-",day," ",time}
    local str = table.concat(concatList)
    local cfg,startTime,endTime = self._module:GetActivityTime(str)
    return startTime,endTime
end
--
function UISignInController:ActBoxBgOnClick(go)
    self:ShowDialog("UISignInActBoxTipsController",self._endTime)
end
function UISignInController:closeBtnOnClick(go)
    self:Lock("UISignInController:OnHide")
    self._anim:Play(self._str2anim["OnHide"])
    self:StartTask(
        function(TT)
            YIELD(TT, 433)
            self:UnLock("UISignInController:OnHide")
            self:CloseDialog()
        end,
        self
    )
end

function UISignInController:_GetComponents()
    local s = self:GetUIComponent("UISelectObjectPath", "itemInfo")
    ---@type UISelectInfo
    self._tips = s:SpawnObject("UISelectInfo")

    self._anim = self:GetUIComponent("Animation", "UISignInController")

    self._totalGo = self:GetGameObject("total")
    self._everyDayGo = self:GetGameObject("everyDay")
    self._totalTr = self:GetUIComponent("Transform", "total")
    self._everyDayTr = self:GetUIComponent("Transform", "everyDay")
    self._totalCanvasGroup = self:GetUIComponent("CanvasGroup", "total")
    self._everyDayCanvasGroup = self:GetUIComponent("CanvasGroup", "everyDay")

    self._activePointTextValue = self:GetUIComponent("UILocalizationText", "activePointTextValue")

    self._activePointTipsText = self:GetUIComponent("UILocalizationText", "activePointTipsText")

    self._timeDownText = self:GetUIComponent("UILocalizationText", "timeDownText")

    self._e_title = self:GetUIComponent("UILocalizationText", "e_title")
    self._dayPool = self:GetUIComponent("UISelectObjectPath", "group")

    self._btnText = self:GetUIComponent("UILocalizationText", "btnText")

    self._eRed = self:GetGameObject("eRed")
    self._tRed = self:GetGameObject("tRed")

    self._totalLogin = self:GetUIComponent("UILocalizationText", "totalLogin")

    self._totalAwardsList = self:GetUIComponent("UIDynamicScrollView", "ScrollView")

    self._eShowBtn = self:GetGameObject("eShowBtn")
    self._tShowBtn = self:GetGameObject("tShowBtn")

    self._actBox = self:GetGameObject("actBox")
    self._actBoxTips = self:GetUIComponent("UILocalizationText","actBoxTips")
end
-------------------------------------------------------------------------------------------------------------------
--签到信息
function UISignInController:ShowEveryDayInfo(anim)
    if anim then
        self._totalCanvasGroup.alpha = 1
        self._everyDayCanvasGroup.alpha = 0
        self:Lock("UISignInController:ShowEveryDayInfo")
        self._anim:Play(self._str2anim["ShowEveryDayInfo"])
        self:StartTask(
            function(TT)
                YIELD(TT, 867)
                self:UnLock("UISignInController:ShowEveryDayInfo")
            end,
            self
        )
    else
        self._totalCanvasGroup.alpha = 0
        self._everyDayCanvasGroup.alpha = 1
    end

    self._everyDayTr:SetAsLastSibling()

    --当前月份
    self._currentMonth = self._data.nMonth

    self:TodayActive()

    self:ShowDays()

    self:ShowTitle()
end
--签到
function UISignInController:CheckAndSignIn(total)
    self:Lock("UISignInController:CheckAndSignIn")
    GameGlobal.TaskManager():StartTask(self.OnCheckAndSignIn, self, total)
end
function UISignInController:OnCheckAndSignIn(TT, total)
    local res, msg = self._module:SignInTodayReq(TT, false)
    self:UnLock("UISignInController:CheckAndSignIn")
    if not self.view then
        Log.debug("###[UISignInController] not view return !")
        return
    end
    if res and res:GetSucc() then
        ---@type SignInBaseInfo
        self._data = msg.sign_in_base_info
        local activityAwards = msg.act_assets
        self._currentDay = self._data.RoleSignInState.sign_in_days
        -- 今日是否已经签到了
        self._currentDaySignIn = self._module:IsSignInToday()
        Log.debug("###[UISignInController] OnCheckAndSignIn succ ! day --> ", self._currentDay)

        --刷信息,先把下月信息刷出来，播动画用
        self:ShowEveryDayInfo()

        self:Lock("PlaySignInAnim")
        --拿到当前的天数，播item的Get动画

        local itemPrefab = self._items[self._currentDay]
        itemPrefab:ShowGetting(true)
        itemPrefab:PlayAnim()
        -- 200+1300
        YIELD(TT, 1500)

        if not self.view then
            Log.debug("###[UISignInController] not view return !")
            return
        end
        
        itemPrefab:ShowGetting(false)
        self:UnLock("PlaySignInAnim")

        --播动画先
        self:PlayAnim(activityAwards)
        --再刷信息
        self:ShowEveryDayInfo()

        self:TimeDown()

        self:BtnState()
    else
        --失败
        local errorCode = res:GetResult()
        Log.error("###[UISignInController] CheckAndSignIn fail ! result --> ", errorCode)
        ToastManager.ShowToast(StringTable.Get(self._error2str[errorCode]))
    end

    if total then
        self:Lock("UISignInController:CheckAndSignIn-2")

        local res2, msg2 = self._module:TotalLoginReq(TT)
        self:UnLock("UISignInController:CheckAndSignIn-2")

        if res2:GetSucc() then
            ---@type table<number,TotalLoginInfo>
            self._totalData = msg2.total_login_info
            self._currentTotalDay = msg2.nTotalLoginDays

            --刷新累计登录界面
            self:TotalLoginDayCount()

            self:ShowTotalAwards()

            self:BtnState()
        else
            --失败
            local errorCode = res2:GetResult()
            Log.error("###[UISignInController] CheckAndSignIn fail ! result --> ", errorCode)
            ToastManager.ShowToast(StringTable.Get(self._error2str[errorCode]))
        end
    end
    self:ShowActBox()
end
--签到动画
function UISignInController:PlayAnim(activityAwards)
    local awardList = {}
    local awards = self._days[self._currentDay].Items
    table.insert(awardList, awards)

    if activityAwards then
        if #activityAwards > 0 then
            for i = 1, #activityAwards do
                local award = activityAwards[i]
                table.insert(awardList, award)
            end
        end
    end

    local tempPets = {}
    if #awardList > 0 then
        for i = 1, #awardList do
            local ispet = self._petModule:IsPetID(awardList[i].assetid)
            if ispet then
                table.insert(tempPets, awardList[i])
            end
        end
    end
    if #tempPets > 0 then
        self:ShowDialog(
            "UIPetObtain",
            tempPets,
            function()
                GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
                self:ShowDialog("UIGetItemController", awardList)
            end
        )
    else
        self:ShowDialog("UIGetItemController", awardList)
    end
end
--显示签到items
function UISignInController:ShowDays()
    ---@type UISignInAwardData[]
    self._days = {}
    ---@type SignInOneDayInfo
    local awardList = self._data.MonthInfo

    local canMakeUp = false
    for i = 1, #awardList do
        local award = awardList[i]

        local got = (i <= self._currentDay)

        local itemCanMakeUp = false
        if not got and not canMakeUp and self._module:IsReSignInToday() then
            itemCanMakeUp = true
            canMakeUp = true
        end

        local data = UISignInAwardData:New(i, award.nDay, award.reward, award.reward_is_good, got, itemCanMakeUp)
        table.insert(self._days, data)
    end

    self._dayPool:SpawnObjects("UISignInEveryDayItem", 35)
    ---@type UISignInEveryDayItem[]
    self._items = self._dayPool:GetAllSpawnList()
    for i = 1, #self._items do
        local dayData
        if i <= table.count(self._days) then
            dayData = self._days[i]
        else
            dayData = nil
        end
        self._items[i]:SetData(
            dayData,
            self._everyDayBg1,
            self._everyDayBg2,
            self._currentDay,
            function()
                self:CheckAndSignIn()
            end,
            function(matid, pos)
                self:ShowItemInfo(matid, pos)
            end,
            function(idx)
                self:MakeUpDay(idx)
            end,
            function(day)
                return self:CheckActBoxByDay(day)
            end
        )
    end
end
--
function UISignInController:CheckActBoxByDay(day)
    return self:GetCheckTimeStr(day)
end
---补签
function UISignInController:MakeUpDay(idx)
    self:Lock("UISignInController:MakeUpDay(idx)")
    GameGlobal.TaskManager():StartTask(self.OnMakeUpDay, self, idx)
end
function UISignInController:OnMakeUpDay(TT, idx)
    -- local day = self._days[idx].Day
    local res, msg = self._module:SignInTodayReq(TT, true)
    self:UnLock("UISignInController:MakeUpDay(idx)")
    if res and res:GetSucc() then
        self._data = msg.sign_in_base_info
        local activityAwards = msg.act_assets
        self._currentDay = self._data.RoleSignInState.sign_in_days
        self._currentDaySignIn = self._module:IsSignInToday()

        self:TodayActive()

        self:MakeUpAnim(idx,activityAwards)
    else
        Log.fatal("###[UISignInController] self._module:MakeUpDay fail ! error --> ", res:GetResult())
    end
end
--补签动画
function UISignInController:MakeUpAnim(idx,activityAwards)
    local data = self._days[idx]
    local awards = {}
    local tempAwards = data.Items
    table.insert(awards, tempAwards)
    if activityAwards then
        if #activityAwards > 0 then
            for i = 1, #activityAwards do
                local award = activityAwards[i]
                table.insert(awards, award)
            end
        end
    end
    local tempPets = {}
    if #awards > 0 then
        for i = 1, #awards do
            local ispet = self._petModule:IsPetID(awards[i].assetid)
            if ispet then
                table.insert(tempPets, awards[i])
            end
        end
    end
    if #tempPets > 0 then
        self:ShowDialog(
            "UIPetObtain",
            tempPets,
            function()
                GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
                self:ShowDialog("UIGetItemController", awards)
            end
        )
    else
        self:ShowDialog("UIGetItemController", awards)
    end

    local item = self._items[idx]
    item:MakeUpAnim()

    self:ShowDays()
end

--倒计时
function UISignInController:TimeDown()
    self:ShowTime()
    if self._timeEvent then
        GameGlobal.Timer():CancelEvent(self._timeEvent)
        self._timeEvent = nil
    end
    self._timeEvent =
        GameGlobal.Timer():AddEventTimes(
        1000,
        TimerTriggerCount.Infinite,
        function()
            self:ShowTime()
        end
    )
end
function UISignInController:ShowTime()
    local nextSignInTime = self._module:GetNextSignInTime()
    local currTime = math.floor(self._svrTimeModule:GetServerTime() * 0.001)
    local timeStamp = nextSignInTime - currTime
    if timeStamp >= 0 then
        if self._showType == UISignInShowType.EVERYDAY then
            local timeStr = HelperProxy:GetInstance():FormatTime(timeStamp)
            self._timeDownText:SetText(timeStr)
        end
    else
        -- 今日是否已经签到了
        self._currentDaySignIn = self._module:IsSignInToday()
        if self._currentDaySignIn then
            return
        end
        if self._timeEvent then
            GameGlobal.Timer():CancelEvent(self._timeEvent)
            self._timeEvent = nil
        end
        --请求刷新数据（签到和累计登录的）
        if self._showType == UISignInShowType.EVERYDAY then
            --调一下签到，然后刷信息
            self:CheckAndSignIn(true)
        else
            self:RefreshData()
        end
    end
end

function UISignInController:RefreshData()
    GameGlobal.TaskManager():StartTask(self.OnRefreshData, self)
end

function UISignInController:OnRefreshData(TT)
    self:Lock("UISignInController:OnRefreshData")
    local res1, msg1 = self._module:GetCurMonthData(TT)
    self:UnLock("UISignInController:OnRefreshData")
    if res1:GetSucc() then
        ---@type SignInBaseInfo
        self._data = msg1.sign_in_base_info
        self._currentDay = self._data.RoleSignInState.sign_in_days
        self._currentDaySignIn = self._module:IsSignInToday()
    else
        --失败
        local errorCode = res1:GetResult()
        Log.error("###[UISignInController] OnRefreshData fail ! result --> ", errorCode)
        ToastManager.ShowToast(StringTable.Get(self._error2str[errorCode]))
    end

    self:Lock("UISignInController:OnRefreshData-2")
    local res2, msg2 = self._module:TotalLoginReq(TT)
    self:UnLock("UISignInController:OnRefreshData-2")
    if res2:GetSucc() then
        ---@type table<number,TotalLoginInfo>
        self._totalData = msg2.total_login_info
        self._currentTotalDay = msg2.nTotalLoginDays

        self:ShowTotalInfo()

        self:TimeDown()

        self:BtnState()
    else
        --失败
        local errorCode = res2:GetResult()
        Log.error("###[UISignInController] OnRefreshData fail ! result --> ", errorCode)
        ToastManager.ShowToast(StringTable.Get(self._error2str[errorCode]))
    end
    self:ShowActBox()
end

--显示活跃度
function UISignInController:TodayActive()
    local questModule = self:GetModule(QuestModule)
    local activePoint = questModule:GetDailyQuestVigorous()

    self._activePointTextValue:SetText(activePoint)
    self._activePointTipsText:SetText(StringTable.Get("str_sign_in_make_up_tips", self._activeMakeUpValue))
end
--显示月份
function UISignInController:ShowTitle()
    self._e_title:SetText(StringTable.Get("str_sign_in_current_month", self._currentMonth))
end

---------------------------------------------------------------------------------------------------------
--累计登录信息
function UISignInController:ShowTotalInfo(anim)
    if anim then
        self._totalCanvasGroup.alpha = 0
        self._everyDayCanvasGroup.alpha = 1
        self:Lock("UISignInController:ShowTotalInfo")
        self._anim:Play(self._str2anim["ShowTotalInfo"])
        self:StartTask(
            function(TT)
                YIELD(TT, 867)
                self:UnLock("UISignInController:ShowTotalInfo")
            end,
            self
        )
    else
        self._totalCanvasGroup.alpha = 1
        self._everyDayCanvasGroup.alpha = 0
    end
    self._totalTr:SetAsLastSibling()

    self:TotalLoginDayCount()

    self:ShowTotalAwards()
end

--累计天数
function UISignInController:TotalLoginDayCount()
    self._totalLogin:SetText(StringTable.Get("str_sign_in_day_str", self._currentTotalDay))
end
--天数奖励
function UISignInController:ShowTotalAwards()
    ---@type UITotalAwardData[]
    self._totalAwardsData = {}

    local awardList = {}
    for i, v in HelperProxy:GetInstance():pairsByKeys(self._totalData) do
        table.insert(awardList, v)
    end

    for i = 1, #awardList do
        local award = awardList[i]

        local data = UITotalAwardData:New(i, award.nDay, award.Reward, award.bIsAccept)
        table.insert(self._totalAwardsData, data)
    end

    self._listCount = table.count(self._totalAwardsData)

    if self._scrollViewInited then
        self._totalAwardsList:SetListItemCount(self._listCount)
        self._totalAwardsList:RefreshAllShownItem()
    else
        self:_InitTotalScrollView()
        self._scrollViewInited = true
    end
    --list的move规则
    self:MoveTotalList()
end
function UISignInController:_InitTotalScrollView()
    if self._totalListInited then
        self._totalAwardsList:SetListItemCount(self._listCount)
    else
        self._totalAwardsList:InitListView(
            self._listCount,
            function(scrollView, index)
                return self:_InitScrollView(scrollView, index)
            end
        )
        self._totalListInited = true
    end
end
function UISignInController:MoveTotalList()
    local moveIdx = 0
    for i = 1, #self._totalAwardsData do
        local data = self._totalAwardsData[i]
        if not data.Got then
            if data.DayCount <= self._currentTotalDay then
                moveIdx = i - 1
                break
            end
        end
    end
    self._totalAwardsList:MovePanelToItemIndex(moveIdx, 0)
end
function UISignInController:_InitScrollView(scrollView, index)
    if index < 0 then
        return nil
    end
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UISignInTotalItem", self._itemCountPerRow)
    end
    ---@type UISignInTotalItem[]
    local rowList = rowPool:GetAllSpawnList()
    for i = 1, self._itemCountPerRow do
        local item = rowList[i]
        local itemIndex = index * self._itemCountPerRow + i
        self:_ShowTotalAwardItem(item, itemIndex)
    end
    return item
end
---@param item UISignInTotalItem
function UISignInController:_ShowTotalAwardItem(item, idx)
    local data = self._totalAwardsData[idx]
    item:SetData(
        data,
        self._currentTotalDay,
        function(matid, pos)
            self:ShowItemInfo(matid, pos)
        end,
        function(days)
            self:GetTotalAward(days)
        end
    )
end
--累计天数领奖
function UISignInController:GetTotalAward(days)
    self:Lock("UISignInController:GetTotalAward(id)")
    GameGlobal.TaskManager():StartTask(self.OnGetTotalAward, self, days)
end
function UISignInController:OnGetTotalAward(TT, days)
    local res, returnDays = self._module:RecvTotalLoginRewardReq(TT, days)
    self:UnLock("UISignInController:GetTotalAward(id)")
    if res and res:GetSucc() then
        local data
        for i = 1, #self._totalAwardsData do
            if self._totalAwardsData[i].DayCount == returnDays then
                data = self._totalAwardsData[i]
                break
            end
        end
        data.Got = true
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnTotalAwardGot, returnDays, data)
        self:BtnState()

        local awards = data.Items
        local tempPets = {}
        if #awards > 0 then
            for i = 1, #awards do
                local ispet = self._petModule:IsPetID(awards[i].assetid)
                if ispet then
                    table.insert(tempPets, awards[i])
                end
            end
        end
        if #tempPets > 0 then
            self:ShowDialog(
                "UIPetObtain",
                tempPets,
                function()
                    GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
                    self:ShowDialog("UIGetItemController", awards)
                end
            )
        else
            self:ShowDialog("UIGetItemController", awards)
        end
    else
        Log.fatal("###[UISignInController] self._module:GetTotalAward fail ! error --> ", res:GetResult())
    end
end
---------------------------------------------------------------------------------------------------------------
function UISignInController:eBtnOnClick(go)
    if self._showType ~= UISignInShowType.EVERYDAY then
        self._showType = UISignInShowType.EVERYDAY
        self:OnButtonOnClickEnd()
    end
end
function UISignInController:tBtnOnClick(go)
    if self._showType ~= UISignInShowType.TOTAL then
        self._showType = UISignInShowType.TOTAL
        self:OnButtonOnClickEnd()
    end
end
function UISignInController:ButtonOnClick(go)
    if self._showType == UISignInShowType.EVERYDAY then
        self._showType = UISignInShowType.TOTAL
    else
        self._showType = UISignInShowType.EVERYDAY
    end

    self:OnButtonOnClickEnd()

    --刷状态两个都刷，开始时候，不用打开页签刷指定的
    -- self:Lock("UISignInController:ButtonOnClick")
    -- GameGlobal.TaskManager():StartTask(self.OnButtonOnClick, self)
end

function UISignInController:OnButtonOnClick(TT)
    if self._showType == UISignInShowType.EVERYDAY then
        local result, msg = self._module:GetCurMonthData(TT)
        self:UnLock("UISignInController:ButtonOnClick")
        if result:GetSucc() then
            ---@type SignInBaseInfo
            self._data = msg.sign_in_base_info

            self:OnButtonOnClickEnd()
        else
            local errorCode = result:GetResult()
            Log.error("###[UISignInController] OnButtonOnClick --> GetCurMonthData fail ! result --> ", errorCode)
            ToastManager.ShowToast(StringTable.Get(self._error2str[errorCode]))
        end
    else
        local result, msg = self._module:TotalLoginReq(TT)
        self:UnLock("UISignInController:ButtonOnClick")
        if result:GetSucc() then
            ---@type table<number,TotalLoginInfo>
            self._totalData = msg.total_login_info

            self._currentTotalDay = msg.nTotalLoginDays

            self:OnButtonOnClickEnd()
        else
            local errorCode = result:GetResult()
            Log.error("###[UISignInController] OnButtonOnClick --> GetCurMonthData fail ! result --> ", errorCode)
            ToastManager.ShowToast(StringTable.Get(self._error2str[errorCode]))
        end
    end
end
function UISignInController:OnButtonOnClickEnd()
    if self._showType == UISignInShowType.EVERYDAY then
        -- 今日是否已经签到了
        self._currentDaySignIn = self._module:IsSignInToday()
        self:ShowEveryDayInfo(true)

        if self._currentDaySignIn then
        else
            --检查签到
            self:CheckAndSignIn()
        end
    else
        self:ShowTotalInfo(true)
    end

    self:_OnValue()
    self:BtnState()

    self:Lock("UISignInController:OnButtonOnClickEnd")
    if self._event then
        GameGlobal.Timer():CancelEvent(self._event)
        self._event = nil
    end
    self._event =
        GameGlobal.Timer():AddEvent(
        433,
        function()
            self:UnLock("UISignInController:OnButtonOnClickEnd")
        end
    )
end

function UISignInController:OnHide()
    if self._event then
        self:UnLock("UISignInController:OnButtonOnClickEnd")
        GameGlobal.Timer():CancelEvent(self._event)
        self._event = nil
    end
end

function UISignInController:_OnValue()
    if self._showType == UISignInShowType.EVERYDAY then
        --self._totalGo:SetActive(false)
        --self._everyDayGo:SetActive(true)
        self._everyDayTr:SetAsLastSibling()
        self._totalCanvasGroup.alpha = 0
        self._everyDayCanvasGroup.alpha = 1
        self._totalCanvasGroup.blocksRaycasts = false
        self._everyDayCanvasGroup.blocksRaycasts = true
    elseif self._showType == UISignInShowType.TOTAL then
        self._totalTr:SetAsLastSibling()
        self._totalCanvasGroup.alpha = 1
        self._everyDayCanvasGroup.alpha = 0
        self._totalCanvasGroup.blocksRaycasts = true
        self._everyDayCanvasGroup.blocksRaycasts = false

    --self._totalGo:SetActive(true)
    --self._everyDayGo:SetActive(false)
    end
end
--红点信息
function UISignInController:BtnState()
    local eRed = false
    eRed = not self._currentDaySignIn

    local tRed = false
    tRed = self._module:HaveTotalLoginReward()

    self._eRed:SetActive(eRed)
    self._tRed:SetActive(tRed)

    self._eShowBtn:SetActive(self._showType == UISignInShowType.EVERYDAY)
    self._tShowBtn:SetActive(self._showType == UISignInShowType.TOTAL)
end

function UISignInController:ShowItemInfo(matid, pos)
    self._tips:SetData(matid, pos)
end

function UISignInController:OnHide()
    if self._timeEvent then
        GameGlobal.Timer():CancelEvent(self._timeEvent)
        self._timeEvent = nil
    end
end

--- @class UISignInShowType
local UISignInShowType = {
    EVERYDAY = 1,
    TOTAL = 2
}
_enum("UISignInShowType", UISignInShowType)

---@class UISignInAwardData:Object 签到奖励信息
_class("UISignInAwardData", Object)
UISignInAwardData = UISignInAwardData

---@param index 下标
---@param day 天数
---@param items 奖励
---@param good 是否是高级奖励
---@param itemGot 是否已领取
---@param canMakeUp 能否补签
function UISignInAwardData:Constructor(index, day, items, good, itemGot, canMakeUp)
    self.Index = index
    self.Day = day
    self.Items = items
    self.Good = good
    self.ItemGot = itemGot
    self.CanMakeUp = canMakeUp
end

---@class UITotalAwardData:Object 累计天数信息
_class("UITotalAwardData", Object)
UITotalAwardData = UITotalAwardData

---@param index 下标
---@param dayCount 天数
---@param items 奖励
---@param got 是否已领取
function UITotalAwardData:Constructor(index, dayCount, items, got)
    self.Index = index
    self.DayCount = dayCount
    self.Items = items
    self.Got = got
end
