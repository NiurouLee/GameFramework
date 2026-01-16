require("ui_side_enter_center_content_base")

---@class UIActivityReturnSystemMainContent : UISideEnterCenterContentBase
_class("UIActivityReturnSystemMainContent", UISideEnterCenterContentBase)
UIActivityReturnSystemMainContent = UIActivityReturnSystemMainContent

function UIActivityReturnSystemMainContent:DoInit(params)
    self._campaignType = params and params.campaign_type
    self._componentIds = params and params.component_ids or {}
    self._campaignId = params and params.campaign_id

    -- self._campaignType = ECampaignType.CAMPAIGN_TYPE_BACK_PHASE_II
    self._campaignType = UIActivityReturnSystemHelper.GetCampaignType()

    ---@type UIActivityCampaign
    self._campaign = self._data
end

function UIActivityReturnSystemMainContent:DoShow(uiParams)
    -- 清除 new
    self:StartTask(function(TT)
        self._campaign:ClearCampaignNew(TT)
    end)

    -- 活动开启时才拉价格
    --- @type BuyGiftComponent
    local component = UIActivityReturnSystemHelper.GetComponentByTabName(self._campaign, "gift", 1)
    component:GetAllGiftLocalPrice()

    ---------------------------------------------------
    -- 记录打开时的状态，如果活动中心后续优化销毁未打开的TabPage，重新加载时会因没有参数而有问题
    -- 现在使用活动中心的 single_mode 后，不允许切换其他页签，不保存也不会有问题
    self.isBoostIntro = self.isBoostIntro or (uiParams and uiParams[1])

    -- 切换别的活动，回来重新显示时，不计算首个页签
    local curIdx = self._tabIndex or self:_CalcFirstIndex()

    ---------------------------------------------------
    self:InitWidget()

    self:_SetCharImgText()
    self:_SetRemainingTime_Main()

    self:_InitTabBtns()
    self:_OnTabBtnSelected(curIdx)
    self:ShowHideTabBtns()

    -- self:_CheckRedPointAll() -- 在 _SetTabPageSelected() 中调用
    self:_AttachEvents()
end

function UIActivityReturnSystemMainContent:DoHide()
    UIWidgetHelper.ClearWidgets(self, "_tipsPool")

    self:_DetachEvents()
end

function UIActivityReturnSystemMainContent:DoDestroy()
end

-----------------------------------------------------------------------------------

function UIActivityReturnSystemMainContent:_ForceRefresh()
    if self._refreshTaskID ~= nil then
        return
    end

    self._refreshTaskID = self:StartTask(function(TT)
            local res = AsyncRequestRes:New()
            res:SetSucc(true)
            self._campaign:ReLoadCampaignInfo_Force(TT, res)
            if res and res:GetSucc() then
                self:_Refresh()
            end
            self._refreshTaskID = nil
        end,
        self
    )
end

function UIActivityReturnSystemMainContent:_Refresh()
end

function UIActivityReturnSystemMainContent:_CalcFirstIndex()
    local curIdx = 1

    --- @type PlayerBackComponent
    local component = UIActivityReturnSystemHelper.GetComponentByTabName(self._campaign, "welecome", 1)
    if component:IsRecvBackReward() then
        self._const_QuestPageIndex = UIActivityReturnSystemHelper.GetTabIndexByTabName("quest")
        curIdx = self._const_QuestPageIndex -- 领取过奖励，跳转到任务页签
    end

    if self.isBoostIntro then
        self._const_BoostPageIndex = UIActivityReturnSystemHelper.GetTabIndexByTabName("boost")
        curIdx = self._const_BoostPageIndex -- 传参进入，强制跳转助力页签
    end
    return curIdx
end

--设置活动页签等信息
function UIActivityReturnSystemMainContent:InitWidget()
    self._tabPages = {
        self:_GetSpawnComponent("tabPageWelecome", "UIActivityReturnSystemWelecome"),
        self:_GetSpawnComponent("tabPageLogin", "UIActivityReturnSystemTabLogin"),
        self:_GetSpawnComponent("tabPageQuest", "UIActivityReturnSystemTabQuest"),
        self:_GetSpawnComponent("tabPageShop", "UIActivityReturnSystemTabShop"),
        self:_GetSpawnComponent("tabPageGift", "UIActivityReturnSystemTabGift"),
        self:_GetSpawnComponent("tabPageBoost", "UIActivityReturnSystemTabBoost")
    }
    self._flexibleWidgetName = {
        { "FlexibleGroup" }, -- charImg
        { "FlexibleGroup2" }, -- time tab
        { "FlexibleGroup2" },
        { "FlexibleGroup" },
        { "FlexibleGroup" },
        { "FlexibleGroup2" }
    }
    self.strID = {
        "str_return_system_btn_welecome",
        "str_return_system_btn_sign",
        "str_return_system_btn_mission",
        "str_return_system_btn_shop",
        "str_return_system_btn_gift",
        "str_return_system_btn_assistance"
    }
