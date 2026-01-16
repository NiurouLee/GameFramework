---@class UIHomelandMainBtns:UICustomWidget
_class("UIHomelandMainBtns", UICustomWidget)
UIHomelandMainBtns = UIHomelandMainBtns

function UIHomelandMainBtns:Constructor()
    ---@type HomelandModule
    self.mHomeland = GameGlobal.GetModule(HomelandModule)
    ---@type UIHomelandModule
    self.mUIHomeland = self.mHomeland:GetUIModule()
    ---@type HomelandClient
    self.homelandClient = self.mUIHomeland:GetClient()
    self._isVisit = self.homelandClient:IsVisit()

    if not self._isVisit then
        self.mHomeland = GameGlobal.GetModule(HomelandModule)
        self.data = self.mHomeland:GetHomelandLevelData()
        self.data:Init()
        self.dataBag = self.mHomeland:GetHomelandBackpackData()
        self.dataBag:Init()
        self._dairyEnterData = UIHomelandDairyEnterData:New()
    end
end

function UIHomelandMainBtns:OnShow()
    local btnPool = self:GetUIComponent("UISelectObjectPath", "btnPool")
    self._btnItem = btnPool:SpawnObject("UIHomeCommonCloseBtn")
    self._btnItem:SetData(
        function()
            self:btnBackOnClick()
        end,
        nil,
        true
    )

    ---@type UILocalizationText
    self.txtTips = self:GetUIComponent("UILocalizationText", "txtTips")
    ---@type UnityEngine.GameObject
    self.goTips = self:GetGameObject("tips")

    ---@type UnityEngine.GameObject
    self.diaryTips = self:GetGameObject("diaryTips")
    ---@type UILocalizationText
    self.msgText = self:GetUIComponent("UILocalizationText", "msgText")
    self.redBag = self:GetGameObject("redBag")
    self.redBag:SetActive(false)
    ---@type UISelectObjectPath
    self.dairyNew = self:GetGameObject("dairyNew")
    self.redLevel = self:GetGameObject("redLevel")
    self.redLevel:SetActive(false)
    ---@type UILocalizationText
    self.txtLevel = self:GetUIComponent("UILocalizationText", "txtLevel")

    self.taskRedPoint = self:GetGameObject("TaskRedPoint")

    self._btnFollowShow = self:GetGameObject("btnFollowShow")
    self._btnFollow = self:GetGameObject("btnFollow")

    self:CheckFollowCount()

    self._homeEventTips = {}
    self:AttachEvent(GameEventType.OnHomeEventTips, self.OnHomeEventTips)
    self:AttachEvent(GameEventType.ItemCountChanged, self.ItemCountChanged)
    self:AttachEvent(GameEventType.OnHomePetFollow, self.CheckFollowCount)
    self:AttachEvent(GameEventType.OnHomeStoryFinish, self.OnHomeEventFinish)
    self:AttachEvent(GameEventType.HomeLandEventChange, self.OnHomeEventFinish)
    self:AttachEvent(GameEventType.HomeAfterCollectLevelReward, self.FlushRedLevel)
    self:AttachEvent(GameEventType.HomeLandFunctionUnlock, self.RefreshFuncUnlock)
    self:AttachEvent(GameEventType.HomelandLevelOnLevelInfoChange, self.FlushLevel)
    self:AttachEvent(GameEventType.QuestUpdate, self.OnQuestUpdate)
    self:AttachEvent(GameEventType.AfterUILayerChanged, self.ShowDiaryInfo)
    self.btnBuild = self:GetGameObject("btnBuild") --建造
    self.btnBag = self:GetGameObject("btnBag") --背包
    self.btnFriend = self:GetGameObject("BtnFriend") --好友
    self.tglFollow = self:GetGameObject("tglFollow") --星灵跟随
    self.btnShowHide = self:GetGameObject("btnShowHide") --
    self.btnDiary = self:GetGameObject("btnDiary") --日记
    self.btnLevel = self:GetGameObject("btnLevel") --等级
    self.btnTask = self:GetGameObject("btnTask") --任务
    self.campaignEnter = self:GetGameObject("campaignEnter") --活动入口

    --拜访家园时关闭一些入口
    if self._isVisit then
        self.btnBuild:SetActive(false)
        self.btnBag:SetActive(false)
        self.tglFollow:SetActive(false)
        self.btnShowHide:SetActive(false)
        self.btnDiary:SetActive(false)
        self.btnLevel:SetActive(false)
        self.btnTask:SetActive(false)
        self.campaignEnter:SetActive(false)
    else
        self:Refresh()
        if self:CheckNewEventTip() then
            self:ShowEventTipTimer()
        end
    end
    self:_RefreshTaskRedPoint()
end

function UIHomelandMainBtns:OnHide()
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
    self:DetachEvent(GameEventType.ItemCountChanged, self.ItemCountChanged)
    self:DetachEvent(GameEventType.OnHomeStoryFinish, self.OnHomeEventFinish)
    self:DetachEvent(GameEventType.HomeLandEventChange, self.OnHomeEventFinish)
    self:DetachEvent(GameEventType.AfterUILayerChanged, self.ShowDiaryInfo)
