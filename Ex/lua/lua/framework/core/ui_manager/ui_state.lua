---@class UIState
_class("UIState", Object)

--region 初始化/销毁
function UIState:Constructor(sceneName, ...)
    ---@type string[]
    self.defaultUIList = {...}

    ---@private
    self.type = UIStateType.Invalid
    self._bExitScreenShot = false
    self.sceneName = sceneName
    ---@type UIControllerManager
    self.uiControllerManager = nil
end
function UIState:Init(uiStateType, uiControllerManager)
    self.type = uiStateType
    self.uiControllerManager = uiControllerManager
end
function UIState:SetExitScreenShot(bss)
    self._bExitScreenShot = bss
end
function UIState:GetExitScreenShot()
    return self._bExitScreenShot
end
function UIState:Dispose()
    if self.scene then
        self.scene:Dispose()
        self.scene = nil
    end
end
--endregion

--region Get/Set
function UIState:GetType()
    return self.type
end
function UIState:GetSceneName()
    return self.sceneName
end
function UIState:SetSceneName(value)
    self.sceneName = value
end

function UIState:GetDefaultUIList()
    return self.defaultUIList
end

function UIState:SetScene(scene)
    self.scene = scene
end
--endregion

--region UIState
function UIState:IsShow()
    return self.uiControllerManager:IsLayerShow(0)
end

---显示/隐藏 UI状态下的窗口
function UIState:Show(flag)
    if self:IsShow() == flag then
        return
    end
    self.uiControllerManager:ShowLayer(0, flag)
end

