---@class UIQuestAchievementItem:UICustomWidget
_class("UIQuestAchievementItem", UICustomWidget)
UIQuestAchievementItem = UIQuestAchievementItem

function UIQuestAchievementItem:OnShow(uiParams)
    ---@type ATransitionComponent
    self._transition = self:GetUIComponent("ATransitionComponent", "UIQuestAchievementItem")
    ---@type UnityEngine.CanvasGroup
    self._canvasGroup = self:GetUIComponent("CanvasGroup", "UIQuestAchievementItem")
    self._canvasGroup.blocksRaycasts = false

    self._itemCountPerRow = 1

    self._leftBtnTweens = {}
    self._leftBtnAnchorPos = {}
    self._leftBtnRectTransform = {}
    self._tweenTime = 0.2
    self._oldHeight = 0
    self._newHeight = 0
    self._openIdx = -1
    self._enum = 0

    --开始自动点击的按钮
    self._openBigIdx = 1
    self._openSmallIdx = 0

    --第一次初始化最近信息
    self._isFirst = true
    --第一次初始化详细信息
    self._isFirstDetail = true

    self._isDetaiOpen = false

    self:AttachEvents()
end

function UIQuestAchievementItem:SetData(type)
    if self._listInitAnimateTask then
        GameGlobal.TaskManager():KillTask(self._listInitAnimateTask)
    end

    self._canvasGroup.blocksRaycasts = true
    self._transition:PlayEnterAnimation(true)

    self._isIntro = (not self._isOpen)

    self._isOpen = true

    self:_GetComponents()

    self._type = type

    ---@type QuestModule
    self._questModule = GameGlobal.GetModule(QuestModule)
    if self._questModule == nil then
        Log.fatal("[quest] error --> _questModule is nil !")
        return
    end
    self._cfg_quest_achieve_type = Cfg.cfg_quest_achieve_type {}
    if self._cfg_quest_achieve_type == nil then
        Log.fatal("[quest] error --> _cfg_quest_achieve_type is nil !")
        return
    end

    --获取红点数据
    self._redInfo = self._questModule:GetAchRedPoint()

    self:_OnValue()

    self._listInitAnimateTask =
        GameGlobal.TaskManager():StartTask(
        function(TT)
            YIELD(TT, 500)
            self._isIntro = false
        end
    )
end

function UIQuestAchievementItem:OnHide()
    self:RemoveEvents()
end

--给分类页签检查红点状态用
function UIQuestAchievementItem:CheckRedState(enum)
    return self._redInfo[enum]
end

function UIQuestAchievementItem:_GetComponents()
    self._detailGo = self:GetGameObject("detailGo")
    self._allGo = self:GetGameObject("allGo")
    self._achPointRedPoint = self:GetGameObject("red")

    self._detailScrollView = self:GetUIComponent("UIDynamicScrollView", "taskDetailList")
    self._allScrollView = self:GetUIComponent("UIDynamicScrollView", "taskAllList")

    self._achTypePool = self:GetUIComponent("UISelectObjectPath", "achTypePool")

    self._leftPool = self:GetUIComponent("UISelectObjectPath", "leftPool")

    self._allViewFillAmont = self:GetUIComponent("Image", "allViewFillAmont")
    self._allViewValue = self:GetUIComponent("UILocalizationText", "allViewValue")
end

function UIQuestAchievementItem:_InitAchTypeBtns()
    local tempTab = {}
    for i = 1, #self._cfg_quest_achieve_type do
        --if i ~= 1 then
        table.insert(tempTab, self._cfg_quest_achieve_type[i])
        --end
    end

    self._btnCount = table.count(tempTab)
    self._leftPool:SpawnObjects("UIQuestAchTypeBtnItem", self._btnCount)
    ---@type UIQuestAchTypeBtnItem[]
    self._btns = self._leftPool:GetAllSpawnList()

    for i = 1, self._btnCount do
        local itemData = tempTab[i]

        self._btns[i]:SetData(
            i,
            itemData,
            function(enum)
                self:ShowInfoOfEnum(enum)
            end,
            function(idx, height)
                self:ChangeLayout(idx, height)
            end,
            function(enum)
                return self:CheckRedState(enum)
            end,
            self._isIntro
        )
    end

    for i = 1, self._btnCount do
        local tween = nil
        table.insert(self._leftBtnTweens, tween)
        local itemRT = self._btns[i]:ItemRectTransform()
        table.insert(self._leftBtnRectTransform, itemRT)
        table.insert(self._leftBtnAnchorPos, itemRT.anchoredPosition)
    end

    self._leftRT = self:GetUIComponent("RectTransform", "leftPool")
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._leftRT)

    local leftGrid = self:GetUIComponent("GridLayoutGroup", "leftPool")

    self._leftRT.sizeDelta =
        Vector2(leftGrid.cellSize.x, leftGrid.cellSize.y * self._btnCount + leftGrid.spacing.y * (self._btnCount - 1))

    leftGrid.enabled = false