end

-- 家园活动入口
function UIHomelandMainBtns:SetCampaignEnter(latestCampObj)
    if not self._isVisit then
        ---@type UIHomelandMainBtnsCampaignEnter
        local obj = UIWidgetHelper.SpawnObject(self, "campaignEnter", "UIHomelandMainBtnsCampaignEnter")
        obj:SetData(self.campaignEnter)
    end
end

function UIHomelandMainBtns:CheckFollowCount()
    local show = false
    local followList = self.homelandClient:PetManager():GetFollowPets()
    if table.count(followList) > 0 then
        show = true
    end
    self._btnFollow:SetActive(show)
end

function UIHomelandMainBtns:btnBackOnClick(go)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ExitHomeland)
    HomeLoading.Exit()
end

function UIHomelandMainBtns:BtnFollowOnClick(go)
    local followList = self.homelandClient:PetManager():GetFollowPets()
    if table.count(followList) > 0 then
        self._btnFollowShow:SetActive(true)
        self:ShowDialog(
            "UIHomePetFollowList",
            function()
                self._btnFollowShow:SetActive(false)
            end
        )
    end
end

function UIHomelandMainBtns:BtnShowHideOnClick(go)
    self.uiOwner:SetShowHide(false)
end

function UIHomelandMainBtns:BtnBuildOnClick(go)
    self:StartTask(self._EnterBuildMode, self)
end

function UIHomelandMainBtns:_EnterBuildMode(TT)
    self:SwitchState(UIStateType.UIHomelandBuild)
    while GameGlobal.UIStateManager():IsLocked() do
        YIELD(TT)
    end
    self.homelandClient:StartBuild()
end

function UIHomelandMainBtns:btnBagOnClick(go)
    self:ShowDialog("UIHomelandBackpack")
end

