--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    UIStateManager：UI状态管理器
    管理UI状态以及UI窗口管理器。

    UI状态(UIState)：第0层，可以有多个UIController，例如游戏的登录界面、主界面等。这类窗口的特点是在游戏的底层，且比较固定。
        切UI状态的请求若遇到正在切UI状态会被丢弃。
    Dialog窗口(UIController)：是指第1层及以上的窗口，模态窗口，适用于游戏的对话框窗口，例如背包、设置界面等。这类窗口的特点是在游戏的上层，且切换频繁。
        Dialog请求不会被丢弃都会等待UI框架处理锁结束再处理，但是客户端一旦进入登出状态，无论是之前正在等待处理的Dialog请求还是此时的Dialog请求，都会被丢弃直到登出状态结束。

    关于UI框架 处理状态切换 的锁：以下5种状态从请求到被处理完成都会阻塞用户输入。
    UI框架请求锁(简称请求锁)表示在请求发起到被处理前的过程中会触发UI Lock，阻塞用户输入；UI框架处理锁(简称处理锁)表示在处理到结束的过程中会触发UI Lock，阻塞用户输入。

    1、UIState切换：请求锁是"UIStateSwitch"，处理锁是"__framework_switch_lock__"。请求当前只能有一个。
    2、ShowDialog：请求锁是"OpenDialog"..uiName，处理锁是"__framework_switch_lock__"。请求可以有多个，等待处理锁解开再处理。
    3、CloseDialog：请求锁是"CloseDialog"..uiName，处理锁是"__framework_switch_lock__"。请求可以有多个，等待处理锁解开再处理。
    UI State切换、OpenDialog、CloseDialog这三个状态是不允许同时出现的。

    以下为MessageBox相关锁(关于它的说明具体见PopupManager)，在有处理锁的时候，允许有弹出/关闭MessageBox请求。
    但是等待处理锁解开再处理，优先级高的poup(比如弱网popup)不受限制。也就是说上面三种状态会影响popup的处理时间。
    4、ShowPopup：从请求发起到被处理完，会触发UI Lock "OpenPopup"..uiMsgBoxName。
    5、ClosePopup：从请求发起到被处理完，会触发UI Lock "ClosePopup"..uiMsgBoxName。
**********************************************************************************************
]]
--------------------------------------------------------------------------------------------

---@class UIStateManager:Object
_class("UIStateManager", Object)
UIStateManager = UIStateManager

local UI_STATE_SWITCH_LOCK_NAME = "UIStateSwitch"
local OPEN_DIALOG_LOCK_NAME = "OpenDialog"
local CLOSE_DIALOG_LOCK_NAME = "CloseDialog"
local OPEN_POPUP_LOCK_NAME = "OpenPopup"
local CLOSE_POPUP_LOCK_NAME = "ClosePopup"

--region 初始化/销毁
function UIStateManager:Constructor(request)
    local uiControllerMng = UIControllerManager:New(request)
    self.uiControllerManager = uiControllerMng
    self.registeredStateDic = {}
    self.stateStack = Stack:New()
    self.isStateStackDirty = false

    self.lastStateType = UIStateType.Invalid
    ---@type UIState
    self.curState = nil

    ---@type UIState
    self.nextState = nil
    self.uiParams = nil
    self.nextDialogListInfo = nil

    self.stackStateInfoCache = Stack:New()
    --该列表中的UIstate会清理所有UI缓存
    self.clearCacheUIList = {"UIAircraftController", "UIBattle", "UIHomelandMain", "UILoginEmpty"}

    -- UI窗口注册
    for k, v in pairs(UIRegister.registeredUIs) do
        uiControllerMng:RegisterUI(k, v.uiPrefab, v.maskType, v.hideUnderLayer, v.loadDataBeforeSwitch, v.uiComponents)
    end
    -- UI状态注册
    UIStateRegister.Register(self)
    -- UI扩展管理器注册
    UIExtendManagerRegister:RegisterUIExtendManagers(uiControllerMng)

    self.logouting = false --这个参数很重要，表示客户端正在处理登出