end
--总览
function UIQuestAchievementItem:allViewBtnOnClick()
    if self._viewSwitchTask then
        GameGlobal.TaskManager():KillTask(self._viewSwitchTask)
    end
    self._canvasGroup.blocksRaycasts = false
    self._viewSwitchTask =
        GameGlobal.TaskManager():StartTask(
        function(TT)
            local enum = self._cfg_quest_achieve_type[1].BigTypeEnum
            self:ShowInfoOfEnum(enum)
        end
    )
end

function UIQuestAchievementItem:ShowInfoOfEnum(enum)
    if self._enum == enum then
        return
    end
    self._enum = enum

    --总览
    if self._enum == 1 then
        self._allGo:SetActive(true)
        self._detailGo:SetActive(false)

        self._isDetaiOpen = false

        if self._isFirst == true then
            self._isFirst = false
            self:_InitLatelyScrollViewAndTypePool()
        else
            self:_RefrenshLatelyScrollView()
        end
    else
        self._allGo:SetActive(false)
        self._detailGo:SetActive(true)

        self._isDetaiOpen = true

        if self._isFirstDetail == true then
            self._isFirstDetail = false
            --初始化详细信息
            self:_InitDetailScrollView()
        else
            self:_RefrenshDetailScrollView()
        end
    end
end

function UIQuestAchievementItem:ChangeLayout(idx, height)
    self._newHeight = height

    local lastIdx = self._openIdx

    if self._openIdx > 0 then
        self._btns[self._openIdx]:CloseMovePos()
    end
    if self._openIdx == idx then
        --如果下面没有子按钮，第二次点击不触发
        if self._btns[self._openIdx]:HasItems() == false then
            return
        end
        self._openIdx = -1
    else
        self._openIdx = idx
    end
    if self._openIdx ~= -1 then
        self._btns[self._openIdx]:OpenMovePos()
    end

    local nextIdx = self._openIdx

    for i = 1, #self._leftBtnTweens do
        if self._leftBtnTweens[i] ~= nil then
            self._leftBtnTweens[i]:Kill(true)
        end
    end

    if lastIdx == -1 then
        for i = 1, self._btnCount do
            if i > nextIdx then
                self._leftBtnTweens[i] =
                    self._leftBtnRectTransform[i]:DOAnchorPos(
                    Vector2(
                        self._leftBtnRectTransform[i].anchoredPosition.x,
                        self._leftBtnRectTransform[i].anchoredPosition.y - height
                    ),
                    self._tweenTime
                )
            end
        end
        self._leftRT.sizeDelta = Vector2(self._leftRT.sizeDelta.x, self._leftRT.sizeDelta.y + self._newHeight)

        self._oldHeight = height
    else
        if nextIdx == -1 then
            for i = 1, self._btnCount do
                if i > lastIdx then
                    self._leftBtnTweens[i] =
                        self._leftBtnRectTransform[i]:DOAnchorPos(
                        Vector2(
                            self._leftBtnRectTransform[i].anchoredPosition.x,
                            self._leftBtnRectTransform[i].anchoredPosition.y + self._oldHeight
                        ),
                        self._tweenTime
                    )
                end
            end
            self._leftRT.sizeDelta = Vector2(self._leftRT.sizeDelta.x, self._leftRT.sizeDelta.y - self._oldHeight)

            self._oldHeight = 0
        else
            if lastIdx < nextIdx then
                for i = 1, self._btnCount do
                    if i > lastIdx and i <= nextIdx then
                        self._leftBtnTweens[i] =
                            self._leftBtnRectTransform[i]:DOAnchorPos(
                            Vector2(
                                self._leftBtnRectTransform[i].anchoredPosition.x,
                                self._leftBtnRectTransform[i].anchoredPosition.y + self._oldHeight
                            ),
                            self._tweenTime
                        )
                    elseif i > nextIdx then
                        self._leftBtnTweens[i] =
                            self._leftBtnRectTransform[i]:DOAnchorPos(
                            Vector2(
                                self._leftBtnRectTransform[i].anchoredPosition.x,
                                self._leftBtnRectTransform[i].anchoredPosition.y + self._oldHeight - self._newHeight
                            ),
                            self._tweenTime
                        )
                    end
                end
            else
                for i = 1, self._btnCount do
                    if i > nextIdx and i <= lastIdx then
                        self._leftBtnTweens[i] =
                            self._leftBtnRectTransform[i]:DOAnchorPos(
                            Vector2(
                                self._leftBtnRectTransform[i].anchoredPosition.x,
                                self._leftBtnRectTransform[i].anchoredPosition.y - self._newHeight
                            ),
                            self._tweenTime
                        )
                    elseif i > lastIdx then
                        self._leftBtnTweens[i] =
                            self._leftBtnRectTransform[i]:DOAnchorPos(
                            Vector2(
                                self._leftBtnRectTransform[i].anchoredPosition.x,
                                self._leftBtnRectTransform[i].anchoredPosition.y + self._oldHeight - self._newHeight
                            ),
                            self._tweenTime
                        )
                    end
                end
            end
            self._leftRT.sizeDelta =
                Vector2(self._leftRT.sizeDelta.x, self._leftRT.sizeDelta.y - self._oldHeight + self._newHeight)

            self._oldHeight = height
        end
    end

    --改变其他按钮的选中状态
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIQuestOnBigTypeBtnClick, self._openIdx)
end

