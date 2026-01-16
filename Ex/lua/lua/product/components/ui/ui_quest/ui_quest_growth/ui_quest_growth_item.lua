---@class UIQuestGrowthItem:UICustomWidget
_class("UIQuestGrowthItem", UICustomWidget)
UIQuestGrowthItem = UIQuestGrowthItem

--
function UIQuestGrowthItem:_GetComponents()
    self._questBGList = self:GetUIComponent("UISelectObjectPath", "v")
    self._daysList = self:GetUIComponent("UISelectObjectPath", "daysList")

    self._bigAwardIcon = self:GetUIComponent("RawImageLoader", "bigAwardIcon")
    self._cgRect = self:GetUIComponent("RectTransform", "bigAwardIcon")

    self._bigAwardLookIcon = self:GetUIComponent("RawImageLoader", "look")

    ---@type UISelectObjectPath
    self._featherPool = self:GetUIComponent("UISelectObjectPath", "featherPool")
    self._featherPoolGo = self:GetGameObject("featherPool")

    self._hadTex = self:GetUIComponent("UILocalizationText", "hadTex")

    self._featherImage = self:GetUIComponent("Image", "bigAwardImgValue")

    self._remainingTimeTex = self:GetUIComponent("UILocalizationText", "timeRemaining")
end

--
function UIQuestGrowthItem:OnShow(uiParams)
    ---@type ATransitionComponent
    self._transition = self:GetUIComponent("ATransitionComponent", "UIQuestGrowthItem")
    ---@type UnityEngine.CanvasGroup
    self._canvasGroup = self:GetUIComponent("CanvasGroup", "UIQuestGrowthItem")
    self._canvasGroup.blocksRaycasts = false

    self:AttachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
end

--
function UIQuestGrowthItem:OnHide()
    self:DetachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)

    if self._event then
        GameGlobal.RealTimer():CancelEvent(self._event)
        self._event = nil
    end
end

--
function UIQuestGrowthItem:OnClose()
    self._isOpen = false

    if self._event then
        GameGlobal.RealTimer():CancelEvent(self._event)
        self._event = nil
    end

    self._transition:PlayLeaveAnimation(true)
    self._canvasGroup.blocksRaycasts = false
end

-- UIQuestController:QuestUpdate() 调用的刷新方法
function UIQuestGrowthItem:RefrenshList(anim)
    -- 注意：未初始化由外部事件直接刷新

    self:_SetTabSelect(self._tabIndex or self._questModule:GetLatestIndex_QuestGrowthTab())
    self:_SetDaySelect(self._dayIndex or self._questModule:GetLatestIndex_QuestGrowthDay())
    self:_SetGoalSelect(self._goalIndex or self._questModule:GetLatestIndex_QuestGrowthGoal())

    self:_Refresh_TabBtn()
    self:_Refresh_DayBtn()
    self:_Refresh_GoalBtn()

    self:_SetState(self._tabIndex)

    self:_Refresh_QuestList(anim)
    self:_Refresh_Feather()
end

--
function UIQuestGrowthItem:SetData(type)
    self._transition:PlayEnterAnimation(true)
    self._canvasGroup.blocksRaycasts = true

    self._isOpen = true

    self:_GetComponents()

    ---@type SvrTimeModule
    self._svrTimeModule = self:GetModule(SvrTimeModule)
    ---@type PetModule
    self._petModule = GameGlobal.GetModule(PetModule)
    ---@type QuestModule
    self._questModule = GameGlobal.GetModule(QuestModule)

    self._type = type

    self:_SetTabBtns()
    self:_SetDayBtn()
    self:_SetGoalBtn()

    self:RefrenshList(true)

    if EngineGameHelper.EnableAppleVerifyBulletin() then
        -- 审核服环境
        -- 临时隐藏二阶段
        for _, v in pairs(self._tabBtns) do
            v:GetGameObject():SetActive(false)
        end
    end
end

--
function UIQuestGrowthItem:_SetState(index)
    if not self._stateObj then
        self._stateObj = UIWidgetHelper.GetObjGroupByWidgetName(self, {
            { "_dayBtns", "_dayIcon" },
            { "_goalBtns", "_goalIcon" }
        })
    end
    UIWidgetHelper.SetObjGroupShow(self._stateObj, index)
