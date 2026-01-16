--特殊处理的每日任务
--- @class UIQuestDailySpecialType
local UIQuestDailySpecialType = {
        DoOneDispatch = 20006, --每日任务中的完成一次派遣 
        DoThreeDispatch = 20015, --每日任务中的完成三次派遣
}
_enum("UIQuestDailySpecialType", UIQuestDailySpecialType)

---@class UIQuestDailyListItem:UICustomWidget
_class("UIQuestDailyListItem", UICustomWidget)
UIQuestDailyListItem = UIQuestDailyListItem

function UIQuestDailyListItem:OnShow(uiParams)
    self._module = GameGlobal.GetModule(QuestModule)
    if self._module == nil then
        Log.fatal("[quest] erro --> module is nil !")
        return
    end
    self._atlas = self:GetAsset("UIQuest.spriteatlas", LoadType.SpriteAtlas)
end

function UIQuestDailyListItem:SetData(index, quest, callback, itemCallback)
    self:_GetComponents()

    self._index = index
    self._quest = quest:QuestInfo()
    self._callback = callback
    self._itemCallback = itemCallback

    self:_OnValue()
end

function UIQuestDailyListItem:OnHide()
end

function UIQuestDailyListItem:_GetComponents()
    self._typeTex = self:GetUIComponent("UILocalizationText", "typeTex")
    self._desTex = self:GetUIComponent("UILocalizationText", "desTex")

    self._awardPool = self:GetUIComponent("UISelectObjectPath", "awardPool")

    self._stateValueImg = self:GetUIComponent("Image", "stateValueImg")
    self._stateValueTex = self:GetUIComponent("UILocalizationText", "stateValueTex")

    self._btn = self:GetGameObject("btn")
    self._got = self:GetGameObject("got")

    self._btnImg = self:GetUIComponent("Image", "btn")
    self._btnIcon = self:GetUIComponent("Image", "icon")
    self._btnTex = self:GetUIComponent("UILocalizationText", "stateTex")

    self._mask = self:GetGameObject("mask")
    self._select = self:GetGameObject("select")
end

function UIQuestDailyListItem:_OnValue()
    self._typeTex:SetText(StringTable.Get(self._quest.QuestName))
    self._desTex:SetText(StringTable.Get(self._quest.CondDesc))

    local progress = ""
    if self._quest.ShowType == 1 then
        local c, d = math.modf(self._quest.cur_progress * 100 / self._quest.total_progress)
        if c < 1 and d > 0 then
            c = 1
        end
        progress = c .. "%"
    else
        progress = self._quest.cur_progress .. "/<color=#7386ff>" .. self._quest.total_progress .. "</color>"
    end
    self._stateValueTex:SetText(progress)

    local rate = self._quest.cur_progress / self._quest.total_progress
    self._stateValueImg.fillAmount = rate

    local btnTex = ""
    local icon = ""
    local img = ""

    self._mask:SetActive(self._quest.status == QuestStatus.QUEST_Taken)
    self._select:SetActive(self._quest.status == QuestStatus.QUEST_Completed)

    if self._quest.status == QuestStatus.QUEST_Taken then
        self._got:SetActive(true)
        self._btn:SetActive(false)
    else
        self._got:SetActive(false)
        self._btn:SetActive(true)

        if self._quest.status <= QuestStatus.QUEST_Accepted then --未完成
            self._btnTex.color = Color(1, 1, 1)
            btnTex = StringTable.Get("str_quest_base_go_to")
            icon = "task_richang_icon1"
            img = "task_richang_btn1"
        elseif self._quest.status == QuestStatus.QUEST_Completed then --未领取
            btnTex = StringTable.Get("str_quest_base_get")
            icon = "task_richang_icon2"
            img = "task_richang_btn2"
            self._btnTex.color = Color(46 / 255, 46 / 255, 46 / 255)
        end
        self._btnTex:SetText(btnTex)
        self._btnImg.sprite = self._atlas:GetSprite(img)
        self._btnIcon.sprite = self._atlas:GetSprite(icon)
    end

    local reward = self._quest.rewards
    self._awardPool:SpawnObjects("UIQuestSmallAwardItem", table.count(reward))
    local awards = self._awardPool:GetAllSpawnList()
    local awardsList = self._quest.rewards
    for i = 1, table.count(awardsList) do
        awards[i]:SetData(i, awardsList[i], self._itemCallback, UIItemScale.Level3)
    end
end

function UIQuestDailyListItem:btnOnClick()

    if self._quest.quest_id == UIQuestDailySpecialType.DoOneDispatch or self._quest.quest_id == UIQuestDailySpecialType.DoThreeDispatch then 
        local aircraftModule = self:GetModule(AircraftModule)
        local unLock = aircraftModule:GetRoomByRoomType(AirRoomType.DispatchRoom)
        if not unLock then 
            ToastManager.ShowToast(StringTable.Get("str_function_lock_dispatchroom_unlock"))
            return
        end
    end

    if self._quest.status <= QuestStatus.QUEST_Accepted then --未完成
        ---@type UIJumpModule
        local jumpModule = self._module.uiModule
        if jumpModule == nil then
            Log.fatal("[quest] error --> uiModule is nil ! --> jumpModule")
            return
        end
        --FromUIType.NormalUI
        local fromParam = {}
        table.insert(fromParam, QuestType.QT_Daily)
        jumpModule:SetFromUIData(FromUIType.NormalUI, "UIQuestController", UIStateType.UIMain, fromParam)
        local jumpType = self._quest.JumpID
        local jumpParams = self._quest.JumpParam
        jumpModule:SetJumpUIData(jumpType, jumpParams)
        jumpModule:Jump()
    elseif self._quest.status == QuestStatus.QUEST_Completed then --未领取
        if self._callback then
            self._callback(self._quest)
        end
    end
end
