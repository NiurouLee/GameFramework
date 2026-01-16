---@class UIQuestSideListItem:UICustomWidget
_class("UIQuestSideListItem", UICustomWidget)
UIQuestSideListItem = UIQuestSideListItem

function UIQuestSideListItem:OnShow(uiParams)
    self._animation = self:GetUIComponent("Animation", "UIQuestSideListItem")
    --每列显示的行数
    self._itemCountPerRow = 1
    self._questModule = GameGlobal.GetModule(QuestModule)
    if self._questModule == nil then
        Log.fatal("[quest] error --> self._questModule is nil !")
        return
    end
end

---@param callback function 记录点击下标
function UIQuestSideListItem:SetData(index, quest, callback, awardClick, isIntro)
    if self._introTask then
        GameGlobal.TaskManager():KillTask(self._introTask)
    end

    self:_GetComponents()

    self._index = index
    self._data = quest:QuestInfo()

    if callback then
        self._callback = callback
    end
    if awardClick then
        self._awardClick = awardClick
    end

    self._target = self._data.QuestDesc
    self._items = self._data.rewards

    self:_OnValue()

    if isIntro and (not self._isIntroPlayed) then
        self._introTask =
            GameGlobal.TaskManager():StartTask(
                function(TT)
                    self._isIntroPlayed = true
                    self._animation:Stop()
                    YIELD(TT, (index - 1) * 50)
                    if self._isIntroPlayed then
                        self._animation:Play("uieff_Quest_SideListItem_In")
                    end
                    self._introTask = nil
                end
            )
    end
end

function UIQuestSideListItem:_RefrenshInfo()
    self._target = self._data.QuestDesc
    self._items = self._data.rewards

    self:_OnValue()
end

function UIQuestSideListItem:_GetComponents()
    self._targetTex = self:GetUIComponent("UILocalizationText", "targetTex")

    self._revolvingText = self:GetUIComponent("RevolvingTextWithDynamicScroll", "revolvingText")

    self._targetValueImg = self:GetUIComponent("Image", "targetValueImg")
    self._targetValueTex = self:GetUIComponent("UILocalizationText", "targetValueTex")

    self._awardPool = self:GetUIComponent("UISelectObjectPath", "awardPool")

    self._gotoGo = self:GetGameObject("GoTo")
    self._getGo = self:GetGameObject("Get")
end

function UIQuestSideListItem:_OnValue()
    self._gotoGo:SetActive(false)
    self._getGo:SetActive(false)
    if self._data.status == QuestStatus.QUEST_Accepted then
        self._gotoGo:SetActive(true)
    elseif self._data.status == QuestStatus.QUEST_Completed then
        self._getGo:SetActive(true)
    else
        Log.error(
            "###[Quest] get a quest , state is error , state --> ",
            self._data.status,
            "|quest id  --> ",
            self._data.quest_id
        )
    end

    local rate = self._data.cur_progress / self._data.total_progress
    self._targetValueImg.fillAmount = rate

    --[[

        local leftStr
        if self._data.status > QuestStatus.QUEST_Accepted then
            leftStr = "<color=#ff563a>" .. self._data.cur_progress .. "</color>"
        else
            leftStr = "<color=#eeeeee>" .. self._data.cur_progress .. "</color>"
        end
        ]]
    local progress = ""
    if self._data.ShowType == 1 then
        local c, d = math.modf(self._data.cur_progress * 100 / self._data.total_progress)
        if c < 1 and d > 0 then
            c = 1
        end
        progress = c .. "%"
    else
        progress = self._data.cur_progress .. "/" .. self._data.total_progress
    end
    self._targetValueTex:SetText(progress)

    self._targetTex:SetText(StringTable.Get(self._target))

    self._revolvingText:OnRefreshRevolving()

    self._awardPool:SpawnObjects("UIQuestSmallAwardItem", table.count(self._items))
    local pools = self._awardPool:GetAllSpawnList()
    for i = 1, table.count(self._items) do
        pools[i]:SetData(i, self._items[i], self._awardClick, UIItemScale.Level3)
    end
end

function UIQuestSideListItem:GetOnClick()
    if self._callback then
        self._callback(self._data)
    end
end

function UIQuestSideListItem:GoToOnClick()
    ---@type UIJumpModule
    local jumpModule = self._questModule.uiModule
    if jumpModule == nil then
        Log.fatal("[quest] error --> uiModule is nil ! --> jumpModule")
        return
    end

    --FromUIType.NormalUI
    local fromParam = {}
    table.insert(fromParam, QuestType.QT_Branch)
    jumpModule:SetFromUIData(FromUIType.NormalUI, "UIQuestController", UIStateType.UIMain, fromParam)
    local jumpType = self._data.JumpID
    local jumpParams = self._data.JumpParam
    jumpModule:SetJumpUIData(jumpType, jumpParams)
    jumpModule:Jump()
end

function UIQuestSideListItem:OnHide()
    self._isIntroPlayed = false
end