end

function UIActivityReturnSystemMainContent:_SetRemainingTime_Main()
    -- 活动结束时间服务器计算后调整
    local sample = self._campaign and self._campaign:GetSample()
    local endTime = sample and sample.end_time or 0
    local descId = "str_return_system_time_main"
    self:_SetRemainingTime("remainingTimePool", descId, endTime)
end

function UIActivityReturnSystemMainContent:_SetRemainingTime_Tab(descId, endTime)
    self:_SetRemainingTime("remainingTimePool_Tab", descId, endTime)
end

function UIActivityReturnSystemMainContent:_SetRemainingTime(widgetName, descId, endTime)
    ---@type UIActivityCommonRemainingTime
    local obj = UIWidgetHelper.SpawnObject(self, widgetName, "UIActivityCommonRemainingTime")

    obj:SetCustomTimeStr_Common_1()

    obj:SetExtraRollingText()
    obj:SetAdvanceText(descId)
    obj:SetData(endTime, nil, nil)
end

function UIActivityReturnSystemMainContent:_SetCharImgText()
    ---@type UILocalizationText
    local charImg_title = self:GetUIComponent("UILocalizationText", "charImg_title")
    ---@type UILocalizationText
    local charImg_desc = self:GetUIComponent("UILocalizationText", "charImg_desc")

    local petId = 1500331 -- 薇丝
    local cfgv = Cfg.cfg_pet[petId]
    if not cfgv then
        Log.fatal("### no pet in cfg_pet.petId=", petId)
        return
    end

    charImg_title:SetText(StringTable.Get(cfgv.Name))

    local content = HelperProxy:GetInstance():ReplacePlayerName(StringTable.Get("str_return_system_greetings"))
    charImg_desc:SetText(content)
end

--region tab btn
function UIActivityReturnSystemMainContent:_InitTabBtns()
    self._tabBtnPool = self:GetUIComponent("UISelectObjectPath", "tabBtnPool")
    self._tabBtnPool:SpawnObjects("UIActivityReturnSystemTabBtn", table.count(self.strID))

    ---@type UIActivityReturnSystemTabBtn[]
    local list = self._tabBtnPool:GetAllSpawnList()
    for i, v in ipairs(list) do
        v:SetData(
            i,
            self.strID,
            function(idx)
                self:_OnTabBtnSelected(idx)
            end
        )
    end
end

function UIActivityReturnSystemMainContent:_SetTabBtnSelected()
    ---@type UIActivityReturnSystemTabBtn[]
    local list = self._tabBtnPool:GetAllSpawnList()
    for i, v in ipairs(list) do
        v:SetSelected(self._tabIndex == i)
    end
end

function UIActivityReturnSystemMainContent:_SetTabBtnRedPoint()
    ---@type UIActivityReturnSystemTabBtn[]
    local list = self._tabBtnPool:GetAllSpawnList()
    for i, v in ipairs(list) do
        local red = false
        local ids = UIActivityReturnSystemHelper.GetComponentIdByTabIndex(i)
        for _, vv in ipairs(ids) do
            local show = self._campaign:CheckComponentRed(vv)
            red = red or show
        end

        local shopIndex = UIActivityReturnSystemHelper.GetTabIndexByTabName("shop")
        if i == shopIndex then -- 回流二期商店特殊处理
            red = UIActivityReturnSystemHelper.GetShopRedPoint()
        end
        v:SetRedPoint(red)
    end
end

function UIActivityReturnSystemMainContent:_SetTabPageSelected()
    for i, v in ipairs(self._tabPages) do
        v:GetGameObject():SetActive(i == self._tabIndex)
    end

    self._tabPages[self._tabIndex]:SetData(
        self._campaign,
        function(endTime, hide) -- 设置倒计时 回调
            if not hide then
                local strDescId = {
                    nil,
                    "str_return_system_time_login",
                    "str_return_system_time_quest",
                    nil,
                    nil,
                    "str_return_system_time_boost"
                }
                local descId = strDescId[self._tabIndex]
                if not string.isnullorempty(descId) then
                    self:_SetRemainingTime_Tab(descId, endTime)
                end

                for _, v in pairs(self._flexibleWidgetName[self._tabIndex]) do
                    self:GetGameObject(v):SetActive(true)
                end
            else
                for _, v in pairs(self._flexibleWidgetName[self._tabIndex]) do
                    self:GetGameObject(v):SetActive(false)
                end
            end
        end,
        function(matid, pos) -- tips
            UIWidgetHelper.SetAwardItemTips(self, "_tipsPool", matid, pos)
        end,
        self.isBoostIntro
    )

    -- Shop
    local shopIndex = UIActivityReturnSystemHelper.GetTabIndexByTabName("shop")
    self._tabPages[shopIndex]:SetTopTips(
        function(id, go) -- topTips
            local topTips = UIWidgetHelper.SpawnObject(self, "_topTips", "UITopTipsContext")
            topTips:SetData(id, go)
        end
    )

    self:_CheckRedPointAll()