end

function UIStateManager:Reset()
    --清理之前的UIState栈
    self:ClearState()
end

function UIStateManager:Dispose()
    if self.curState then
        self.curState:Dispose()
    end
    self.uiControllerManager:Dispose()
end

--endregion

--region 注册信息
---@param uiStateType UIStateType
---@param uiState UIState
function UIStateManager:RegisterUIState(uiStateType, uiState, bScreenshot)
    if (self.registeredStateDic[uiStateType] == nil) then
        uiState:Init(uiStateType, self.uiControllerManager)
        if (bScreenshot == true) then
            uiState:SetExitScreenShot(true)
        end
        self.registeredStateDic[uiStateType] = uiState
    end
end

function UIStateManager:GetUIRegisterInfo(ui_name)
    return self.uiControllerManager:GetUIRegisterInfo(ui_name)
end

--endregion
function UIStateManager:GetLastStateType()
    return self.lastStateType
end

--region UI锁
function UIStateManager:Lock(name)
    self.uiControllerManager:Lock(name)
end

function UIStateManager:UnLock(name)
    self.uiControllerManager:UnLock(name)
end

function UIStateManager:ExpirationLock(name, lockMs)
    self.uiControllerManager:ExpirationLock(name, lockMs)
end

function UIStateManager:CancelExpirationLock(name)
    self.uiControllerManager:CancelExpirationLock(name)
end

function UIStateManager:ShowBusy(flag)
    Log.debug("[busy] ShowBusy", flag, Log.traceback())
    self.uiControllerManager:ShowBusy(flag)
end

function UIStateManager:ClearBusy()
    Log.debug("[busy] ClearBusy", Log.traceback())
    self.uiControllerManager:ClearBusy()
end

function UIStateManager:UnLockAll()
    self.uiControllerManager:UnLockAll()
end

function UIStateManager:IsLocked()
    return self.uiControllerManager:IsLocked()
end

function UIStateManager:GetSwitchLock()
    return self.uiControllerManager:GetSwitchLock()
end

function UIStateManager:LockedSize()
    return self.uiControllerManager:LockedSize()
end

function UIStateManager:SetBlackSideVisible(visible, force)
    self.uiControllerManager:SetBlackSideVisible(visible, force)
end

function UIStateManager:SetForceCloseBlackSideVisible(visible)
    self.uiControllerManager:SetForceCloseBlackSideVisible(visible)
end

function UIStateManager:SetForceCloseBlackSideVisible(visible)
    self.uiControllerManager:SetForceCloseBlackSideVisible(visible)
end

--endregion

--region UIState
---预加载UIState
---@param uiStateType UIStateType
function UIStateManager:PreLoadState(TT, uiStateType)
    ---@type UIState
    local state = self.registeredStateDic[uiStateType]
    if state then
        state:PreLoad(TT)
    end
end

---切换到新UI状态，且当前UI状态入栈
---@param uiStateType UIStateType
---@vararg System.Object
function UIStateManager:PushAndSwitchState(uiStateType, ...)
    if self.nextState ~= nil then
        Log.warn(
            "[UI] UIStateManager:PushAndSwitchState ",
            uiStateType,
            " Error, UIState ",
            self.nextState:GetType(),
            " is switching"
        )
        return
    end

    if uiStateType == self:CurUIStateType() then
        self:SwitchState(uiStateType, ...)
        return
    end

    if self:IsInStateStackBottom(uiStateType) then
        self:ClearState()
        self:SwitchState(uiStateType, ...)
        return
    end

    Log.sys("[UI] UIStateManager:PushAndSwitchState: ", uiStateType)
    self.nextState = self.registeredStateDic[uiStateType]
    if self.nextState then
        self:Lock(UI_STATE_SWITCH_LOCK_NAME)
        if self.curState then
            local curStateInfo = StateStackInfo:New(self.curState, self.uiParams)
            local nextStateType = self.nextState:GetType()
            self.isStateStackDirty = true
            if self:ContainsUIState(nextStateType) then -- 如果栈内此时已经有目标UI状态,先移除目标状态
                self.stackStateInfoCache:Clear()

                while self.stateStack:Size() > 0 do
                    local popState = self.stateStack:Pop()
                    if popState.uiState:GetType() == nextStateType then -- yqqtodo 效率
                        break
                    else
                        self.stackStateInfoCache:Push(popState)
                    end
                end

                while self.stackStateInfoCache:Size() > 0 do
                    local info = self.stackStateInfoCache:Pop()
                    self.stateStack:Push(info)
                end

                self:PushToStateStack(curStateInfo)
            else
                self:PushToStateStack(curStateInfo)
            end
        end
        self.uiParams = { ... }
    end