--初始化详细信息
function UIQuestAchievementItem:_InitDetailScrollView()
    self._questDataList = self:GetList()

    self._questDataListCount = table.count(self._questDataList)

    self._detailScrollView:InitListView(
        self._questDataListCount,
        function(scrollView, index)
            return self:_OnInitDetailScrollView(scrollView, index)
        end
    )
end

--根据类型拿任务列表
function UIQuestAchievementItem:GetList()
    local qlbt = self:GetQuestList()

    local tempList = {}

    for i = 1, table.count(qlbt) do
        local quest = qlbt[i]:QuestInfo()
        if quest.AchieveType == self._enum then
            table.insert(tempList, quest)
        end
    end

    return tempList
end

function UIQuestAchievementItem:GetQuestList()
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

function UIQuestAchievementItem:_OnInitDetailScrollView(scrollView, index)
    if index < 0 then
        return nil
    end
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UIQuestAchievementLatelyAchieveItem", self._itemCountPerRow)
    end
    local rowList = rowPool:GetAllSpawnList()
    for i = 1, self._itemCountPerRow do
        local heartItem = rowList[i]
        local itemIndex = index * self._itemCountPerRow + i
        self:_ShowAchieveItem(heartItem, itemIndex)
    end
    return item
end
function UIQuestAchievementItem:_ShowAchieveItem(heartItem, itemIndex)
    local data = self._questDataList[itemIndex]
    heartItem:GetGameObject():SetActive(true)
    if (data ~= nil) then
        heartItem:SetData(
            itemIndex,
            data,
            function(questInfo)
                self:_AchievementClick(questInfo.quest_id)
            end,
            function(matid, pos)
                GameGlobal.EventDispatcher():Dispatch(GameEventType.QuestAwardItemClick, matid, pos)
            end
        )
    end
end

function UIQuestAchievementItem:_AchievementClick(id)
    self:Lock("UIQuestGet")
    GameGlobal.GetModule(PetModule):GetAllPetsSnapshoot()
    self:StartTask(self._OnGet, self, id)
end

function UIQuestAchievementItem:OnUIPetObtainCloseInQuest(type)
    if self._isOpen then
        if type == QuestType.QT_Achieve then
            self:ShowDialog(
                "UIGetItemController",
                self._tempMsgRewards,
                function()
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIGetItemCloseInQuest, QuestType.QT_Achieve)
                end
            )
        end
    end
end

function UIQuestAchievementItem:AttachEvents()
    self:AttachEvent(GameEventType.RolePropertyChanged, self._OnRedChanged)
    self:AttachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
    self:AttachEvent(GameEventType.OnUIPetObtainCloseInQuest, self.OnUIPetObtainCloseInQuest)
end
function UIQuestAchievementItem:RemoveEvents()
    self:DetachEvent(GameEventType.RolePropertyChanged, self._OnRedChanged)
    self:DetachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
    self:DetachEvent(GameEventType.OnUIPetObtainCloseInQuest, self.OnUIPetObtainCloseInQuest)
end