end

--region TabBtn

-- 设置 tab btn
function UIQuestGrowthItem:_SetTabBtns()
    local title = {
        "str_quest_base_growth_tab_btn_title_1",
        "str_quest_base_growth_tab_btn_title_2"
    }

    ---@type UIActivityCommonTextTabBtn[]
    self._tabBtns = UIWidgetHelper.SpawnObjects(self, "_tabBtns", "UIActivityCommonTextTabBtn", #title)
    for i, v in ipairs(self._tabBtns) do
        v:SetData(
            i, -- 索引
            {
                indexWidgets = {}, -- 与索引相关的状态组
                onoffWidgets = { { "select" }, { "" } }, -- 与是否选中相关的状态组 [1] = 选中 [2] = 非选中
                lockWidgets = { { "lock" }, {} }, --- 与是否锁定相关的状态组 [1] = 锁定 [2] = 正常
                titleWidgets = { "txtTitle" }, -- 标题列表组
                titleText = StringTable.Get(title[i]), -- 标题文字
                callback = function(index, isOffBtnClick) -- 点击按钮回调
                    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
                    if isOffBtnClick then
                        self:_SetTabSelect(index)
                        self:RefrenshList(true)
                        self:_ClearNew(index)
                    end
                end,
                lockCallback = function(index) -- 锁定按钮回调
                    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
                    UIWidgetHelper.SetAnimationPlay(v, "anim", "uieff_Quest_GrowthDayItem_Lock")
                    ToastManager.ShowToast(StringTable.Get("str_quest_base_growth_tab_btn_lock"))
                    self:_ClearNew(index)
                end
            }
        )
    end
end

--
function UIQuestGrowthItem:_Refresh_TabBtn()
    if self._tabBtns then
        local lock = self._questModule:CheckQuestIILock(1)
        self._tabBtns[2]:SetLock(lock)

        local red1 = self._questModule:GetGrowthRedPointNumWithFeather()
        UIWidgetHelper.SetNewAndReds(self._tabBtns[1], nil, red1 > 0, "new", "red")

        local new2 = self._questModule:GetNewPoint(QuestType.QT_Growth)
        local red2 = self._questModule:GetStage2GrowthRedPointNumWithFeather()
        UIWidgetHelper.SetNewAndReds(self._tabBtns[2], new2, red2 > 0, "new", "red")
    end
end

-- 刷新 tab
function UIQuestGrowthItem:_SetTabSelect(index)
    if self._tabBtns then
        for i = 1, #self._tabBtns do
            self._tabBtns[i]:SetSelected(i == index)
        end
    end

    if self._tabIndex == index then
        return
    end
    self._tabIndex = index
end

--endregion

--region Day Btn

--
function UIQuestGrowthItem:_SetDayBtn()
    local cfgs = Cfg.cfg_quest_growth_day {}
    local strId = cfgs[1].Text

    ---@type UIActivityCommonTextTabBtn[]
    self._dayBtns = UIWidgetHelper.SpawnObjects(self, "_dayBtns", "UIActivityCommonTextTabBtn", #cfgs)
    for i, v in ipairs(self._dayBtns) do
        v:SetData(
            i, -- 索引
            {
                indexWidgets = {}, -- 与索引相关的状态组
                onoffWidgets = { { "select" }, { "" } }, -- 与是否选中相关的状态组 [1] = 选中 [2] = 非选中
                lockWidgets = { { "lock" }, {} }, --- 与是否锁定相关的状态组 [1] = 锁定 [2] = 正常
                titleWidgets = { "txtTitle" }, -- 标题列表组
                titleText = StringTable.Get(strId, i), -- 标题文字
                callback = function(index, isOffBtnClick) -- 点击按钮回调
                    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
                    if isOffBtnClick then
                        self:_SetDaySelect(index)
                        self:RefrenshList(true)
                    end
                end,
                lockCallback = function(index) -- 锁定按钮回调
                    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
                    UIWidgetHelper.SetAnimationPlay(v, "anim", "uieff_Quest_GrowthDayItem_Lock")
                    ToastManager.ShowToast(StringTable.Get("str_quest_base_growth_login_and_open", index))
                end
            }
        )
    end
end

--
function UIQuestGrowthItem:_Refresh_DayBtn()
    if self._dayBtns then
        for i, v in ipairs(self._dayBtns) do
            local lock = self._questModule:CheckQuestLock(i)
            v:SetLock(lock)

            local red = self._questModule:GetGrowthRedPointNum(i)
            v:GetGameObject("red"):SetActive(red > 0)
        end
    end
end

--
function UIQuestGrowthItem:_SetDaySelect(index)
    if self._dayBtns then
        for i = 1, #self._dayBtns do
            self._dayBtns[i]:SetSelected(i == index)
        end
    end

    if self._dayIndex == index then
        return
    end
    self._dayIndex = index
end

--endregion

--region Goal Btn

--
function UIQuestGrowthItem:_SetGoalBtn()
    local cfgs  = Cfg.cfg_quest_growth_goal {}
    local strId = cfgs[1].Text

    ---@type UIActivityCommonTextTabBtn[]
    self._goalBtns = UIWidgetHelper.SpawnObjects(self, "_goalBtns", "UIActivityCommonTextTabBtn", #cfgs)
    for i, v in ipairs(self._goalBtns) do
        v:SetData(
            i, -- 索引
            {
                indexWidgets = {}, -- 与索引相关的状态组
                onoffWidgets = { { "select" }, { "" } }, -- 与是否选中相关的状态组 [1] = 选中 [2] = 非选中
                lockWidgets = { { "lock" }, {} }, --- 与是否锁定相关的状态组 [1] = 锁定 [2] = 正常
                titleWidgets = { "txtTitle" }, -- 标题列表组
                titleText = StringTable.Get(strId, i), -- 标题文字
                callback = function(index, isOffBtnClick) -- 点击按钮回调
                    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
                    if isOffBtnClick then
                        self:_SetGoalSelect(index)
                        self:RefrenshList(true)
                    end
                end,
                lockCallback = function(index) -- 锁定按钮回调
                    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
                    UIWidgetHelper.SetAnimationPlay(v, "anim", "uieff_Quest_GrowthDayItem_Lock")
                    ToastManager.ShowToast(StringTable.Get("str_quest_base_growth_tab_goal_lock"))
                end
            }
        )
    end
end

--
function UIQuestGrowthItem:_Refresh_GoalBtn()
    if self._goalBtns then
        for i, v in ipairs(self._goalBtns) do
            local lock = self._questModule:CheckQuestIILock(i)
            v:SetLock(lock)

            local red = self._questModule:GetStage2GrowthRedPointNum(i)
            v:GetGameObject("red"):SetActive(red > 0)
        end
    end
end

--
function UIQuestGrowthItem:_SetGoalSelect(index)
    if self._goalBtns then
        for i = 1, #self._goalBtns do
            self._goalBtns[i]:SetSelected(i == index)
        end
    end

    if self._goalIndex == index then
        return
    end
    self._goalIndex = index
end

--endregion

--
function UIQuestGrowthItem:_Refresh_QuestList(anim)
    local list = {
        self._questModule:GetQuestByDayIndex(self._dayIndex),
        self._questModule:GetQuestIIByStage(self._goalIndex)
    }

    local tempList = list[self._tabIndex]
    self._questBGList:SpawnObjects("UIQuestGrowthQuestBGItem", 3)
    ---@type UIQuestGrowthQuestBGItem[]
    local questBGs = self._questBGList:GetAllSpawnList()
    for index, ui in ipairs(questBGs) do
        ui:Flush(
            index,
            tempList,
            function()
                self:RefrenshList(anim)
            end,
            anim
        )
    end
end

--
function UIQuestGrowthItem:_Refresh_Feather()
    local hadTexs = {
        self._questModule:GetFeatherCount(),
        self._questModule:GetStage2FeatherCount()
    }
    local hadTex = hadTexs[self._tabIndex]
    self._hadTex:SetText(StringTable.Get("str_quest_base_growth_had") .. hadTex)

    local maxVals = {
        Cfg.cfg_global["GrowthQuestCount"].IntValue,
        Cfg.cfg_global["GrowthQuestCount2"].IntValue
    }
    local maxValue = maxVals[self._tabIndex]

    local cfg_feather = Cfg.cfg_quest_growth_feather { ["QuestStage"] = self._tabIndex }
    if cfg_feather then
        local count = #cfg_feather

        self._featherImage.fillAmount = hadTex / maxValue

        ---@type UnityEngine.RectTransform
        local rect = self._featherPoolGo:GetComponent("RectTransform")
        local width = rect.sizeDelta.x

        self._featherPool:SpawnObjects("UIQuestGrowthFeatherItem", count)
        ---@type UIQuestGrowthFeatherItem[]
        self._featherItems = self._featherPool:GetAllSpawnList()

        local lastWidth = 0
        for i = 1, count do
            local needCount = cfg_feather[i].NeedCount
            local itemWidth = width / maxValue * needCount
            local reward = cfg_feather[i].Reward
            local id = reward[1][1]
            local rewardCount = reward[1][2]

            self._featherItems[i]:SetData(self._tabIndex, cfg_feather[i].ID, itemWidth, lastWidth, id, rewardCount, needCount, hadTex)
            lastWidth = itemWidth
        end
    end

    local cfgs = {
        Cfg.cfg_global["UIQuestGrowthLookIcon"],
        Cfg.cfg_global["UIQuestGrowthLookIcon_2"]
    }
    local cfg = cfgs[self._tabIndex]
    local lookIcon = cfg.StrValue
    self._bigAwardPetID = cfg.IntValue
    self._bigAwardLookIcon:LoadImage(lookIcon)

    local cfg_pet = Cfg.cfg_pet[self._bigAwardPetID]
    if cfg_pet == nil then
        Log.fatal("[quest] error --> cfg_pet is nil ! id --> " .. self._bigAwardPetID)
        return
    end
    local cg = HelperProxy:GetInstance():GetPetStaticBody(self._bigAwardPetID, 0, 0, PetSkinEffectPath.NO_EFFECT)
    self._bigAwardIcon:LoadImage(cg)

    UICG.SetTransform(self._cgRect, self:GetName(), cg)
end

function UIQuestGrowthItem:_ClearNew(index)
    -- 清除 阶段二 new
    if index == 2 then
        local new = self._questModule:GetNewPoint(QuestType.QT_Growth)
        if new then
            self._questModule:SetGrowthNewPoint()
        end
    end
end

--region Event

--
function UIQuestGrowthItem:lookOnClick()
    local id = self._bigAwardPetID
    Log.info("UIQuestGrowthItem:lookOnClick() id = ", id)

    if id then
        local itemModule = self:GetModule(ItemModule)
        if itemModule:IsChoosePetGift(id) then
            self:ShowDialog("UIPetBackPackBox", id, true)
        else
            self:ShowDialog("UIShopPetDetailController", id)
        end
    end
end

--endregion


--region AttachEvent

--
function UIQuestGrowthItem:OnUIGetItemCloseInQuest(type)
    if self._isOpen then
        self:RefrenshList()
    end
end

--endregion

--region Unuse

--
function UIQuestGrowthItem:getOnClick()
    self:Lock("UIQuestGet")

    GameGlobal.GetModule(PetModule):GetAllPetsSnapshoot()

    self:StartTask(self.OngetOnClick, self)
end

--
function UIQuestGrowthItem:OngetOnClick(TT)
    local petquest = self._questModule:GetQuestByDay(0)
    local res, msg = self._questModule:TakeQuestReward(TT, petquest[0]:QuestInfo().quest_id)
    self:UnLock("UIQuestGet")
    if (self.uiOwner == nil) then
        return
    end
    if res:GetSucc() then
        local rewards = msg.rewards

        self:ShowDialog(
            "UIPetObtain",
            rewards,
            function()
                GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
                self:ShowDialog(
                    "UIGetItemController",
                    rewards,
                    function()
                        GameGlobal.EventDispatcher():Dispatch(
                            GameEventType.OnUIGetItemCloseInQuest,
                            QuestType.QT_Growth
                        )
                    end
                )
            end
        )
    end
end

--
function UIQuestGrowthItem:GetAward(index)
    return self.awards and self.awards[index] and self.awards[index]:GetGameObject("bg")
end

--endregion