end

---切换到新UI状态
---@param uiStateType UIStateType
---@vararg System.Object
function UIStateManager:SwitchState(uiStateType, ...)
    if self.nextState then
        Log.warn(
            "[UI] UIStateManager:SwitchState ",
            uiStateType,
            " Error, UIState ",
            self.nextState:GetType(),
            " is switching"
        )
        return
    end

    Log.sys("[UI] UIStateManager:SwitchState, ", uiStateType)
    if self:ContainsUIState(uiStateType) then --目标State在栈里，修改接口
        self:PopStateTo(uiStateType, true)
        return
    end

    self.nextState = self.registeredStateDic[uiStateType]
    if self.nextState then
        self:Lock(UI_STATE_SWITCH_LOCK_NAME)
        self.uiParams = { ... }
    end
end

---切换到新UI状态
---@param uiStateType UIStateType
---@param dialogList OpenDialogListInfo
---@vararg System.Object
function UIStateManager:SwitchStateWithDialogList(uiStateType, dialogList, ...)
    if self.nextState then
        Log.warn(
            "[UI] UIStateManager:SwitchState ",
            uiStateType,
            " Error, UIState ",
            self.nextState:GetType(),
            " is switching"
        )
        return
    end

    Log.sys("[UI] UIStateManager:SwitchState, ", uiStateType)
    if self:ContainsUIState(uiStateType) then --目标State在栈里，修改接口
        self:PopStateTo(uiStateType, true)
        return
    end

    self.nextState = self.registeredStateDic[uiStateType]
    if self.nextState then
        self.nextDialogListInfo = dialogList
        self:Lock(UI_STATE_SWITCH_LOCK_NAME)
        self.uiParams = { ... }
    end
end

---@private
---慎用！！！专为弱网登出使用！
---此时caller已被reset，协程函数会陆续返回，所以上次的任务(无论是切状态还是切Dialog)都会完成。
---1、登出的时候若遇到正在切换UI状态，等待其切换完再处理切到login状态。
---2、登出的时候若遇到正在打开Dialog，等待Dialog处理完再处理切到login状态。
---3、登出的时候，正在等待的Dialog请求都会丢弃。
---4、登出的时候，新的Dialog请求若先处理，那么打开再随着切到login状态而关闭；若优先处理切到login状态，则新的Dialog请求会在等待时被丢弃。

---5、若协程返回的时候有请求切换UI状态，会失败。
---6、若协程返回的时候有请求Dialog，同4
function UIStateManager:ForceSwitchState(TT, uiStateType, ...)
    Log.sys("[UI] UIStateManager:ForceSwitchState, ", uiStateType)
    self.logouting = true
    --有正在切换的状态，等待之
    --这个函数是被弱网登出调用，到这里即使是之前的网络协程请求也是会返回的了，所以等待是有意义的
    while self.nextState do
        YIELD(TT)
    end

    self.nextState = self.registeredStateDic[uiStateType]
    if self.nextState then
        self:Lock(UI_STATE_SWITCH_LOCK_NAME)
        self.uiParams = { ... }
    end
