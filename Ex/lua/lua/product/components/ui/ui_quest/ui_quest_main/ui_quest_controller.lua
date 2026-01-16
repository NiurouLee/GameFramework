---@class UIQuestController:UIController
_class("UIQuestController", UIController)
UIQuestController = UIQuestController

--出赛季任务外其它类型需要和QuestType对应上
--如果赛季的id和QuestType的其它类型冲突了，可以改这个赛季的id，同时修改配置文件cfg_quest_main_type
--- @class ClientQuestType
local ClientQuestType = {
    QT_None = 0,
    QT_Main = 1, -- 主线任务
    QT_Daily = 2, -- 日常任务
    QT_Branch = 3, -- 支线任务
    QT_Growth = 4, -- 成长任务
    QT_Achieve = 5, -- 成就任务
    QT_Season = 10001, -- 赛季
}
_enum("ClientQuestType", ClientQuestType)

function UIQuestController:LoadDataOnEnter(TT, res, uiParams)
    local questModule = self:GetModule(QuestModule)
    questModule:CalReqQuestDailyRefreshTime(TT)
    self:CheckSeasonOpen(TT)
    res:SetSucc(true)
end
function UIQuestController:CheckSeasonOpen(TT)
    self._showSeasonTab = false
    ---@type SeasonModule
    self._seasonModule = GameGlobal.GetModule(SeasonModule)
    local seasonid = self._seasonModule:GetCurSeasonID()
    if seasonid and seasonid>0 then
        local cfg_season_client = Cfg.cfg_season_campaign_client[seasonid]
        if cfg_season_client and cfg_season_client.QuestContent then
            local resSeason = self._seasonModule:ForceRequestCurSeasonData(TT)
            if resSeason:GetSucc() then
                --检查任务组件开启
                local component = self._seasonModule:GetCurSeasonQuestComponent()
                if component then
                    local isOpen = component:ComponentIsOpen()
                    if isOpen then
                        self._showSeasonTab = true
                    end
                end
            end
        end
    end
end
function UIQuestController:OnShow(uiParams)
    --self._backCallback = uiParams[1]
    self._id2Controller = {
        [QuestType.QT_Daily] = "UIQuestDailyItem",
        [QuestType.QT_Main] = "UIQuestStoryItem",
        [QuestType.QT_Branch] = "UIQuestSideItem",
        [QuestType.QT_Growth] = "UIQuestGrowthItem",
        [QuestType.QT_Achieve] = "UIQuestAchievementItem"
    }
    self._id2bg = {
        [QuestType.QT_Daily] = "task_richang_beijing1",
        [QuestType.QT_Main] = "task_juqing_beijing1",
        [QuestType.QT_Branch] = "task_zhixian_beijing1",
        [QuestType.QT_Growth] = "task_chengzhang_beijing1",
        [QuestType.QT_Achieve] = "task_chengjiu_beijing1"
    }

    --用来存放typeGo的,控制显影
    self._goTab = {}
    --用来存放UIView的,
    self._controllerTab = {}

    --第一次进入
    self._first = 1

    --五个类型的prefab的lua
    self._storyItem = nil
    self._dailyItem = nil
    self._sideItem = nil
    self._growthItem = nil
    self._achieveItem = nil

    self:_GetComponents()

    self:AttachEvent(GameEventType.ChangeQuestController, self.ChangeQuestController)
    self:AttachEvent(GameEventType.QuestUpdate, self.QuestUpdate)
    self:AttachEvent(GameEventType.QuestAwardItemClick, self.QuestAwardItemClick)

    --任务类型按钮
    self._cfg_type = Cfg.cfg_quest_main_type {}
    self._type_open_state = {}
    self:_CheckQuestOpenState()
    self._currrentIndex = 1

    --进入任务参数
    self._params = nil
    --uiParams[1] = 17
    if uiParams[1] then
        self._currrentType = uiParams[1]
        local questModule = self:GetModule(QuestModule)
        --如果成长未开启
        if self._currrentType == QuestType.QT_Growth and not questModule:IsGrowthVisible() then
            if table.count(self._type_open_state) > 0 then
                self._currrentType = self._type_open_state[self._currrentIndex].ClientType
            end
        else
            self._params = uiParams[2]

            for i = 1, table.count(self._type_open_state) do
                if self._currrentType == self._type_open_state[i].ClientType then
                    self._currrentIndex = i
                    break
                end
            end
        end
    else
        if table.count(self._type_open_state) > 0 then
            self._currrentType = self._type_open_state[self._currrentIndex].ClientType
        end
    end

    self:_OnValue()
    self:StartTask(self._ShowLock, self)
end

