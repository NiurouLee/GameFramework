---@class UIActivityBetweenTheChaptersAwardCell : UICustomWidget
_class("UIActivityBetweenTheChaptersAwardCell", UICustomWidget)
UIActivityBetweenTheChaptersAwardCell = UIActivityBetweenTheChaptersAwardCell

function UIActivityBetweenTheChaptersAwardCell:InitWidget()
    --generated--
    self._rootAnim = self:GetUIComponent("Animation", "_anim")
    ---@type UILocalizationText
    self._valueNumText = self:GetUIComponent("UILocalizationText", "ValueNumText")
    self._specialDayNumText = self:GetUIComponent("UILocalizationText", "SpecialDayNumText")
    ---@type UnityEngine.UI.Image
    self._selectCellBorder = self:GetUIComponent("Image", "SelectCellBorder")
    self._backGo = self:GetGameObject("back")
    self._bgNormalGo = self:GetGameObject("BgNormal")
    self._bgSpecialGo = self:GetGameObject("BgSpecial")
    self._dayAreaGo = self:GetGameObject("DayArea")

    self._valueText = self:GetUIComponent("UILocalizationText", "ValueText")
    self._specialDayText = self:GetUIComponent("UILocalizationText", "SpecialDayText")
    self._setAlphaArea = self:GetUIComponent("CanvasGroup", "SetAlphaArea")

    ---@type UnityEngine.UI.Image
    self._selectStateAreaGo = self:GetGameObject("SelectStateArea")

    ---@type UnityEngine.GameObject
    self._stateArea = self:GetGameObject("StateArea")
    self._stateGot = self:GetGameObject("StateGot")
    self._stateCanGet = self:GetGameObject("StateCanGet")
    self._stateLocked = self:GetGameObject("StateLocked")
    self._cellState = 1
    self._stateAreaGroup = {
        [ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_RECVED] = self._stateGot,
        [ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_CAN_RECV] = self._stateCanGet,
        [ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_LOCK] = self._stateLocked
    }

    ---@type UICustomWidgetPool
    self._item1 = self:GetUIComponent("UISelectObjectPath", "Item1")
    ---@type UICustomWidgetPool
    self._item2 = self:GetUIComponent("UISelectObjectPath", "item2")
    self._items = {self._item1, self._item2}

    self._itemGo1 = self:GetGameObject("Item1")
    self._itemGo2 = self:GetGameObject("item2")
    self._itemGos = {self._itemGo1, self._itemGo2}

    self._itemWidgetTb = {}
    ---@type UILocalizationText
    self._stateGotText = self:GetUIComponent("UILocalizationText", "StateGotText")
    local gotStr = StringTable.Get("str_between_chapters_received")
    self._stateGotText:SetText(gotStr)
    self._stateCanGetText = self:GetUIComponent("UILocalizationText", "StateCanGetText")
    local canGetStr = "- " .. StringTable.Get("str_between_chapters_receive") .. " -"
    self._stateCanGetText:SetText(canGetStr)

    self._eff_front = self:GetGameObject("eff_front")
    self._eff_back = self:GetGameObject("eff_back")
    self._valueNum = 1
    self:SetSelected(false)
    --generated end--
end

function UIActivityBetweenTheChaptersAwardCell:OnShow(uiParams)
    self:AttachEvent(GameEventType.OnActivityTotalAwardGot, self.OnActivityTotalAwardGot)
    self:AttachEvent(GameEventType.OnActivityTotalAwardCellSelect, self.OnActivityTotalAwardCellSelect)
    self:InitWidget()
end

function UIActivityBetweenTheChaptersAwardCell:OnHide()
    self:DetachEvent(GameEventType.OnActivityTotalAwardGot, self.OnActivityTotalAwardGot)
    self:DetachEvent(GameEventType.OnActivityTotalAwardCellSelect, self.OnActivityTotalAwardCellSelect)
end

--------------------------------------------------------------------------------
function UIActivityBetweenTheChaptersAwardCell:SetData(data, itemInfoCallback, getRewardCallback)
    self.data = data
    self._itemInfoCallback = itemInfoCallback
    self._getRewardCallback = getRewardCallback
    self:FillUi()
end