end

---切换到上一个UI状态，且从栈中Pop掉
function UIStateManager:PopState(...)
    if self.nextState then
        Log.warn("[UI] UIStateManager:PopState Error, UIState ", self.nextState:GetType(), " is switching")
        return
    end

    Log.sys("[UI] UIStateManager:PopState")
    if self.stateStack:Size() > 0 then
        self.isStateStackDirty = true
        local stateInfo = self.stateStack:Pop()
        self.nextState = stateInfo.uiState
        self.uiParams = (GameHelper.IsNull(...) and stateInfo.uiParams or { ... })
        self:Lock(UI_STATE_SWITCH_LOCK_NAME)
    else
        Log.fatal("[UI] UIStateManager:PopState Error, Stack is empty")
    end
end

function UIStateManager:PopStateTo(uiStateType, doSwitch, ...)
    return GameGlobal.TaskManager():StartTask(UIStateManager.PopStateToImp, self, uiStateType, doSwitch, ...)
end

---@private
function UIStateManager:ClearState()
    self.isStateStackDirty = true
    self.stateStack:Clear()
end

--endregion

--region UI Dialog
---Dialog请求默认情况下都是会等待直到解锁就可以处理
---但是如果开始处理登出了，不管是之前在等待的Dialog还是登出中请求的Dialog都会丢弃，直到登出结束！

---@param uiName string
function UIStateManager:ShowDialog(uiName, ...)
    return GameGlobal.TaskManager():StartTask(UIStateManager.ShowDialogImp, self, uiName, ...)
end

---@param uiName string
function UIStateManager:CloseDialog(uiName)
    return GameGlobal.TaskManager():StartTask(UIStateManager.CloseDialogImp, self, uiName)
end

--endregion

--region Popup相关接口
---@private
---@param uiMsgBoxName string
---@return UIMessageBox
function UIStateManager:GetUIMessageBox(TT, uiMsgBoxName, isShow)
    return self.uiControllerManager:GetUIMessageBox(TT, uiMsgBoxName, isShow)
end

function UIStateManager:CheckMessageBoxCameraStatus(isShow)
    self.uiControllerManager:CheckMessageBoxCameraStatus(isShow)
end

function UIStateManager:SetGuideMessageBoxParent(view, uiName)
    self.uiControllerManager:SetGuideMessageBoxParent(view, uiName)
end

function UIStateManager:HasPopup()
    return self.uiControllerManager:HasPopup()
end

---@return PopupPriority
function UIStateManager:GetCurShowingPriority()
    return self.uiControllerManager:GetCurShowingPriority()
end

function UIStateManager:ClearPopup()
    return GameGlobal.TaskManager():StartTask(UIControllerManager.ClearPopup, self.uiControllerManager)
end

---@param value PopupPriority 有值则会设置
---@param bOnlyFilter boolean 是否仅过滤掉popup不重置优先级过滤器的值（默认false）
---@return PopupPriority
function UIStateManager:PopupPriorityFilter(value, bOnlyFilter)
    bOnlyFilter = bOnlyFilter or false
    if value then
        GameGlobal.TaskManager():StartTask(
            UIControllerManager.SetPopupPriorityFilter,
            self.uiControllerManager,
            value,
            bOnlyFilter
        )
    else
        return self.uiControllerManager:GetPopupPriorityFilter()
    end
end

---@param popup Popup
function UIStateManager:ShowPopup(popup)
    local uiMsgBoxName = popup.uiMsgBoxName
    Log.debug("[UIPopup] UIStateManager:ShowPopup,", uiMsgBoxName)
    return GameGlobal.TaskManager():StartTask(UIStateManager.ShowPopupImp, self, uiMsgBoxName, popup)
end