---@param homeTreasure HomelandTreasure
function UIHomelandMainBtns:OnHomeEventTips(petid, text)
    self._homeEventTips[#self._homeEventTips + 1] = { petid, text }
    self:PlayTips(true)
    --self:ShowDiaryInfo()
end

function UIHomelandMainBtns:PlayTips(isStart)
    if self._isPlayingTips and isStart then
        return
    end
    local t = self._homeEventTips[1]
    if not t then
        self._isPlayingTips = false
        self.goTips:SetActive(false)
        return
    end
    table.remove(self._homeEventTips, 1)
    if isStart then
        self._isPlayingTips = true
        self.goTips:SetActive(true)
    end
    ---@type CanvasGroup
    local canvasGroup = self.goTips:GetComponent("CanvasGroup")
    --TODO 获取头像和名字
    self.txtTips:SetText(t[2])

    --渐现渐隐
    canvasGroup:DOFade(1, 1.5):OnComplete(
        function()
            canvasGroup:DOFade(0, 1.5):OnComplete(
                function()
                    self:PlayTips(false)
                end
            )
        end
    )
end

function UIHomelandMainBtns:ShowDiaryInfo()
    -- 已完成的家园事件
    if not self._isVisit then
        self._homelandDairyCount, self._finishDairys = self._dairyEnterData:GetDairyEventCount()
        local isNew = self._dairyEnterData:CheckNew()
        self.diaryTips:SetActive(self._homelandDairyCount > 0 and (not isNew))
        self.dairyNew:SetActive(isNew)
        self._homelandDairyCount = self._homelandDairyCount > 99 and 99 or self._homelandDairyCount
        self.msgText:SetText(self._homelandDairyCount)
    end
end

-- 点击事件
function UIHomelandMainBtns:BtnDiaryOnClick(go)
    self:ShowDialog("UIHomeLandDiaryEnterController")
end

---@param functionType HomelandUnlockType
function UIHomelandMainBtns:RefreshFuncUnlock(functionType)
    if functionType == HomelandUnlockType.E_HOMELAND_UNLOCK_BAG_UI then
        self.btnBag:SetActive(true)
    elseif functionType == HomelandUnlockType.E_HOMELAND_UNLOCK_BUILD_UI then
        self.btnBuild:SetActive(true)
    elseif functionType == HomelandUnlockType.E_HOMELAND_UNLOCK_LEVEL_BTN_UI then
        self.btnLevel:SetActive(true)
    elseif functionType == HomelandUnlockType.E_HOMELAND_UNLOCK_DAIRY_UI then
        self.btnDiary:SetActive(true)
    elseif functionType == HomelandUnlockType.E_HOMELAND_UNLOCK_VISIT_UI then
        self.btnFriend:SetActive(true)
    elseif functionType == HomelandUnlockType.E_HOMELAND_UNLOCK_QUEST_BTN then
        self.btnTask:SetActive(true)
    elseif functionType == HomelandUnlockType.E_HOMELAND_UNLOCK_FOLLOW_UI then
        self.tglFollow:SetActive(true)
    end
end

--  界面初始
function UIHomelandMainBtns:Refresh()
    self.btnBag:SetActive(self.mHomeland:CheckFunctionUnlock(HomelandUnlockType.E_HOMELAND_UNLOCK_BAG_UI))
    self.btnBuild:SetActive(self.mHomeland:CheckFunctionUnlock(HomelandUnlockType.E_HOMELAND_UNLOCK_BUILD_UI))
    self.btnLevel:SetActive(self.mHomeland:CheckFunctionUnlock(HomelandUnlockType.E_HOMELAND_UNLOCK_LEVEL_BTN_UI))
    self.btnDiary:SetActive(self.mHomeland:CheckFunctionUnlock(HomelandUnlockType.E_HOMELAND_UNLOCK_DAIRY_UI))
    self.btnFriend:SetActive(self.mHomeland:CheckFunctionUnlock(HomelandUnlockType.E_HOMELAND_UNLOCK_VISIT_UI))
    self.btnTask:SetActive(self.mHomeland:CheckFunctionUnlock(HomelandUnlockType.E_HOMELAND_UNLOCK_QUEST_BTN))
    self.tglFollow:SetActive(self.mHomeland:CheckFunctionUnlock(HomelandUnlockType.E_HOMELAND_UNLOCK_FOLLOW_UI))

    self:ShowDiaryInfo()
    self:FlushRedBag()
    self:FlushLevel()
end

--region Bag
function UIHomelandMainBtns:ItemCountChanged()
    if not self._isVisit then
        self.dataBag:InitList()
        self:FlushRedBag()
    end
end

function UIHomelandMainBtns:FlushRedBag()
    if not self._isVisit then
        if self.dataBag:IsNew() then
            self.redBag:SetActive(true)
        else
            self.redBag:SetActive(false)
        end
    end
end

--endregion

--region level button
function UIHomelandMainBtns:btnLevelOnClick(go)
    self:ShowDialog("UIHomelandLevel")
end

function UIHomelandMainBtns:FlushLevel()
    self.txtLevel:SetText(self.data.level)
    self:FlushRedLevel()
end

---家园等级红点
function UIHomelandMainBtns:FlushRedLevel()
    if self.data:HasAward2Get() then
        self.redLevel:SetActive(true)
    else
        self.redLevel:SetActive(false)
    end
end

function UIHomelandMainBtns:BtnFriendOnClick(go)
    self:ShowDialog("UIHomeVisitFriends")
end

--endregion

--手册(任务)
function UIHomelandMainBtns:btnTaskOnClick(go)
    self:ShowDialog(
        "UIHomelandTask",
        function()
            self:_RefreshTaskRedPoint()
        end
    )
end

function UIHomelandMainBtns:_RefreshTaskRedPoint()
    ---@type QuestModule
    local questModule = self:GetModule(QuestModule)
    local show, functionType = questModule:HomeLandTaskRedPoint()
    if show then
        local unlock = true
        if functionType == QuestType.QT_Homeland_Stage or functionType == QuestType.QT_Homeland_Stage_Num then
            unlock = self.mHomeland:CheckFunctionUnlock(HomelandUnlockType.E_HOMELAND_UNLOCK_QUEST_STAGE_UI)
        elseif functionType == QuestType.QT_Homeland_Common then
            unlock = self.mHomeland:CheckFunctionUnlock(HomelandUnlockType.E_HOMELAND_UNLOCK_QUEST_COMMON_UI)
        end
        self.taskRedPoint:SetActive(show and unlock)
    else
        self.taskRedPoint:SetActive(show)
    end
end

function UIHomelandMainBtns:OnHomeEventFinish()
    self:ShowDiaryInfo()
    self:ShowEventTipTimer()
end

function UIHomelandMainBtns:CheckNewEventTip()
    local mRole = GameGlobal.GetModule(RoleModule)
    local pstid = mRole:GetPstId()
    local key = "CheckNewEventTip" .. pstid
    if not UnityEngine.PlayerPrefs.HasKey(key) then
        UnityEngine.PlayerPrefs.SetInt(key, 0)
    end
    local res = false
    local count = UnityEngine.PlayerPrefs.GetInt(key)
    if #self._finishDairys ~= count then
        res = true
    end
    return res
end

function UIHomelandMainBtns:ShowEventTip()
    local mRole = GameGlobal.GetModule(RoleModule)
    local pstid = mRole:GetPstId()
    local key = "CheckNewEventTip" .. pstid
    local count = UnityEngine.PlayerPrefs.GetInt(key)
    if #self._finishDairys ~= count then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.OnUIHomeEventTips,
            UIHomeEventTipsType.Dairy,
            { StringTable.Get("str_homeland_diarynew_tips") }
        )
        UnityEngine.PlayerPrefs.SetInt(key, #self._finishDairys)
    end
end

function UIHomelandMainBtns:ShowEventTipTimer()
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
    if not self._timerHandler then
        self._timerHandler =
        GameGlobal.Timer():AddEventTimes(
            500,
            TimerTriggerCount.Once,
            function()
                self:ShowEventTip()
            end
        )
    end
end

function UIHomelandMainBtns:OnQuestUpdate(quests)
    self:_RefreshTaskRedPoint()
end
