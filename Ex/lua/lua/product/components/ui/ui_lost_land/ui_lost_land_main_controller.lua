---@class UILostLandMainController : UIController
_class("UILostLandMainController", UIController)
UILostLandMainController = UILostLandMainController
--[[
    玩法主界面
]]
function UILostLandMainController:OnShow(uiParams)
    self._module = GameGlobal.GetModule(LostAreaModule)
    ---@type UILostLandModule
    self._uiModule = GameGlobal.GetUIModule(LostAreaModule)
    ---@type SvrTimeModule
    self._svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    self._enterData = self._uiModule:GetEnterData()

    self:GetComponents()
    --播重置表现
    local resetTime = uiParams[1]
    if resetTime then
        self:ResetAnim()
    end
    self:OnValue()

    self:AttachEvent(GameEventType.OnLostLandTimeReset, self.OnLostLandTimeReset)
end

function UILostLandMainController:GetComponents()
    ---@type UISelectObjectPath
    local ltBtns = self:GetUIComponent("UISelectObjectPath", "btnBack")
    ---@type UICommonTopButton
    self._backBtn = ltBtns:SpawnObject("UICommonTopButton")
    self._backBtn:SetData(
        function()
            self:CloseController()
        end
    )

    self._resetGo = self:GetGameObject("reset")
    self._resetGo:SetActive(false)

    self._timerTex = self:GetUIComponent("UILocalizationText", "timerTex")

    self._enterPool = self:GetUIComponent("UISelectObjectPath", "enterPool")
end

function UILostLandMainController:CloseController()
    self:SwitchState(UIStateType.UIDiscovery)
end

--重置动画
function UILostLandMainController:ResetAnim()
    self._resetGo:SetActive(true)
    GameGlobal.Timer():AddEvent(
        3000,
        function()
            if self._resetGo then
                self._resetGo:SetActive(false)
            end
        end
    )
end

--重置动画播完了请求数据，结束后发事件
function UILostLandMainController:OnLostLandTimeReset()
    self:OnValue()
end

function UILostLandMainController:OnValue()
    self:InitTimer()
    self:InitEnterData()
end

--难度入口
function UILostLandMainController:InitEnterData()
    local count = #self._enterData
    self._enterPool:SpawnObjects("UILostLandMainItem", count)
    ---@type UILostLandMainItem[]
    self._enterPools = self._enterPool:GetAllSpawnList()
    for i = 1, #self._enterPools do
        local item = self._enterPools[i]
        item:SetData(
            i,
            self._enterData[i],
            function(idx)
                self:EnterItemClick(idx)
            end
        )
    end
end

--点击难度
function UILostLandMainController:EnterItemClick(idx)
    ---@type UILostLandEnterData
    local enterData = self._enterData[idx]
    local state = enterData:GetLockState()
    if state == UILostLandEnterLockType.UNLOCK then
        -- 已解锁
        PopupManager.Alert(
            "UICommonMessageBox",
            PopupPriority.Normal,
            PopupMsgBoxType.OkCancel,
            "",
            StringTable.Get("str_lost_land_choose_enter_pop_tips"),
            function(param)
                Log.debug("###[UILostLandMainController] 难度选择", idx)
                self:ChooseEnter(enterData)
            end,
            nil,
            function(param)
                Log.debug("###[UILostLandMainController] 取消难度选择")
            end,
            nil
        )
    elseif state == UILostLandEnterLockType.CANUNLOCK then
        -- 未解锁，可以解锁
        self:UnLockEnter(idx)
    elseif state == UILostLandEnterLockType.LOCK then
        -- 不可解锁
        ToastManager.ShowToast(StringTable.Get("str_lost_land_enter_lock_tips"))
    elseif state == UILostLandEnterLockType.CHOOSE then
        self:ChooseEnter(enterData)
    end
end

--选择了难度
function UILostLandMainController:ChooseEnter(enterdata)
    self._uiModule:ChooseEnter(enterdata)
end
--解锁了难度
function UILostLandMainController:UnLockEnter(idx)
    Log.debug("###[UILostLandMainController] 开始解锁 idx --> ", idx)
    GameGlobal.TaskManager():StartTask(self._OnUnLockEnter, self, idx)
end
function UILostLandMainController:_OnUnLockEnter(TT, idx)
    local enterData = self._enterData[idx]
    local unlockid = enterData:GetEnterID()
    local res = self._module:RequestLostAreaUnlockOnedifficulty(TT, unlockid)
    if res:GetSucc() then
        Log.debug("###[UILostLandMainController] 解锁成功")
        --刷新数据
        self._enterData[idx]:UnLock()
        self._enterPools[idx]:FlushData(self._enterData[idx])
    else
        Log.debug("###[UILostLandMainController] 解锁失败,res-->", res:GetResult())
    end
end

function UILostLandMainController:OnHide()
    if self._timerEvent then
        GameGlobal.Timer():CancelEvent(self._timerEvent)
        self._timerEvent = nil
    end
end

--计时器
function UILostLandMainController:InitTimer()
    --重置点
    self._resetTime = self._uiModule:GetResetTime()

    -- body
    if self._timerEvent then
        GameGlobal.Timer():CancelEvent(self._timerEvent)
        self._timerEvent = nil
    end
    self._timerEvent =
        GameGlobal.Timer():AddEventTimes(
        1000,
        TimerTriggerCount.Infinite,
        function()
            self:SetTimerTex()
        end
    )
    self:SetTimerTex()
end
function UILostLandMainController:SetTimerTex()
    local svrTime = math.floor(self._svrTimeModule:GetServerTime() * 0.001)
    local sec = self._resetTime - svrTime
    if sec < 0 then
        self:TimeReset()
    else
        local timeTex = self._uiModule:Time2Tex(sec)
        self._timerTex:SetText(StringTable.Get("str_lost_land_reset_time_tips", timeTex))
    end
end
--重置
function UILostLandMainController:TimeReset()
    Log.debug("###[UILostLandMainController] 时间到，迷失之地重置")

    if self._timerEvent then
        GameGlobal.Timer():CancelEvent(self._timerEvent)
        self._timerEvent = nil
    end

    self:ResetAnim()

    self._uiModule:ResetTime(UILostLandResetTimeDialog.Main)
end

function UILostLandMainController:weekBtnOnClick()
    self:ShowDialog("UILostLandWeekInfoController")
end