---@param popup Popup
function UIStateManager:ClosePopup(popup)
    local uiMsgBoxName = popup.uiMsgBoxName
    Log.debug("[UIPopup] UIStateManager:ClosePopup,", uiMsgBoxName)
    return GameGlobal.TaskManager():StartTask(UIStateManager.ClosePopupImp, self, uiMsgBoxName, popup)
end

--endregion

--region 其他对外接口
---@private
function UIStateManager:Update(deltaTimeMS)
    if self.nextState and not self.uiControllerManager:GetSwitchLock() then
        local targetState = self.nextState

        self:UnLock(UI_STATE_SWITCH_LOCK_NAME)
        GameGlobal.TaskManager():StartTask(UIStateManager.DoSwitchState, self, targetState, self.uiParams)
    end
    self.uiControllerManager:Update(deltaTimeMS)
    -- self:LogUIStateStackWhenDirty() --不准取消注释！
end

---@return UIStateType
function UIStateManager:CurUIStateType()
    if self.curState ~= nil then
        return self.curState:GetType()
    end
    return UIStateType.Invalid
end

function UIStateManager:ShowCurUIState(flag)
    if self.curState then
        self.curState:Show(flag)
    end
end

function UIStateManager:IsShow(uiName)
    return self.uiControllerManager:IsShow(uiName)
end

function UIStateManager:IsTopUI(uiName)
    return self.uiControllerManager:IsTopUI(uiName)
end

---@private
function UIStateManager:GetController(uiName)
    return self.uiControllerManager:GetController(uiName)
end

function UIStateManager:GetControllerCamera(uiName)
    return self.uiControllerManager:GetControllerCamera(uiName)
end

---@private
---把UI挂载到TopDepth层
---@generic T : UIBase
---@param ui T UI类型
function UIStateManager:SetTopParent(ui)
    return self.uiControllerManager:SetTopParent(ui)
end

---@private
---把UI挂载到HighDepth层
---@generic T : UIBase
---@param ui T UI类型
function UIStateManager:SetHighParent(ui)
    return self.uiControllerManager:SetHighParent(ui)
end

---@generic T : UIExtendManager
---@param type T UI扩展管理器类型
---@return T UI扩展管理器类型
function UIStateManager:GetExtendManager(type)
    return self.uiControllerManager:GetExtendManager(type)
end

--endregion

--region UI窗口之间交互的接口
function UIStateManager:CallUIMethod(uiName, methodName, ...)
    return self.uiControllerManager:CallUIMethod(uiName, methodName, ...)
end

--endregion