function UIState:Exit(TT, nextState)
    local temp_deleteUIList = FastArray:New()
    local temp_hideUIList = FastArray:New()
    self:GetCloseUIList(self, nextState, temp_deleteUIList, temp_hideUIList)

    local deleteUIList = FastArray:New()
    local hideUIList = FastArray:New()
    local count = temp_deleteUIList:Size()
    for i = 1, temp_deleteUIList:Size() do
        local name = temp_deleteUIList:GetAt(count - i + 1)
        deleteUIList:PushBack(name)
    end

    count = temp_hideUIList:Size()
    for i = 1, temp_hideUIList:Size() do
        local name = temp_hideUIList:GetAt(count - i + 1)
        hideUIList:PushBack(name)
    end

    -- before hide
    local subTaskList = {}
    for i = 1, deleteUIList:Size() do
        local name = deleteUIList:GetAt(i)
        local uiController = self.uiControllerManager:GetController(name)
        uiController:SetHideUnderLayerFlag(false)
        subTaskList[#subTaskList + 1] =
            GameGlobal.TaskManager():StartTask(UIControllerManager.BeforeHideUI, self.uiControllerManager, name)
    end
    for i = 1, hideUIList:Size() do
        local name = hideUIList:GetAt(i)
        local uiController = self.uiControllerManager:GetController(name)
        uiController:SetHideUnderLayerFlag(false)
        subTaskList[#subTaskList + 1] =
            GameGlobal.TaskManager():StartTask(UIControllerManager.BeforeHideUI, self.uiControllerManager, name)
    end
    for i = 1, #subTaskList do
        JOIN(TT, subTaskList[i])
    end

    -- hide
    for i = 1, deleteUIList:Size() do
        local name = deleteUIList:GetAt(i)
        self.uiControllerManager:HideUI(name)
    end
    for i = 1, hideUIList:Size() do
        local name = hideUIList:GetAt(i)
        self.uiControllerManager:HideUI(name, true)
    end

    -- after hide

    for i = 1, deleteUIList:Size() do
        local name = deleteUIList:GetAt(i)
        self.uiControllerManager:AfterHideUI(name)
    end
    for i = 1, hideUIList:Size() do
        local name = hideUIList:GetAt(i)
        self.uiControllerManager:AfterHideUI(name, true)
    end
end

function UIState:PreLoad(TT)
    local res = UIStateSwitchReq:New()
    local defaultUIList = self.defaultUIList
    for i = 1, #defaultUIList do
        local name = defaultUIList[i]
        if not self.uiControllerManager:IsShow(name) then
            self.uiControllerManager:LoadUI(TT, name, res)
        end
    end
end

---@return UIStateSwitchReq
---@param nextDialogListInfo OpenDialogListInfo
function UIState:TryEnter(TT, curState, res, uiParams, nextDialogListInfo)
    res:SetSucc(true)
    Log.debug("[ui] UIState:TryEnter ", curState)
    local defaultUIList = self.defaultUIList
    for i = 1, #defaultUIList do
        local name = defaultUIList[i]
        Log.debug("[ui] uiControllerManager:TryShowUI start", name)
        self.uiControllerManager:TryShowUI(TT, name, res, uiParams)
        Log.debug("[ui] uiControllerManager:TryShowUI end", name)
        if not res:GetSucc() then
            Log.debug("[ui] uiControllerManager:TryShowUI error", name)
            break
        end
    end

    if res:GetSucc() then
        if nextDialogListInfo then
            local uiList = nextDialogListInfo:GetUIList()
            for i = 1, #uiList do
                self.uiControllerManager:TryShowUI(TT, uiList[i][1], res, uiList[i][2])
                local uiController = self.uiControllerManager:GetController(uiList[i][1])
                uiController:SetHideUnderLayerFlag(i == #uiList)
                if not res:GetSucc() then
                    break
                end
            end
            
            if not res:GetSucc() then
                for i = 1, #uiList do
                    local uiName = uiList[i][1]
                    if not self.uiControllerManager:IsShow(uiName) then
                        self.uiControllerManager:ForceUnLoadUI(uiName)
                    end
                end
            end
        end
    else
        Log.debug("[UI] UIState:TryEnter error", curState)
        -- 失败，则卸载掉没有显示的UI
        for i = 1, #defaultUIList do
            local name = defaultUIList[i]
            if not self.uiControllerManager:IsShow(name) then
                self.uiControllerManager:ForceUnLoadUI(name)
            -- 直接卸载预设
            end
        end
    end
end

---@param nextDialogListInfo OpenDialogListInfo
function UIState:Enter(curState, res, uiParams, nextDialogListInfo)
    -- 刚进入到UI State，默认是显示的
    self:Show(true)

    local defaultUIList = self.defaultUIList
    for i = 1, #defaultUIList do
        local name = defaultUIList[i]
        self.uiControllerManager:ShowUI(name, res, uiParams, 0)
    end
    
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateLayerTopDepth)

    if nextDialogListInfo then
        local dialogList = nextDialogListInfo:GetUIList()
        for i = 1, #dialogList do
            self.uiControllerManager:ShowUI(dialogList[i][1], res, dialogList[i][2], i)
        end
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.AfterUILayerChanged)
end

---@return UIStateSwitchReq
---@param nextDialogListInfo OpenDialogListInfo
function UIState:AfterEnter(TT, curState, res, uiParams, nextDialogListInfo)
    res:SetSucc(true)

    local subTaskList = {}
    local defaultUIList = self.defaultUIList
    for i = 1, #defaultUIList do
        local name = defaultUIList[i]
        subTaskList[#subTaskList + 1] =
            GameGlobal.TaskManager():StartTask(
            UIControllerManager.AfterShowUI,
            self.uiControllerManager,
            name,
            res,
            uiParams
        )
    end

    if nextDialogListInfo then
        local dialogList = nextDialogListInfo:GetUIList()
        for i = 1, #dialogList do
            subTaskList[#subTaskList + 1] =
                GameGlobal.TaskManager():StartTask(
                UIControllerManager.AfterShowUI,
                self.uiControllerManager,
                dialogList[i][1],
                res,
                dialogList[i][2]
            )
        end
    end

    for i = 1, #subTaskList do
        JOIN(TT, subTaskList[i])
    end
end
function UIState:RevertState(TT, res)
    res:SetSucc(true)
end

function UIState:UnloadInvisibleUI()
    local defaultUIList = self.defaultUIList
    for i = 1, #defaultUIList do
        local name = defaultUIList[i]
        if not self.uiControllerManager:IsShow(name) then
            self.uiControllerManager:ForceUnLoadUI(name)
            --直接卸载预设
        end
    end
end
--endregion

--region UI Dialog
function UIState:ShowDialog(TT, uiName, ...)
    while self.uiControllerManager:GetSwitchLock() do
        YIELD(TT)
    end

    if GameGlobal.UIStateManager():CurUIStateType() ~= self.type then
        Log.fatal("[UI] UIState:ShowDialog Error, State:", self.type, " already leave, cannot show:", uiName)
        return
    end
    self.uiControllerManager:SetSwitchLock(true)

    local uiRegisterInfo = self.uiControllerManager:GetUIRegisterInfo(uiName)
    if not uiRegisterInfo then
        Log.fatal("[UI] UIState:ShowDialog Error, UI ", uiName, " not regist")
        self.uiControllerManager:SetSwitchLock(false)
        return
    end

    local res = UIStateSwitchReq:New()
    res:SetSucc(true)

    -- 检查Dialog是否已经在顶层显示
    local isShow = self.uiControllerManager:IsShow(uiName)
    if isShow and self.uiControllerManager:IsTopUI(uiName) then
        Log.warn("[UI] UIState:ShowDialog, UI already visible at toppest:", uiName)
        self.uiControllerManager:SetSwitchLock(false)
        return
    end

    -- 检查Dialog已经显示但不在顶层（处理：从底层先关闭）
    -- 这里改成直接销毁之前的资源了，没有做资源缓存。考虑到UI预设上会挂逻辑脚本，比如动态滚动列表
    -- 如果缓存了资源，那么所有类似的脚本需要在UI重新显示前做好清理，否则重新OnShow的逻辑里可能会出问题。
    if isShow then
        self.uiControllerManager:CloseDialogWhichIsNotToppest(TT, uiName)
    end

    -- 检查Dialog层级已经占满(处理：关掉 depth 1 的Dialog,并将上层Dialog下移)
    self.uiControllerManager:CheckLayerMax(TT)

    -- 可以显示了
    local uiParams = {...}
    self.uiControllerManager:TryShowUI(TT, uiName, res, uiParams)
    if not res:GetSucc() then
        if not self.uiControllerManager:IsShow(uiName) then
            self.uiControllerManager:ForceUnLoadUI(uiName)
        -- 直接卸载预设
        end
        self.uiControllerManager:SetSwitchLock(false)
        return
    end

    --等待ui渐变完成
    while not CutsceneManager.GetSceneFlag() do
        YIELD(TT)
    end

    self.uiControllerManager:ShowUI(uiName, res, uiParams)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.AfterUILayerChanged)
    self.uiControllerManager:AfterShowUI(TT, uiName, res, uiParams)
    
    self.uiControllerManager:SetSwitchLock(false)
end
function UIState:CloseDialog(TT, uiName)
    while self.uiControllerManager:GetSwitchLock() do
        YIELD(TT)
    end
    self.uiControllerManager:SetSwitchLock(true)

    local uiRegisterInfo = self.uiControllerManager:GetUIRegisterInfo(uiName)
    if not uiRegisterInfo then
        self.uiControllerManager:SetSwitchLock(false)
        return
    end

    -- Dialog没在显示
    local isShow = self.uiControllerManager:IsShow(uiName)
    if not isShow then
        self.uiControllerManager:SetSwitchLock(false)
        Log.fatal("[UI] UIState:CloseDialog Error, UI is invisible, ", uiName)
        return
    end

    if self.uiControllerManager:IsTopUI(uiName) then
        -- 检查要关闭的UI是否在顶层
        self.uiControllerManager:HideDialog(TT, uiName)
    else
        self.uiControllerManager:CloseDialogWhichIsNotToppest(TT, uiName)
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.AfterUILayerChanged, true)

    if self.uiControllerManager:TopDepth() == 0 then
        self:Show(true)
    end

    self.uiControllerManager:SetSwitchLock(false)
end

--function UIState
--endregion

--region private

---@private
---@param curState UIState
---@param nextState UIState
---@param deleteUIList FastArray
---@param hideUIList FastArray
function UIState:GetCloseUIList(curState, nextState, deleteUIList, hideUIList)
    if curState then
        local defaultUIList = curState.defaultUIList
        for i = 1, #defaultUIList do
            local uiName = defaultUIList[i]
            if not deleteUIList:Contains(uiName) then
                deleteUIList:PushBack(uiName)
            end
        end
    end

    for i = 1, self.uiControllerManager:VisibleUIList():Size() do
        local visibleUIList = self.uiControllerManager:VisibleUIList()
        local uiName = visibleUIList:GetAt(i)
        if not deleteUIList:Contains(uiName) then
            deleteUIList:PushBack(uiName)
        end
    end

    if nextState then
        local defaultUIList = nextState.defaultUIList
        for i = 1, #defaultUIList do
            local nextUIName = defaultUIList[i]
            local cannotDel = false
            if deleteUIList:Contains(nextUIName) then
                cannotDel = true
            end
            if cannotDel then
                deleteUIList:Remove(nextUIName)
                if self.uiControllerManager:IsShow(nextUIName) then
                    hideUIList:PushBack(nextUIName)
                end
            end
        end
    end
    --当前切换为需要强制清理缓存的状态，则将缓存view添加至deleteList
    if self.uiControllerManager:GetForceClearCache() then
        local cacheUIList = self.uiControllerManager:GetCacheUIList()
        for i = 1, cacheUIList:Size() do
            local uiName = cacheUIList:GetAt(i)
            if not deleteUIList:Contains(uiName) then
                deleteUIList:PushBack(uiName)
            end
        end
    end
end
--endregion