function UIQuestController:_ShowLock(TT)
    self:Lock("UIQuestController.Show")
    YIELD(TT, 500)
    self:UnLock("UIQuestController.Show")
end

function UIQuestController:OnHide()
    self:DetachEvent(GameEventType.ChangeQuestController, self.ChangeQuestController)
    self:DetachEvent(GameEventType.QuestUpdate, self.QuestUpdate)
    self:DetachEvent(GameEventType.QuestAwardItemClick, self.QuestAwardItemClick)
end

--任务内部跳转
function UIQuestController:ChangeQuestController(uiParams)
    for i = 1, table.count(self._type_open_state) do
        if uiParams == self._type_open_state[i].Type then
            self:_ItemClick(i, uiParams)
            return
        end
    end
    ToastManager.ShowToast("jump error , target is not open !")
end

--任务变了
function UIQuestController:QuestUpdate()
    --刷新信息
    self._controllerTab[self._currrentType]:RefrenshList()
end

--任务页签的物品的点击tips
function UIQuestController:QuestAwardItemClick(matid, pos)
    self._selectInfo:SetData(matid, pos)
end

function UIQuestController:_GetComponents()
    self._detailPool = self:GetUIComponent("UISelectObjectPath", "detailPool")
    self._detailPoolGo = self:GetGameObject("detailPool")

    self._detailPoolGrid = self:GetUIComponent("GridLayoutGroup", "detailPool")

    self._canvasGroup = self:GetUIComponent("CanvasGroup", "Center")

    self._itemInfo = self:GetUIComponent("UISelectObjectPath", "itemInfo")
    self._selectInfo = self._itemInfo:SpawnObject("UISelectInfo")

    local backBtns = self:GetUIComponent("UISelectObjectPath", "backBtns")
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            --主线
            if self._currrentType == QuestType.QT_Main and self._storyItem:CheckDetailOpen() then
                self._storyItem:CloseDetail()
            else
                self:CloseDialog()
            end
        end,
        nil
    )

    --self._bg = self:GetUIComponent("RawImageLoader", "bg")
    --self._bg2Go = self:GetGameObject("bg2")

    ---@type UnityEngine.RectTransform
    self._safeArea = self:GetUIComponent("RectTransform", "SafeArea")
    self._canvas = self._safeArea.parent:GetComponent("RectTransform")

    local safesize = self._canvas.rect.size
    safesize.x = safesize.x * (self._safeArea.anchorMax.x - self._safeArea.anchorMin.x)
    safesize.x = safesize.x + 1
    safesize.y = safesize.y + 1
    self._cellSize = safesize

    --Btns
    self._pools = self:GetUIComponent("UISelectObjectPath", "pools")

    self:_InitTypeComponents()
end