--region private
---@private
---@param nextState UIState
function UIStateManager:DoSwitchState(TT, nextState, params)
    while self.uiControllerManager:GetSwitchLock() do
        YIELD(TT)
    end
    local bScreenShot = false
    self.uiControllerManager:SetSwitchLock(true)
    if (self.curState ~= nil) then
        self.lastStateType = self.curState:GetType()
        bScreenShot = self.curState:GetExitScreenShot()
    else
        self.lastStateType = UIStateType.Invalid
    end
    if bScreenShot then
        UISwitchImgManager.Show()
    end
    GameObjectHelper.UnLoadUnUsedAsset()
    -- 0、Try Show UI
    local res = UIStateSwitchReq:New()
    --重置节点状态 todo可以保留相同元素的状态
    self.uiControllerManager:ResetAllLayerVisble()
    nextState:TryEnter(TT, self.curState, res, params, self.nextDialogListInfo)

    if res:GetSucc() then
        --这里判断是否卸载缓存资源
        local forceClearCache = false
        for _, clearCacheUIName in pairs(self.clearCacheUIList) do
            local defaultUIList = nextState:GetDefaultUIList()
            for i = 1, #defaultUIList do
                local name = defaultUIList[i]
                if name == clearCacheUIName then
                    forceClearCache = true
                    break
                end
            end
        end
        self.uiControllerManager:SetForceClearCache(forceClearCache)
        if self.curState then
            -- 这里卸载掉的是新状态里没有的UI(新旧状态重复的UI，不会卸载，但依旧走隐藏流程)
            self.curState:Exit(TT, nextState)
        end
        self.uiControllerManager:SetForceClearCache(false)
        -- 把加载场景挪到这里，是考虑UI切换视角效果：先隐藏当前UI再切换到新UI的场景或界面
        local nextSceneName = nextState:GetSceneName()
        if not string.isnullorempty(nextSceneName) and UIHelper.GetActiveSceneName() ~= nextSceneName then
            local scene = GameGlobal.GameLogic():LoadScene(TT, nextSceneName)
            nextState:SetScene(scene)

            YIELD(TT)
            -- 这里停一帧，是为了保证UIController OnShow的时候场景对象Start完成
        end

        -- 1、Show UI
        nextState:Enter(self.curState, res, params, self.nextDialogListInfo)
        UISwitchImgManager.Hide()
        -- 2、After Show UI
        nextState:AfterEnter(TT, self.curState, res, params, self.nextDialogListInfo)

        if self.curState then
            self.curState:Dispose()
        end
        self.curState = nextState
        --只针对列表中的state进行GC操作
        if table.icontains(GCStateList, nextState:GetType()) or table.icontains(GCStateList, self.lastStateType) then
            --Log.fatal("GC!!!!!!!!!!!")
            ---切state执行gc
            HelperProxy:GetInstance():GCCollect()
            collectgarbage("collect")
            HelperProxy:GetInstance():GCCollect()
            collectgarbage("collect")
        end

        if res:GetSucc() then
            Log.debug("[UI] UIStateManager:DoSwitchState, EnterState success, ", nextState:GetType())
            GameGlobal.EventDispatcher():Dispatch(GameEventType.SwitchUIStateFinish, nextState:GetType())
        else
            Log.fatal("[UI] UIStateManager:DoSwitchState, EnterState false: ", nextState:GetType())
        end
    else
        UISwitchImgManager.Hide()
    end

    self.nextState = nil
    self.nextDialogListInfo = nil

    self.uiControllerManager:SetSwitchLock(false)
end

---@private
function UIStateManager:PopStateToImp(TT, uiStateType, doSwitch, ...)
    doSwitch = doSwitch ~= false
    if self.nextState then
        Log.warn(
            "[UI] UIStateManager:PopStateToImp ",
            uiStateType,
            " Error, UIState ",
            self.nextState:GetType(),
            " is switching"
        )
        return
    end
    Log.sys("[UI] UIStateManager:PopStateToImp: ", uiStateType)

    if not self:ContainsUIState(uiStateType) then
        Log.fatal("[UI] UIStateManager:PopStateToImp Error, cannot find type, ", uiStateType)
        return
    end

    local res = AsyncRequestRes:New()
    res:SetSucc(true)

    ---@type StateStackInfo[]
    local t = self.stateStack:ToArray()
    for i = 1, #t do
        local dest = t[i]
        if dest.uiState:GetType() == uiStateType then
            for j = 1, i do
                t[j].uiState:UnloadInvisibleUI() -- 卸载掉所有隐藏的UI yqqtodo
            end
            if doSwitch then
                self.nextState = dest.uiState
                self.uiParams = (GameHelper.IsNull(...) and dest.uiParams or { ... })
                self:Lock(UI_STATE_SWITCH_LOCK_NAME)
            end

            self.isStateStackDirty = true
            self.stateStack:Clear()
            for j = #t, i + 1, -1 do
                self.stateStack:Push(t[j])
            end
            return
        else
            dest.uiState:RevertState(TT, res)
            -- pop之前先调用RevertState
            if not res:GetSucc() then
                return
            end
        end
    end
    Log.fatal("[UI] UIStateManager:PopStateToImp Error, ", uiStateType)
end

---@private
function UIStateManager:ContainsUIState(uiStateType)
    local t = self.stateStack:ToArray()
    for i = 1, #t do
        if uiStateType == t[i].uiState:GetType() then
            return true
        end
    end
    return false
