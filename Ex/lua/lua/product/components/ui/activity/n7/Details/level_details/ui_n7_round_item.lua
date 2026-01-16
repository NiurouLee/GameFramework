---@class UIN7RoundItem : UICustomWidget
_class("UIN7RoundItem", UICustomWidget)
UIN7RoundItem = UIN7RoundItem
--region 初始化相关
function UIN7RoundItem:Constructor()
    self._callback = nil
    self._index = 0
    self._myCfg = nil
    self._selectState = false
    self._isLast = false
end

function UIN7RoundItem:OnShow(uiParams)
    self:_GetComponent()
end

function UIN7RoundItem:_GetComponent()
    --generated--
    ---@type UnityEngine.GameObject
    self.lock = self:GetGameObject("lock")
    ---@type UnityEngine.GameObject
    self.unlock = self:GetGameObject("unlock")
    ---@type UnityEngine.GameObject
    self.select = self:GetGameObject("select")
    ---@type UnityEngine.GameObject
    self.arrowsLock = self:GetGameObject("arrowsLock")
    ---@type UnityEngine.GameObject
    self.arrowsUnlock = self:GetGameObject("arrowsUnlock")
    ---@type UILocalizationText
    self.roundNumberLockText = self:GetUIComponent("UILocalizationText", "roundNumberLockText")
    ---@type UILocalizationText
    self.roundNumberUnlockText = self:GetUIComponent("UILocalizationText", "roundNumberUnlockText")
    --generated end--
end

---@param i int
---@param myCfg cfg
---@param callback function
function UIN7RoundItem:SetData(i, myCfg, callback)
    self._index = i
    self._myCfg = myCfg
    self._callback = callback
    local state = N7RoundState.Lock
    if self.myCfg and self.myCfg.NeedMissionId == 0 then
        state = N7RoundState.UnLock
    end
    self:_SetState(state)
end
--endregion

---@private
---设置关卡状态
function UIN7RoundItem:_SetState(state)
    self.state = state
    if self.state == N7RoundState.Lock then
        self.lock:SetActive(true)
        self.unlock:SetActive(false)
        if self._isLast == false then
            self.arrowsUnlock:SetActive(false)
            self.arrowsLock:SetActive(true)
        end
    elseif self.state == N7RoundState.UnLock then
        self.lock:SetActive(false)
        self.unlock:SetActive(true)
        if self._isLast == false then
            self.arrowsUnlock:SetActive(true)
            self.arrowsLock:SetActive(false)
        end
    end
end

---@private
---点击回调
function UIN7RoundItem:_OnClickHandel()
    self:SetSelectState(true)
    if self._callback then
        self._callback(self._index)
    end
end
---@public
---设置选中状态
---@param boolean selectState
function UIN7RoundItem:SetSelectState(selectState)
    self._selectState = selectState
    self.select:SetActive(self._selectState)
end
---@public
---关闭箭头
function UIN7RoundItem:CloseArrows()
    self._isLast = true
    self.arrowsLock:SetActive(false)
    self.arrowsUnlock:SetActive(false)
end
---@public
---获取当前状态
function UIN7RoundItem:GetState()
    return self.state
end

function UIN7RoundItem:GetMissionID()
    return self._myCfg.MissionID
end

--region 按钮点击事件相关
function UIN7RoundItem:btnLockOnClick(go)
    self:_OnClickHandel()
end
function UIN7RoundItem:btnUnlockOnClick(go)
    self:_OnClickHandel()
end
--endregion