--不同类型的item生成
function UIQuestController:_InitTypeComponents()
    ---@type UISelectObjectPath
    --daily
    self._dailyTypeGrid = self:GetUIComponent("GridLayoutGroup", "dailyTypePool")
    --self._dailyTypeGrid.cellSize = Vector2(self._cellSize.x, self._cellSize.y)

    self._dailyTypePool = self:GetUIComponent("UISelectObjectPath", "dailyTypePool")
    self._dailyItem = self._dailyTypePool:SpawnObject("UIQuestDailyItem")
    self._dailyTypeGo = self:GetGameObject("dailyTypePool")
    self._goTab[ClientQuestType.QT_Daily] = self._dailyTypeGo
    self._controllerTab[ClientQuestType.QT_Daily] = self._dailyItem
    --table.insert(self._goTab, self._dailyTypeGo)
    -- self._dailyTypeGo:SetActive(false)
    --story
    self._storyTypeGrid = self:GetUIComponent("GridLayoutGroup", "dailyTypePool")
    --self._storyTypeGrid.cellSize = Vector2(self._cellSize.x, self._cellSize.y)

    self._storyTypePool = self:GetUIComponent("UISelectObjectPath", "storyTypePool")
    self._storyItem = self._storyTypePool:SpawnObject("UIQuestStoryItem")
    self._storyItem:SetDetailReference(self._detailPool, self._detailPoolGo, self._detailPoolGrid)
    self._storyTypeGo = self:GetGameObject("storyTypePool")
    self._goTab[ClientQuestType.QT_Main] = self._storyTypeGo
    self._controllerTab[ClientQuestType.QT_Main] = self._storyItem
    --table.insert(self._goTab, self._storyTypeGo)
    -- self._storyTypeGo:SetActive(false)
    --side
    self._sideTypeGrid = self:GetUIComponent("GridLayoutGroup", "dailyTypePool")
    --self._sideTypeGrid.cellSize = Vector2(self._cellSize.x, self._cellSize.y)

    self._sideTypePool = self:GetUIComponent("UISelectObjectPath", "sideTypePool")
    self._sideItem = self._sideTypePool:SpawnObject("UIQuestSideItem")
    self._sideTypeGo = self:GetGameObject("sideTypePool")
    self._goTab[ClientQuestType.QT_Branch] = self._sideTypeGo
    self._controllerTab[ClientQuestType.QT_Branch] = self._sideItem
    --table.insert(self._goTab, self._sideTypeGo)
    -- self._sideTypeGo:SetActive(false)
    --growth
    self._growthTypeGrid = self:GetUIComponent("GridLayoutGroup", "dailyTypePool")
    --self._growthTypeGrid.cellSize = Vector2(self._cellSize.x, self._cellSize.y)

    self._growthTypePool = self:GetUIComponent("UISelectObjectPath", "growthTypePool")
    self._growthItem = self._growthTypePool:SpawnObject("UIQuestGrowthItem")
    self._growthTypeGo = self:GetGameObject("growthTypePool")
    self._goTab[ClientQuestType.QT_Growth] = self._growthTypeGo
    self._controllerTab[ClientQuestType.QT_Growth] = self._growthItem
    --table.insert(self._goTab, self._growthTypeGo)
    -- self._growthTypeGo:SetActive(false)
    --achieve
    self._achieveTypeGrid = self:GetUIComponent("GridLayoutGroup", "dailyTypePool")
    --self._achieveTypeGrid.cellSize = Vector2(self._cellSize.x, self._cellSize.y)

    self._achieveTypePool = self:GetUIComponent("UISelectObjectPath", "achieveTypePool")
    self._achieveItem = self._achieveTypePool:SpawnObject("UIQuestAchievementItem")
    self._achieveTypeGo = self:GetGameObject("achieveTypePool")
    self._goTab[ClientQuestType.QT_Achieve] = self._achieveTypeGo
    self._controllerTab[ClientQuestType.QT_Achieve] = self._achieveItem
    --table.insert(self._goTab, self._achieveTypeGo)
    -- self._achieveTypeGo:SetActive(false)

    if self._showSeasonTab then
        self._seasonTypePool = self:GetUIComponent("UISelectObjectPath", "seasonTypePool")
        self._seasonItem = self._seasonTypePool:SpawnObject("UIQuestSeasonItem")
        self._seasonTypeGo = self:GetGameObject("seasonTypePool")
        self._goTab[ClientQuestType.QT_Season] = self._seasonTypeGo
        self._controllerTab[ClientQuestType.QT_Season] = self._seasonItem
    end
end

--检查每个类型的开启状态
function UIQuestController:_CheckQuestOpenState()
    ---@type QuestModule
    local module = GameGlobal.GetModule(QuestModule)
    if module == nil then
        Log.fatal("[quest] error --> module is nil !")
        return
    end
    for i = 1, table.count(self._cfg_type) do
        --赛季没配类型，其它的必须配，这里不处理，其它地方处理开关
        if self._cfg_type[i].ClientType == ClientQuestType.QT_Season then
            --判断当前有没有开启赛季任务
            if self._showSeasonTab then
                table.insert(self._type_open_state, self._cfg_type[i])
            end
        else
            if module:CheckQuestTypeUnlock(self._cfg_type[i].RealType) then
                --成长任务
                if self._cfg_type[i].RealType == QuestType.QT_Growth then
                    if module:IsGrowthVisible() then
                        table.insert(self._type_open_state, self._cfg_type[i])
                    end
                elseif self._cfg_type[i].RealType == QuestType.QT_Branch then
                    local taskList = module:GetQuestByQuestType(self._cfg_type[i].RealType)
                    local taskListT = {}
                    for i = 1, #taskList do
                        local quest = taskList[i]:QuestInfo()
                        if quest.status ~= QuestStatus.QUEST_NotStart then
                            table.insert(taskListT, taskList[i])
                        end
                    end
                    if #taskListT > 0 then
                        table.insert(self._type_open_state, self._cfg_type[i])
                    end
                else
                    table.insert(self._type_open_state, self._cfg_type[i])
                end
            end
        end
    end
end

function UIQuestController:_OnValue()
    --根据开启状态来生成按钮
    self._pools:SpawnObjects("UIQuestTypeBtnItem", table.count(self._type_open_state))
    ---@type UIQuestTypeBtnItem[]
    self._type_btns = self._pools:GetAllSpawnList()
    for i = 1, table.count(self._type_open_state) do
        self._type_btns[i]:SetData(
            i,
            self._type_open_state[i],
            function(idx, type)
                self:_ItemClick(idx, type)
            end
        )
    end

    --显示默认打开的类型
    self:_ShowInfo()
end