end

---@private
---检查当前栈里如果已经有该State，直接将栈里的State移到栈顶
---@param stateInfo StateStackInfo
function UIStateManager:PushToStateStack(stateInfo)
    if not stateInfo then
        return
    end

    local curStateType = stateInfo.uiState:GetType()
    if self:ContainsUIState(curStateType) then
        local targetState = nil
        local tmpStateStack = Stack:New()
        while self.stateStack:Size() > 0 do
            local popState = self.stateStack:Pop()
            if popState.uiState:GetType() == curStateType then
                targetState = popState
                break
            else
                tmpStateStack:Push(popState)
            end
        end

        while tmpStateStack:Size() > 0 do
            local info = tmpStateStack:Pop()
            self.stateStack:Push(info)
        end
        self.stateStack:Push(targetState)
    else
        self.stateStack:Push(stateInfo)
    end
end

---@private
function UIStateManager:IsInStateStackBottom(uiStateType)
    local t = self.stateStack:ToArray()
    if t then
        local count = #t
        if count > 0 then
            return t[count].uiState:GetType() == uiStateType
        end
    end
    return false
end

---@private
local oldStr
function UIStateManager:LogUIStateStackWhenDirty()
    if self.isStateStackDirty then
        local str = ""
        local t = self.stateStack:ToArray()
        for i = 1, #t do
            ---@type StateStackInfo
            local value = t[i]
            str = str .. value.uiState:GetType() .. ","
        end
        if oldStr ~= str then
            oldStr = str
            Log.fatal("------------------ ", str)
        end
    end
end

---@private
function UIStateManager:ShowDialogImp(TT, uiName, ...)
    local lockName = OPEN_DIALOG_LOCK_NAME .. uiName
    self:Lock(lockName)
    while self.uiControllerManager:GetSwitchLock() do
        if self.logouting then --这意味着Dialog请求遇到登出状态会被丢弃
            self:UnLock(lockName)
            return
        end
        YIELD(TT)
    end
    self:UnLock(lockName)
    if self.curState then
        return self.curState:ShowDialog(TT, uiName, ...)
    end
end

---@private
function UIStateManager:CloseDialogImp(TT, uiName)
    local lockName = CLOSE_DIALOG_LOCK_NAME .. uiName
    self:Lock(lockName)

    while self.uiControllerManager:GetSwitchLock() do
        if self.logouting then --这意味着Dialog请求遇到登出状态会被丢弃
            self:UnLock(lockName)
            return
        end
        YIELD(TT)
    end
    self:UnLock(lockName)
    if self.curState then
        return self.curState:CloseDialog(TT, uiName)
    end
end

---@private
---@param uiMsgBoxName string
---@param popup Popup
local popupRequestID = 0
function UIStateManager:ShowPopupImp(TT, uiMsgBoxName, popup)
    popupRequestID = popupRequestID + 1
    local lockName = OPEN_POPUP_LOCK_NAME .. uiMsgBoxName .. popupRequestID
    self:Lock(lockName)

    while PopupManager:GetInstance():GetSwitchLock() or --特殊类MessageBox(比如弱网弹框、退出游戏弹框)不受UI切换影响
        (popup.priority < PopupPriority.Network and self.uiControllerManager:GetSwitchLock()) do
        YIELD(TT)
    end
    PopupManager:GetInstance():SetSwitchLock(true)
    PopupManager:GetInstance():OpenPopup(TT, popup)
    PopupManager:GetInstance():SetSwitchLock(false)

    self:UnLock(lockName)
end