end

function UIActivityReturnSystemMainContent:_OnTabBtnSelected(index)
    if index == self._tabIndex then
        return
    end
    local preIndex = self._tabIndex
    self._tabIndex = index

    local pre = preIndex and self._flexibleWidgetName[preIndex][1]
    local next = index and self._flexibleWidgetName[index][1]
    -- 不同种类时需要播放切换，同为倒计时种类时需要切换
    local change = (pre and next and pre ~= next) or (pre == "FlexibleGroup2")
    if change then
        local preAnimName, preDuration = self:_GetAnimInfo(pre, "out")
        local nextAnimName, nextDuration = self:_GetAnimInfo(next, "in")
        UIWidgetHelper.PlayAnimation(self, pre, preAnimName, preDuration, function()
            self:GetGameObject(pre):SetActive(false)
            self:GetGameObject(next):SetActive(true)
            UIWidgetHelper.SetAnimationPlay(self, next, nextAnimName)
            self:_SetTabBtnSelected()
            self:_SetTabPageSelected()
        end)
    else
        local objs = UIWidgetHelper.GetObjGroupByWidgetName(self, self._flexibleWidgetName)
        UIWidgetHelper.SetObjGroupShow(objs, index)
        self:_SetTabBtnSelected()
        self:_SetTabPageSelected()
    end
end

function UIActivityReturnSystemMainContent:_GetAnimInfo(name, type)
    local tb = {}
    tb["FlexibleGroup"] = {
        ["in"] = { "uieff_Return_left_in", 250 },
        ["out"] = { "uieff_Return_left_out", 167 }
    }
    tb["FlexibleGroup2"] = {
        ["in"] = { "uieff_TimeTab_in", 267 },
        ["out"] = { "uieff_TimeTab_out", 200 }
    }
    return tb[name][type][1], tb[name][type][2]
end

--endregion

function UIActivityReturnSystemMainContent:ShowHideTabBtns()
    if self.isBoostIntro then
        ---@type UIActivityReturnSystemTabBtn[]
        local list = self._tabBtnPool:GetAllSpawnList()
        for i, v in ipairs(list) do
            if i ~= self._const_BoostPageIndex then
                v:ShowHideRoot(self.isBoostIntro)
            end
        end
    end
end

--region Event Callback

function UIActivityReturnSystemMainContent:StoryBtnOnClick(go)
    local storyId = UIActivityHelper.GetCampaignFirstEnterStoryID(self._campaign, 1)
    if storyId then
        GameGlobal.UIStateManager():ShowDialog("UIStoryController", storyId)
    end
end

function UIActivityReturnSystemMainContent:IntroBtnOnClick(go)
    self:ShowDialog("UIActivityReturnSystemIntro")
end

--endregion

--region AttachEvent

function UIActivityReturnSystemMainContent:_AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:AttachEvent(GameEventType.CampaignComponentStepChange, self._OnComponentStepChange)
    self:AttachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
    self:AttachEvent(GameEventType.QuestUpdate, self._OnQuestUpdate)
end

function UIActivityReturnSystemMainContent:_DetachEvents()
    self:DetachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:DetachEvent(GameEventType.CampaignComponentStepChange, self._OnComponentStepChange)
    self:DetachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
    self:DetachEvent(GameEventType.QuestUpdate, self._OnQuestUpdate)
end

function UIActivityReturnSystemMainContent:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

function UIActivityReturnSystemMainContent:_OnComponentStepChange(campaign_id, component_id, component_step)
    if self._campaign then
        if (self._campaign._id == campaign_id) then
            self:_CheckRedPointAll()
        end
    end
end

function UIActivityReturnSystemMainContent:_CheckRedPointAll()
    self:_SetTabBtnRedPoint()
end

function UIActivityReturnSystemMainContent:OnUIGetItemCloseInQuest(type)
    self:_SetTabPageSelected()

    -- 因为需要主动通知活动主界面刷新红点
    GameGlobal.EventDispatcher():Dispatch(GameEventType.CampaignComponentStepChange, self._campaign._id, nil, nil)
end

function UIActivityReturnSystemMainContent:_OnQuestUpdate()
    self:_SetTabPageSelected()
end

--endregion

function UIActivityReturnSystemMainContent:_GetSpawnComponent(widgetName, className)
    local sop = self:GetUIComponent("UISelectObjectPath", widgetName)
    local obj = sop:SpawnObject(className)
    return obj
end