function UIQuestAchievementItem:OnUIGetItemCloseInQuest(type)
    if self._isOpen then
        if type == QuestType.QT_Achieve then
            self:RefrenshList()
        end
    end
end

function UIQuestAchievementItem:_OnGet(TT, id)
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
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIPetObtainCloseInQuest, QuestType.QT_Achieve)
                end
            )
        else
            self:ShowDialog(
                "UIGetItemController",
                msg.rewards,
                function()
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIGetItemCloseInQuest, QuestType.QT_Achieve)
                end
            )
        end
    end
end

--初始化最近信息
function UIQuestAchievementItem:_InitLatelyScrollViewAndTypePool()
    self._qusetAllDataList = self:GetLatelyList()

    self._questLatelyListCount = table.count(self._qusetAllDataList)

    self._allScrollView:InitListView(
        self._questLatelyListCount,
        function(scrollView, index)
            return self:_OnInitLatelyScrollView(scrollView, index)
        end
    )
end
function UIQuestAchievementItem:GetLatelyList()
    local qls = {}
    local qusetAllDataList = self._questModule:GetRecentCompletedAchiveID()
    for i = 1, table.count(qusetAllDataList) do
        local _q = self._questModule:GetQuest(qusetAllDataList[i]):QuestInfo()
        if _q == nil then
            Log.fatal("[quest] error --> quest is nil ! id --> " .. _q.quest_id)
            return
        end
        table.insert(qls, _q)
    end
    return qls
end
function UIQuestAchievementItem:_OnInitLatelyScrollView(scrollView, index)
    if index < 0 then
        return nil
    end
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UIQuestAchievementLatelyAchieveItem", self._itemCountPerRow)
    end
    local rowList = rowPool:GetAllSpawnList()
    for i = 1, self._itemCountPerRow do
        local heartItem = rowList[i]
        local itemIndex = index * self._itemCountPerRow + i

        self:_ShowLatelyAchieveItem(heartItem, itemIndex)
    end

    return item
end
function UIQuestAchievementItem:_ShowLatelyAchieveItem(heartItem, itemIndex)
    local data = self._qusetAllDataList[itemIndex]

    heartItem:GetGameObject():SetActive(true)
    if (data ~= nil) then
        heartItem:SetData(
            itemIndex,
            data,
            function(questInfo)
                self:_AchievementClick(questInfo.quest_id)
            end,
            function(matid, pos)
                GameGlobal.EventDispatcher():Dispatch(GameEventType.QuestAwardItemClick, matid, pos)
            end,
            self._isIntro
        )
    end
end

function UIQuestAchievementItem:GetCountByType(enum)
    ---@type QuestModule
    return self._questModule:GetAchieveCount(enum)
end

--初始化总览信息Top
function UIQuestAchievementItem:_InitAchTypePool()
    local allViewType = self._cfg_quest_achieve_type[1].BigTypeEnum
    local allViewNowValue, allViewAllValue = self:GetCountByType(allViewType)
    local rate = allViewNowValue / allViewAllValue
    self._allViewFillAmont.fillAmount = rate

    local str
    if allViewNowValue >= allViewAllValue then
        str = "<color=#fdd100>" .. allViewNowValue .. "/" .. allViewAllValue .. "</color>"
    else
        str = "<color=#fdd100>" .. allViewNowValue .. "</color>" .. "/" .. allViewAllValue
    end
    self._allViewValue:SetText(str)

    local tempTab = {}
    for i = 1, #self._cfg_quest_achieve_type do
        if i ~= 1 then
            table.insert(tempTab, self._cfg_quest_achieve_type[i])
        end
    end
    local count = table.count(tempTab)

    self._achTypePool:SpawnObjects("UIQuestAchievementAchieveTypeItem", count)
    ---@type UIQuestAchievementAchieveTypeItem[]
    local items = self._achTypePool:GetAllSpawnList()
    for i = 1, count do
        local name = tempTab[i].BigTypeName
        local nameEn = tempTab[i].BigTypeNameEn

        local type = tempTab[i].BigTypeEnum

        local nowValue, allValue = self:GetCountByType(type)

        local sprite = tempTab[i].Icon

        items[i]:SetData(i, sprite, name, nameEn, nowValue, allValue, count)
    end
end

function UIQuestAchievementItem:OnClose()
    self._isOpen = false

    self._transition:PlayLeaveAnimation(true)
    self._canvasGroup.blocksRaycasts = false
end