---@private
---@param uiMsgBoxName string
---@param popup Popup
local closePopupRequestID = 0
function UIStateManager:ClosePopupImp(TT, uiMsgBoxName, popup)
    closePopupRequestID = closePopupRequestID + 1
    local lockName = CLOSE_POPUP_LOCK_NAME .. uiMsgBoxName .. closePopupRequestID
    self:Lock(lockName)

    while PopupManager:GetInstance():GetSwitchLock() or --特殊类MessageBox(比如弱网弹框、退出游戏弹框)不受UI切换影响
        (popup.priority < PopupPriority.Network and self.uiControllerManager:GetSwitchLock()) do
        YIELD(TT)
    end
    PopupManager:GetInstance():SetSwitchLock(true)
    PopupManager:GetInstance():ClosePopup(TT, popup)
    PopupManager:GetInstance():SetSwitchLock(false)

    self:UnLock(lockName)
end

---@return boolean
function UIStateManager:IsLogouting()
    return self.logouting
end

---@private
---@param value boolean
function UIStateManager:SetIsLogouting(value)
    self.logouting = value
end

function UIStateManager:GetMessageBoxCamera()
    return self.uiControllerManager:GetMessageBoxCamera()
end

function UIStateManager:GetUICameraByDepth(depth)
    return self.uiControllerManager:GetUICameraByDepth(depth)
end
--endregion

function UIStateManager:SetDepthRaycast(depth, active)
    self.uiControllerManager.layerManager.layerManagerHelper:SetDepthRaycast(depth, active)
end

---关闭指定ui外的其他ui
function UIStateManager:CloseAllDialogsExcept(exceptUIName)
    local uiList = {}
    for i = 1, self.uiControllerManager:VisibleUIList():Size() do
        local name = self.uiControllerManager:VisibleUIList():GetAt(i)
        if name ~= exceptUIName then
            uiList[#uiList + 1] = name            
        end
    end

    for i = 1, #uiList do
        local uiController = self.uiControllerManager:GetController(uiList[i])
        uiController.SkipTransitionAmin = true
        --只需要设置最底层显隐状态
        if i == 1 then
            local underLayerUIName = self.uiControllerManager:GetUnderLayerUI(uiList[i])
            self.uiControllerManager:SetUIRootActive(underLayerUIName, true)
        else
            uiController:SetHideUnderLayerFlag(false)
        end
        self:CloseDialog(uiList[i])
    end
end

function UIStateManager:CloseAllDialogOverLayerWithName(uiName, exceptUINameList)
    exceptUINameList = exceptUINameList or {}
    local underLayer = self.uiControllerManager:GetDepth(uiName)
    local uiList = {}
    for i = 1, self.uiControllerManager:VisibleUIList():Size() do
        local name = self.uiControllerManager:VisibleUIList():GetAt(i)
        local uiLayer = self.uiControllerManager:GetDepth(name)
        if uiLayer > underLayer then
            local closeDialogFlag = true
            for _, exceptUIName in pairs(exceptUINameList) do
                if name == exceptUIName then
                    closeDialogFlag = false
                end
            end
            if closeDialogFlag then
                uiList[#uiList + 1] = name     
            end 
        end
    end
    for i = 1, #uiList do
        local uiController = self.uiControllerManager:GetController(uiList[i])
        uiController.SkipTransitionAmin = true
        --只需要设置最底层显隐状态
        if i == 1 then
            local underLayerUIName = self.uiControllerManager:GetUnderLayerUI(uiList[i])
            self.uiControllerManager:SetUIRootActive(underLayerUIName, true)
        else
            uiController:SetHideUnderLayerFlag(false)
        end
        self:CloseDialog(uiList[i])
    end
end

--region StateStackInfo
---@class StateStackInfo
_class("StateStackInfo", Object)
StateStackInfo = StateStackInfo
function StateStackInfo:Constructor(uiState, uiParams)
    ---@type UIState
    self.uiState = uiState
    self.uiParams = uiParams
end

--endregion

--region UIStateSwitchReq
require("async_request_res")
---@class UIStateSwitchReq:AsyncRequestRes
_class("UIStateSwitchReq", AsyncRequestRes)
UIStateSwitchReq = UIStateSwitchReq
function UIStateSwitchReq:Constructor()
    self.loadFromDisk = true
end

--endregion