function UIActivityBetweenTheChaptersAwardCell:PlayAnimationInSequence(index)
    local delay = 0 + (index - 1) * 70
    UIWidgetHelper.PlayAnimationInSequence(self, "_anim", "_anim", "uieff_UIActivityBetweenTheChaptersAwardCell_in", delay)
end

function UIActivityBetweenTheChaptersAwardCell:FillUi()
    self:SetBg(not (self.data._state == ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_RECVED))
    self:SetState(self.data._state)
    self._valueNumText:SetText(self.data._valueNum)
    self._specialDayNumText:SetText(self.data._valueNum)
    for index, value in ipairs(self._items) do
        if self._items and self._items[index] then
            value:SpawnObject("UIActivityBetweenTheChaptersAwardItem")
            local widgets = value:GetAllSpawnList()
            for indexWidget, valueWidget in ipairs(widgets) do
                valueWidget:SetData(self.data._items[index], self._itemInfoCallback)
                table.insert(self._itemWidgetTb, valueWidget)
            end
            self._itemGos[index]:SetActive(true)
        else
            self._itemGos[index]:SetActive(false)
        end
    end
end

function UIActivityBetweenTheChaptersAwardCell:SetSelected(isSelected)
    self._selectStateAreaGo:SetActive(isSelected)
    self._backGo:SetActive(isSelected)
end

function UIActivityBetweenTheChaptersAwardCell:SetState(state)
    self._cellState = state
    if self._cellState == ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_Expired or
            self._cellState == ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_UNKNOW
    then
        self._cellState = ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_LOCK
    end
    for index, value in ipairs(self._stateAreaGroup) do
        value:SetActive(index == self._cellState)
    end
    if self._cellState == ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_RECVED then
        self:_SetAlpha(0.5)
        self:SetBg(false)
    else
        self:_SetAlpha(1)
        self:SetBg(true)
    end
end

function UIActivityBetweenTheChaptersAwardCell:SetBg(isSpecial)
    self._bgNormalGo:SetActive(not isSpecial)
    self._bgSpecialGo:SetActive(isSpecial)
    self._dayAreaGo:SetActive(true)
end
function UIActivityBetweenTheChaptersAwardCell:_SetAlpha(alpha)
    self._setAlphaArea.alpha = alpha
end

function UIActivityBetweenTheChaptersAwardCell:_CheckEff()
    local canShowEff = true
    if self._cellState == ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_RECVED then
        canShowEff = false
    end
    self._eff_front:SetActive(canShowEff)
    self._eff_back:SetActive(canShowEff)
end

function UIActivityBetweenTheChaptersAwardCell:_CellOnClick()
    if self._cellState == ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_LOCK then 
       --GameGlobal.EventDispatcher():Dispatch(GameEventType.ExplorerEnter)
       ---@type UIJumpModule
       local uiJumpModule = GameGlobal.GetUIModule(QuestModule)
       local jumpID = UIJumpType.UI_JumpMission
       local jumpParam = nil
       uiJumpModule:SetJumpUIData(jumpID, jumpParam)
       uiJumpModule:Jump()
       return 
    end 
    if self._getRewardCallback and self._cellState ~= ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_RECVED then
        self._getRewardCallback(self.data._valueNum)
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnActivityTotalAwardCellSelect, self.data._valueNum)
    self:SetState(self._cellState)
    
end

--region Event
function UIActivityBetweenTheChaptersAwardCell:BgAreaOnClick(go)
    self:_CellOnClick()
end

function UIActivityBetweenTheChaptersAwardCell:BgNormalOnClick(go)
    self:_CellOnClick()
end

function UIActivityBetweenTheChaptersAwardCell:BgSpecialOnClick(go)
    self:_CellOnClick()
end
--endregion

--region AttachEvent
function UIActivityBetweenTheChaptersAwardCell:OnActivityTotalAwardGot(index)
    if self.data._valueNum == index then
        self.data._state = ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_RECVED
        self:SetState(self.data._state)
    end
end

function UIActivityBetweenTheChaptersAwardCell:OnActivityTotalAwardCellSelect(index)
    if self.data._valueNum == index then
        self:SetSelected(true)
    else
        self:SetSelected(false)
    end
end
--endregion