--左侧按钮栏位置还原,MainController切换页签时调用
function UIQuestAchievementItem:BtnsOpenStateRevert()
    if self._openIdx > 0 then
        self._btns[self._openIdx]:CloseMovePos()

        for i = 1, self._btnCount do
            if i > self._openIdx then
                self._leftBtnTweens[i] =
                    self._leftBtnRectTransform[i]:DOAnchorPos(
                    Vector2(
                        self._leftBtnRectTransform[i].anchoredPosition.x,
                        self._leftBtnRectTransform[i].anchoredPosition.y + self._oldHeight
                    ),
                    self._tweenTime
                )
            end
        end
        self._leftRT.sizeDelta = Vector2(self._leftRT.sizeDelta.x, self._leftRT.sizeDelta.y - self._oldHeight)

        self._oldHeight = 0

        self._openIdx = -1
    end
end

function UIQuestAchievementItem:_OnValue()
    if not self._type then
        return
    end
    self:ShowInfoOfEnum(self._enum)
    self:_InitAchTypeBtns()
    self:_InitAchTypePool()

    --[[

        ]]
    if self._openBigIdx > 0 then
        self._btns[self._openBigIdx]:BtnBeClick(self._openSmallIdx)
    end
    --成就点奖励红点
    local achPointRedPoint = self._questModule:GetUnReceivedAchRewardsBoxNum() > 0
    self._achPointRedPoint:SetActive(achPointRedPoint)
end

function UIQuestAchievementItem:_OnRedChanged()
    if self._isOpen then
        --成就点奖励红点
        local achPointRedPoint = self._questModule:GetUnReceivedAchRewardsBoxNum() > 0
        self._achPointRedPoint:SetActive(achPointRedPoint)
    end
end

function UIQuestAchievementItem:RefrenshList()
    if self._isDetaiOpen then
        self:_RefrenshDetailScrollView()
    else
        self:_RefrenshLatelyScrollView()
    end
end

function UIQuestAchievementItem:_RefrenshDetailScrollView()
    self._questDataList = self:GetList()

    self._questDataListCount = table.count(self._questDataList)

    local contentPos = self._detailScrollView.ScrollRect.content.localPosition

    self._detailScrollView:SetListItemCount(self._questDataListCount)

    self._detailScrollView:MovePanelToItemIndex(0, 0)

    self._detailScrollView.ScrollRect.content.localPosition = contentPos
end

function UIQuestAchievementItem:_RefrenshLatelyScrollView()
    self._qusetAllDataList = self:GetLatelyList()

    self._questLatelyListCount = table.count(self._qusetAllDataList)

    local contentPos = self._allScrollView.ScrollRect.content.localPosition

    self._allScrollView:SetListItemCount(self._questLatelyListCount)

    self._allScrollView:MovePanelToItemIndex(0, 0)

    self._allScrollView.ScrollRect.content.localPosition = contentPos
end

function UIQuestAchievementItem:OpenAchieveMentPointOnClick()
    self:ShowDialog("UIQuestAchievementPointAwardsController")
end

function UIQuestAchievementItem:AllGetBtnOnClick()
    local redInfo = self._questModule:CanOneKeyGetReward()
    if redInfo then
        self:Lock("AllGetBtnOnClick")
        self:StartTask(self._OnAllGet, self)
    end
end
function UIQuestAchievementItem:_OnAllGet(TT)
    local res, msg = self._questModule:TakeOneKeyReward(TT, self._type)
    self:UnLock("AllGetBtnOnClick")

    if res:GetSucc() then
        --刷新红点
        --GameGlobal.EventDispatcher():Dispatch(GameEventType.CheckQuestRedPoint, QuestType.QT_Achieve)
        if (self.uiOwner == nil) then
            return
        end
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
                        QuestType.QT_Achieve + 10000
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
                            QuestType.QT_Achieve + 10000
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
    else
        Log.fatal("###error , quest All Get ! ", msg)
    end
end

function UIQuestAchievementItem:OnUIPetObtainCloseInQuest(type)
    if type == QuestType.QT_Achieve + 10000 then
        self:ShowDialog(
            "UIGetItemController",
            self._tempMsgRewards,
            function()
                GameGlobal.EventDispatcher():Dispatch(
                    GameEventType.OnUIGetItemCloseInQuest,
                    QuestType.QT_Achieve + 10000
                )
            end
        )
    end
end
function UIQuestAchievementItem:OnUIGetItemCloseInQuest(type)
    if type == QuestType.QT_Achieve + 10000 then
        self:RefrenshList()
    end
end