function UIQuestController:_ItemClick(idx, type)
    if idx == self._currrentIndex then
        return
    end
    --检查赛季开关，关了的话就刷新一下按钮栏
    if type == ClientQuestType.QT_Season then
        if not self._seasonModule then
            self._seasonModule = GameGlobal.GetModule(SeasonModule)
        end
        local seasonid = self._seasonModule:GetCurSeasonID()
        if seasonid>0 then
            Log.debug("###[UIQuestController] _ItemClick season type is open !")
        else
            Log.debug("###[UIQuestController] _ItemClick season type is close !")

            local tips = StringTable.Get("str_activity_error_109")
            ToastManager.ShowToast(tips)

            self._type_open_state = {}
            self._showSeasonTab = false
            self:_CheckQuestOpenState()
            self:_OnValue()
            return
        end
    end

    if self._currrentIndex ~= 0 then
        self._type_btns[self._currrentIndex]:Select(false)
    end

    --成就任务需要切换页签时还原一下按钮位置
    if self._currrentType == QuestType.QT_Achieve then
        self._controllerTab[self._currrentType]:BtnsOpenStateRevert()
    end

    self._controllerTab[QuestType.QT_Main]:CloseDetail()

    self._controllerTab[self._currrentType]:OnClose()

    self._currrentIndex = idx
    self._currrentType = type

    self:_ShowInfo()
end

function UIQuestController:ChangeCanvasGroup()
    self:Lock("UIQuestControllerChangeCanvasGroup")
    self._canvasGroup:DOFade(0, 0.082):OnComplete(
        function()
            self._canvasGroup:DOFade(1, 0.082):OnComplete(
                function()
                    self:UnLock("UIQuestControllerChangeCanvasGroup")
                end
            )
        end
    )
end

function UIQuestController:_ShowInfo()
    if self._currrentIndex ~= 0 then
        self._type_btns[self._currrentIndex]:Select(true)
        if self._currrentType==ClientQuestType.QT_Season then
            --清除赛季new
            self:GetModule(QuestModule):SetSeasonNew()
            self._type_btns[self._currrentIndex]:CheckQuestRedPoint()
        end
    end

    --[[

        if self._first == 0 then
            self:ChangeCanvasGroup()
        end
        if self._first == 1 then
            self._first = 0
        end
        ]]
    --换背景
    --self._bg:LoadImage(self._id2bg[self._currrentType])

    --切换页签时显示界面
    self:_ItemActiveAndHide()

    --成长任务两个背景
    --self._bg2Go:SetActive(self._currrentType == QuestType.QT_Growth)

    --刷新信息
    self._controllerTab[self._currrentType]:SetData(self._currrentType)
    --, self._cellSize.x, self._cellSize.y)
end

function UIQuestController:_ItemActiveAndHide()
    -- for key, value in pairs(self._goTab) do
    --     value:SetActive(key == self._currrentType)
    -- end
    --[[
        old
        for i = 1, table.count(self._goTab) do
            self._goTab[i]:SetActive(i == self._currrentIndex)
        end
        ]]
end

function UIQuestController:GetQuestStoryListItem(index)
    if self._storyItem then
        return self._storyItem:GetQuestStoryListItem(index)
    else
        return nil
    end
end

function UIQuestController:GetQuestStoryScroll()
    if self._storyItem then
        return self._storyItem:GetQuestStoryScroll()
    else
        return nil
    end
end

function UIQuestController:GetQuestStoryDetailItemGet()
    if self._storyItem then
        return self._storyItem:GetQuestStoryDetailItemGet()
    else
        return nil
    end
end

function UIQuestController:GetQuestStoryDetailItemGoto()
    if self._storyItem then
        return self._storyItem:GetQuestStoryDetailItemGoto()
    else
        return nil
    end
end

function UIQuestController:GetQuestTypeBtn(questType)
    if self._type_btns then
        -- return self._type_btns[index]:GetGameObject("bg")
        for index, value in ipairs(self._type_btns) do
            if value._type == questType then
                return value:GetGameObject("bg")
            end
        end
        return nil
    else
        return nil
    end
end

function UIQuestController:GetQuestSideTypeGotoBtn(questId)
    if self._sideItem then
        for index, item in ipairs(self._sideItem._items) do
            if item._data.quest_id == questId then
                return item:GetGameObject("GoTo")
            end
        end
        return nil
    else
        return nil
    end
end

function UIQuestController:GetQuestGrowthTypeLook()
    if self._growthItem then
        return self._growthItem:GetGameObject("look")
    else
        return nil
    end
end

function UIQuestController:GetQuestGrowthAward(index)
    if self._growthItem then
        return self._growthItem:GetAward(index)
    else
        return nil
    end
end
