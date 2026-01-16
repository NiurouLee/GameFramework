--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    UI窗口继承的基类
    打开时创建，目前关闭时销毁
    关联一个UIView，封装了和View的交互
**********************************************************************************************
]] --------------------------------------------------------------------------------------------
require("game_event_listener")

---@class UIController : GameEventListener
_class("UIController", GameEventListener)

--region 常量
local TABLE_CLEAR = table.clear
--endregion

--region 初始化/销毁
function UIController:Constructor(ui_root_transform)
    -- 该UI打开时第一次加载的View
    self.view = nil
    self.name = nil
    self.depth = 0
    self.maskType = MaskType.MT_None
    self.hideUnderLayer = HideUnderLayerType.Dont_Hide
    ---@type SortedDictionary
    self.components = SortedDictionary:New()
    ---@type UIDefaultComponent
    self.defaultComponent = UIDefaultComponent:New()
    self.defaultComponent:Init(self, nil)
    ---@type table
    self.componentParams = {}
    ---@type FastArray
    self.ondepthChanges = FastArray:New()

    -- GameEvent
    ---@type FastArray<GameEventType>
    self.attachedEventTypes = nil
    ---@type table<string, Callback>
    self.type2Callbacks = nil

    -- 缓存的用于动态加载脚本的UICustomWidgetPool
    ---@type table<string, UICustomWidgetPool>
    self.key2CustomWidgetPools = {}

    self.resRequest = nil
    -- 缓存的主动动态加载的 Unity Assets/GameObject资源
    self.name2Assets = {}
    self.go2ResRequest = {}
    -- 缓存的UI View上提前编辑关联的 GameObject/组件
    self.gameobject = nil
    self.name2Gameobjects = {}
    self.type2ComponentTable = {}
    --是否执行底层UI隐藏检测
    self.hideUnderLayerFlag = true

    --- product append
    -- UIEventTrigger
    self.uiEventTriggers = {}
    self.uiCustomEventListener = UICustomUIEventListener:New()
end

function UIController:Dispose()
    -- 清理各种事件
    self.ondepthChanges = nil
    self.attachedEventTypes = nil
    self.type2Callbacks = nil

    -- 缓存的Unity Assets资源
    self.name2Assets = nil
    self.name2ObjRequests = nil

    -- 清空缓存的Unity相关的GameObject和Component
    self.gameobject = nil
    self.name2Gameobjects = nil
    self.type2ComponentTable = nil
    self.components = nil
    self.defaultComponent = nil
    self.componentParams = nil
    self.key2CustomWidgetPools = nil
    self.uiCustomEventListener = nil
    if self.resRequest then
        Log.fatal("Error @ yqq, resRequest Not Dispose")
    end
end
--endregion

--region Get/Set
function UIController:GetName()
    return self.name
end
function UIController:SetName(name)
    self.name = name
end

function UIController:GetDepth()
    return self.depth
end
function UIController:SetDepth(depth)
    if (self.depth ~= depth) then
        self.depth = depth
        if self.ondepthChanges then
            for i = 1, self.ondepthChanges:Size() do
                local callback = self.ondepthChanges:GetAt(i)
                callback:Call(self.depth)
            end
        end
    end
end

--region Get/Set
function UIController:GetHideUnderLayerFlag()
    return self.hideUnderLayerFlag
end
function UIController:SetHideUnderLayerFlag(flag)
    self.hideUnderLayerFlag = flag
end

function UIController:RemoveCustomEventListener(delegate)
    self.uiCustomEventListener:RemoveCustomEventListener(delegate)
end
function UIController:AddUICustomEventListener(go, type, func)
    self.uiCustomEventListener:AddUICustomEventListener(go, type, func)
end
function UIController:RemoveAllCustomEventListener()
    self.uiCustomEventListener:RemoveAllCustomEventListener()
end
function UIController:GetMaskType()
    return self.maskType
end
function UIController:SetMaskType(maskType)
    self.maskType = maskType
end

function UIController:ManualSetUnderLayerUIVisble(visble)
    if GameGlobal.UIStateManager().uiControllerManager:CheckHideUnderLayerUIType(self:GetName()) == HideUnderLayerType.Manual_Hide then
        GameGlobal.UIStateManager().uiControllerManager:SetUnderLayerUIVisble(self:GetName(), visble)
    end
end

--region 子类可以重写的相关函数
function UIController:OnRootActiveChange(flag)
    
end

function UIController:GetHideUnderLayer()
    return self.hideUnderLayer
end
function UIController:SetHideUnderLayer(hideUnderLayer)
    self.hideUnderLayer = hideUnderLayer
end
--endregion

--region 子类可以重写的相关函数

---UI显示的时候，即创建的时候
---@param uiParams table 打开UI传入的参数
function UIController:OnShow(uiParams)
end

---只有在显示的UI，Update才会起效
function UIController:OnUpdate(deltaTimeMS)
end

---销毁的时候（大部分情况）
---隐藏的时候（当切State时，两个State重叠且已经显示的UIController会先隐藏；显示Dialog时如果已经在低层级显示，则先隐藏）
function UIController:OnHide()
end

--region 数据加载

---请求拉取数据（这时UI不一定加载完成，所以不要去和Unity或UI组件交互）
---@param res UIStateSwitchReq
---@param uiParams table 打开UI传入的参数
function UIController:LoadDataOnEnter(TT, res, uiParams)
    res:SetSucc(true)
end

---为UI填入默认数据，等待拉取完数据再更新成真实数据
function UIController:UpdateUIOnEnterByDefaultData()
end

---用真实数据更新UI
function UIController:UpdateUIOnEnter()
end
--endregion

--endregion

--region 其他辅助函数
---@param uiStateType UIStateType
function UIController:PushAndSwitchState(uiStateType, ...)
    GameGlobal.UIStateManager():PushAndSwitchState(uiStateType, ...)
end

---@param uiStateType UIStateType
function UIController:SwitchState(uiStateType, ...)
    GameGlobal.UIStateManager():SwitchState(uiStateType, ...)
end
function UIController:PopState(...)
    GameGlobal.UIStateManager():PopState(...)
end

---@param uiStateType UIStateType
---@param doSwitch boolean
function UIController:PopStateTo(uiStateType, doSwitch, ...)
    GameGlobal.UIStateManager():PopStateTo(uiStateType, doSwitch, ...)
end

---当需要在打开模态Dialog的同时，隐藏UI状态下的窗口，可以手动调用这个接口;当前UI状态下的窗口会默认在第1层模态Dialog关闭时显示出来
---@param flag boolean
function UIController:ShowCurUIState(flag)
    GameGlobal.UIStateManager():ShowCurUIState(flag)
end

---@param uiName string
function UIController:ShowDialog(uiName, ...)
    GameGlobal.UIStateManager():ShowDialog(uiName, ...)
end

---关闭自己
function UIController:CloseDialog()
    GameGlobal.UIStateManager():CloseDialog(self:GetName())
end

function UIController:Manager()
    return GameGlobal.UIStateManager()
end

---@generic T:GameModule
---@param gameModuleProto T
---@return T
function UIController:GetModule(gameModuleProto)
    return GameGlobal.GetModule(gameModuleProto)
end

---@generic T:GameModule, K:UIModule
---@param gameModuleProto T
---@return K
function UIController:GetUIModule(gameModuleProto)
    return GameGlobal.GetUIModule(gameModuleProto)
end

--- UIController中起的Task
function UIController:StartTask(func, ...)
    -- 协程开始
    if type(func) ~= "function" then
        return
    end

    local taskID = GameGlobal.TaskManager():StartTask(func, ...)
    --Log.sys("[UI] UIController StartTask, ID= ", taskID)
    return taskID
end

--- UIController中起的Task safe version
function UIController:StartSafeTask(lockName, func, ...)
    local params = {...}
    if params[1] == self then
        table.insert(params, 2, lockName)
    else
        table.insert(params, 1, lockName)
    end

    local taskID = UIController.StartTask(self, func, table.unpack(params))

    if self._safeTasks == nil then
        self._safeTasks = {}
    end

    table.insert(self._safeTasks, {taskID = taskID, lockName = lockName})

    return taskID
end

function UIController:ReleaseSafeTasks()
    if self._safeTasks == nil then
        return
    end

    local taskMgr = GameGlobal.TaskManager()
    for k, v in pairs(self._safeTasks) do
        local task = taskMgr:FindTask(v.taskID)
        if task and task.state ~= TaskState.Stop then
            if v.lockName then
                self:UnLock(v.lockName)
            end

            taskMgr:KillTask(v.taskID)
        end
    end

    self._safeTasks = nil
end

--endregion

--region UI锁

---加锁
---@param name string
function UIController:Lock(name)
    GameGlobal.UIStateManager():Lock(name)
end

---解锁
---@param name string
function UIController:UnLock(name)
    GameGlobal.UIStateManager():UnLock(name)
end

---时限锁
---@param name string
---@param lockMs number
function UIController:ExpirationLock(name, lockMs)
    GameGlobal.UIStateManager():ExpirationLock(name, lockMs)
end

---取消时限锁
---@param name string
function UIController:CancelExpirationLock(name)
    GameGlobal.UIStateManager():CancelExpirationLock(name)
end

---SetShowBusy(True) 与 SetShowBusy(False)需要成对出现
---@param value boolean
function UIController:SetShowBusy(value)
    GameGlobal.UIStateManager():ShowBusy(value)
end
--endregion

--region UI窗口（已显示）交互
---UI窗口（已显示）交互函数，可以返回值
---@param uiName string
---@param methodName string
---@param ... 函数参数
function UIController:CallUIMethod(uiName, methodName, ...)
    return GameGlobal.UIStateManager():CallUIMethod(uiName, methodName, ...)
end
--endregion

--region Game Event
---只在显示的时候能监听事件，隐藏(销毁)的时候自动注销
---两种事件通知方式，共存，可以同时使用两种方式关注一个事件类型
---1、注册事件，由UIController接受，统一回调到OnGameEvent
---2、注册事件，由具体的函数接受
---@param gameEventType GameEventType
function UIController:AttachEvent(gameEventType, func)
    if func then
        --回调的是具体的函数
        if not self.type2Callbacks then
            self.type2Callbacks = {}
        end

        local callback = self.type2Callbacks[gameEventType]
        if callback then
            Log.fatal(
                "[UI] UIController:AttachEvent Error, had attached callback of event, ",
                gameEventType,
                ",",
                debug.traceback()
            )
            return
        end

        callback = GameHelper:GetInstance():CreateCallback(func, self)
        self.type2Callbacks[gameEventType] = callback
        GameGlobal.EventDispatcher():AddCallbackListener(gameEventType, callback)
    else
        --回调默认OnGameEvent
        if not self.attachedEventTypes then
            self.attachedEventTypes = FastArray:New()
        end
        if self.attachedEventTypes:Contains(gameEventType) then
            return
        end

        self.attachedEventTypes:PushBack(gameEventType)
        GameGlobal.EventDispatcher():AddListener(gameEventType, self)
    end
end

function UIController:DetachEvent(gameEventType, func)
    if func then
        if self.type2Callbacks then
            local callback = self.type2Callbacks[gameEventType]
            if callback then
                GameGlobal.EventDispatcher():RemoveCallbackListener(gameEventType, callback)
                self.type2Callbacks[gameEventType] = nil
            end
        end
    else
        if self.attachedEventTypes then
            GameGlobal.EventDispatcher():RemoveListener(gameEventType, self:GetListenerID())
            self.attachedEventTypes:Remove(gameEventType)
        end
    end
end

---释放所有+过的事件
function UIController:DetachAllEvents()
    local attachedEventTypes = self.attachedEventTypes
    if attachedEventTypes then
        for i = 1, attachedEventTypes:Size() do
            local gameEventType = attachedEventTypes:GetAt(i)
            GameGlobal.EventDispatcher():RemoveListener(gameEventType, self:GetListenerID())
        end
        self.attachedEventTypes:Clear()
    end

    local type2Callbacks = self.type2Callbacks
    if type2Callbacks then
        for k, v in pairs(type2Callbacks) do
            GameGlobal.EventDispatcher():RemoveCallbackListener(k, v)
        end
        TABLE_CLEAR(self.type2Callbacks)
    end
end

---@param gameEventType GameEventType
---@param ... 任意参数
function UIController:DispatchEvent(gameEventType, ...)
    GameGlobal.EventDispatcher():Dispatch(gameEventType, ...)
end

--endregion

--region 获取引擎资源对象的接口

---从View中获取GameObject
---@param name string 自定义的名称（默认是控件名称），整个UI预设（包括子预设）唯一
---@return UnityEngine.GameObject
function UIController:GetGameObject(name)
    if not name then
        if (self.gameobject == nil) then
            self.gameobject = self.view:GetGameObject()
        end
        return self.gameobject
    else
        local obj = self.name2Gameobjects[name]
        if obj then
            return obj
        end

        local view = self.view
        if view then
            local target = view:GetGameObject(name)
            if target then
                self.name2Gameobjects[name] = target
                return target
            end
        end
        Log.fatal("UIController", self:GetName(), " GetGameObject ->", name, "<- is Null !")
        return nil
    end
end

---从View中获取组件
---@param componentTypeName string Unity组件名称
---@param name string 自定义的名称（默认是控件名称），整个UI预设（包括子预设）唯一
---@return UnityEngine.Component
function UIController:GetUIComponent(componentTypeName, name)
    if componentTypeName == "UISelectObjectPath" then
        -- 动态加载
        local uiCustomWidgetPool = self.key2CustomWidgetPools[name]
        if uiCustomWidgetPool then
            return uiCustomWidgetPool
        end

        local view = self.view
        if view then
            local dynamicInfoOfEngine = view:GetUIComponent(componentTypeName, name)
            if dynamicInfoOfEngine then
                uiCustomWidgetPool = UICustomWidgetPool:New(self, dynamicInfoOfEngine)
                self.key2CustomWidgetPools[name] = uiCustomWidgetPool
                return uiCustomWidgetPool
            end
        end
        Log.fatal("UIController", self:GetName(), " GetUIComponent ->", componentTypeName, " ", name, "<- is Null !")
        return nil
    else
        -- 普通获取View上的组件
        local name2Component = self.type2ComponentTable[componentTypeName]
        if name2Component then
            local component = name2Component[name]
            if component then
                return component
            end
        end

        local view = self.view
        if view then
            local target = view:GetUIComponent(componentTypeName, name)
            if target then
                if (name2Component == nil) then
                    self.type2ComponentTable[componentTypeName] = {}
                    name2Component = self.type2ComponentTable[componentTypeName]
                end
                name2Component[name] = target
                return target
            end
        end

        Log.fatal("UIController", self:GetName(), " GetUIComponent ->", componentTypeName, " ", name, "<- is Null !")
        return nil
    end
end

---从外部信息获取组件
---比如从动态滚动列表信息中获取UICustomWidgetPool
---@param dynamicObject UnityEngine.GameObject
function UIController:GetUIComponentDynamic(componentTypeName, dynamicObject)
    local key = dynamicObject:GetInstanceID()
    local uiCustomWidgetPool = self.key2CustomWidgetPools[key]
    if uiCustomWidgetPool then
        return uiCustomWidgetPool
    end

    local dynamicInfoOfEngine = dynamicObject:GetComponent(componentTypeName)
    if dynamicInfoOfEngine then
        uiCustomWidgetPool = UICustomWidgetPool:New(self, dynamicInfoOfEngine)
        self.key2CustomWidgetPools[key] = uiCustomWidgetPool
        return uiCustomWidgetPool
    end
    Log.fatal("UIController ", self:GetName(), " GetUIComponentDynamic ->", componentTypeName, " ", key, "<- is Null !")
    return nil
end

function UIController:GetChildComponent(parent, componentTypeName, name)
    local child = parent.transform:Find(name)
    if child == nil then
        return nil
    end

    return child:GetComponent(componentTypeName)
end

---从customWidget获取组件
---@param customWidget string 自定义控件UI的名字
---@param name string 自定义的名称（默认是控件名称），整个UI预设（包括子预设）唯一
---@return UnityEngine.GameObject
function UIController:GetGameObjectInCustomWidget(customWidget, name)
    for _, pool in pairs(self.key2CustomWidgetPools) do
        local spawns = pool:GetAllSpawnList()
        if #spawns > 0 then
            for _, widget in pairs(spawns) do
                if widget._className == customWidget then
                    return widget:GetGameObject(name), widget
                end
            end
        end
    end
end

---得到customWidget
---@param customWidget string 自定义控件UI的名字
---@return UICustomWidget
function UIController:GetCustomWidget(customWidget)
    for _, pool in pairs(self.key2CustomWidgetPools) do
        local spawns = pool:GetAllSpawnList()
        if #spawns > 0 then
            for _, widget in pairs(spawns) do
                if widget._className == customWidget then
                    return widget
                end
            end
        end
    end
end
--endregion

--region 资源加载

---主动加载Assets资源
---@param name string 资源名称，需要加后缀
---@param loadType LoadType
---@return UnityEngine.Object
function UIController:GetAsset(name, loadType)
    return UIResourceManager.GetAsset(name, loadType, self.name2Assets)
end

---主动异步加载Assets资源
---@param name string 资源名称，需要加后缀
---@param loadType LoadType
---@return UnityEngine.Object
function UIController:AsyncGetAsset(TT, name, loadType)
    return UIResourceManager.AsyncGetAsset(TT, name, loadType, self.name2Assets)
end

---主动释放Assets资源
---@param name string 资源名称，需要加后缀
function UIController:DisposeAsset(name)
    UIResourceManager.DisposeAsset(name, self:GetName(), self.name2Assets)
end

---同步加载UI GameObject
---该接口会在图集准备好后再Active GameObject，所以不要调完立马设置Active
---@param name string 资源名称，需要加后缀
---@param parentTransform UnityEngine.Transform 父节点，可以为空
---@return UnityEngine.GameObject
function UIController:SyncGetGameObject(name, parentTransform)
    local go = UIResourceManager.SyncGetGameObject(name, self.go2ResRequest)
    if parentTransform then
        go.transform:SetParent(parentTransform, false)
    end
    return go
end

---异步加载UI GameObject
---@param name string 资源名称，需要加后缀
---@param parentTransform UnityEngine.Transform 父节点，可以为空
---@return UnityEngine.GameObject
function UIController:AsyncGetGameObject(TT, name, parentTransform)
    local go = UIResourceManager.AsyncGetGameObject(TT, name, self.go2ResRequest)
    if parentTransform then
        go.transform:SetParent(parentTransform, false)
    end
    return go
end

---销毁UI GameObject
---@param go UnityEngine.GameObject
function UIController:DisposeGameObject(go)
    UIResourceManager.DisposeGameObject(go, self.go2ResRequest)
end

---释放所有主动加载的资源
---为了防止业务层忘记释放资源,统一在Hide的时候释放所有主动加载的资源
function UIController:DisposeAllResources()
    UIResourceManager.DisposeAllAssets(self.name2Assets)
    UIResourceManager.DisposeAllGameObjects(self.go2ResRequest)
end
--endregion

--region 动效

--yqqtodo
function UIController:PlayEnterAnim(TT)
end
function UIController:PlayLeaveAnim(TT)
end
--endregion

--region UI显示3D
---@private
---for UICustomWidget

function UIController:AddDepthChangeCallback(callback)
    self.ondepthChanges:PushBack(callback)
end
---@private
---for UICustomWidget
function UIController:RemoveDepthChangeCallback(id)
    for i = 1, self.ondepthChanges:Size() do
        local callback = self.ondepthChanges:GetAt(i)
        if callback:GetID() == id then
            self.ondepthChanges:Remove(callback)
            break
        end
    end
end

---@return UI3DModule
function UIController:CreateUI3DModule()
    return UIHelper.CreateUI3DModule(self:GetName())
end

---@param ui3DModule UI3DModule
---@param modelPrefabPath string
---@param limitRotateAngle float
---@return int
function UIController:InitUI3DModule(ui3DModule, modelPrefabPath, limitRotateAngle)
    if ui3DModule then
        -- Init
        local callback = GameHelper:GetInstance():CreateCallback(ui3DModule.OnUIControllerDepthChange, ui3DModule)
        self.ondepthChanges:PushBack(callback)

        limitRotateAngle = limitRotateAngle or -1
        ui3DModule:Init(modelPrefabPath, limitRotateAngle)
        return callback:GetID()
    end
end

---@param ui3DModule UI3DModule
function UIController:Show3DModule(
    ui3DModule,
    camPfbPath,
    maxFov,
    uiOperationGraphic,
    uibaseDepth,
    isCanUpDown,
    isCanScale,
    isCanRot)
    if ui3DModule then
        isCanUpDown = isCanUpDown ~= false
        isCanScale = isCanScale ~= false
        isCanRot = isCanRot ~= false
        ui3DModule:Show(camPfbPath, maxFov, uiOperationGraphic, uibaseDepth, isCanUpDown, isCanScale, isCanRot)
    end
end
function UIController:Hide3DModule(ui3DModule)
    if ui3DModule then
        ui3DModule:Hide()
    end
end
function UIController:Dispose3DModule(ui3DModule, id)
    if ui3DModule then
        for i = 1, self.ondepthChanges:Size() do
            local callback = self.ondepthChanges:GetAt(i)
            if callback:GetID() == id then
                self.ondepthChanges:Remove(callback)
                ui3DModule:Release()
                break
            end
        end
    end
end

---@private
function UIController:DisposeAll3DModules()
    for i = 1, self.ondepthChanges:Size() do
        local callback = self.ondepthChanges:GetAt(i)
        local ui3DModule = callback:GetOoObject()
        if ui3DModule then
            ui3DModule:Release()
        end
    end
    self.ondepthChanges:Clear()
end
--endregion

--region 业务层不用关心！
function UIController:AddComponents(uiComponentInfo)
    if uiComponentInfo then
        for k, v in pairs(uiComponentInfo) do
            local cmp = _createInstance(k)
            if cmp then
                if not cmp:IsChildOf("UIComponent") then
                    Log.fatal("[UI] UIController:AddComponent Fail, ", k, " is not inherited from UIComponent!")
                else
                    cmp:Init(self, v)
                    self.components:Insert(k, cmp)
                end
            else
                Log.fatal("[UI] UIController:AddComponent Fail, ", k)
            end
        end
    end
end
function UIController:Update(deltaTimeMS)
    self:OnUpdate(deltaTimeMS)
end
---------------------------------------------

--[[-------------------------------------------
    每次显示UI，加载View的时候调用
]]
function UIController:Load(view, resRequest)
    self.view = view
    self.resRequest = resRequest
    self.luaView = LuaUIView:New()
end

function UIController:SetComponentSharedParam(key, value)
    self.componentParams[key] = value
end

function UIController:GetComponentSharedParam(key)
    return self.componentParams[key]
end

function UIController:Show(uiParams)
    -- 这个时候其他View还没有加载
    if self.view then
        self.view:SetShow(true, self)
    end
    if self.luaView then
        self.luaView:SetShow(true, self)
    end
    self:OnShow(uiParams)

    for i = 1, self.components:Size() do
        self.components:GetAt(i):Show()
    end

    self.defaultComponent:Show()

    self:AttachEvent(GameEventType.FakeInput, self.OnFakeInput)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIShowEnd, self.name, uiParams)
end
function UIController:AfterShow(TT)
    for i = 1, self.components:Size() do
        self.components:GetAt(i):AfterShow(TT)
    end

    self.defaultComponent:AfterShow(TT)
end
function UIController:BeforeHide(TT)
    for i = 1, self.components:Size() do
        self.components:GetAt(i):BeforeHide(TT)
    end

    self.defaultComponent:BeforeHide(TT)
end

function UIController:Hide()
    for i = 1, self.components:Size() do
        self.components:GetAt(i):Hide()
    end

    self.defaultComponent:Hide()

    --region product append
    self:RemoveAllUIEventTrigger()
    --endretion

    self:ReleaseSafeTasks()
    self:DetachAllEvents()
    self:OnHide()

    local view = self.view
    if view then
        view:SetShow(false, nil)
    end

    if self.luaView then
        self.luaView:SetShow(false, nil)
    end
    self:RemoveAllCustomEventListener()
    self:DisposeCustomWidgets()
    self:DisposeAllResources()
    self:DisposeAll3DModules()
end

function UIController:HideView()
    local view = self.view
    if view then
        view:SetShow(false, nil)
    end
end

function UIController:UnLoad()
    local resRequest = self.resRequest
    if resRequest then
        UIResourceManager.DisposeView(resRequest)
    end

    self.resRequest = nil
    self.view = nil
    self.luaView:Dispose()
    self.luaView = nil
end

function UIController:View()
    return self.view
end
--endregion

--region Private
---@private
---释放动态加载的脚本(和对应资源)
function UIController:DisposeCustomWidgets()
    local key2CustomWidgetPools = table.shallowcopy(self.key2CustomWidgetPools)
    if key2CustomWidgetPools then
        for _, v in pairs(key2CustomWidgetPools) do
            v:Dispose()
        end
    end
    TABLE_CLEAR(self.key2CustomWidgetPools)
end
--endregion

--region UI组件回调注册/清除/统一清除
---只在显示的时候能绑定UI事件，隐藏(销毁)的时候自动解绑
---@public
---@param uiEventType UIEvent
---@param go UnityEngine.GameObject
---@param name string 同一个界面有多个同名组件需要访问时，uiview里会为它们指定不同的名字，这时候绑定事件的时候这个名字也需要传进来，根据这个名字去绑定对应的事件
function UIController:AddUIEvent(uiEventType, widget, name)
    self.luaView:AddUIEvent(uiEventType, widget, name)
end
--endregion

--product append
--retion UI组件回调注册/清除/统一清除
--region UIEventTriggerType定义
---@class UIEventTriggerType
local UIEventTriggerType = {
    Click = "onClick",
    DoubleClick = "onDoubleClick",
    Down = "onDown",
    Enter = "onEnter",
    Exit = "onExit",
    Up = "onUp",
    Select = "onSelect",
    UpdateSelect = "onUpdateSelect",
    BeginDrag = "onBeginDrag",
    Drag = "onDrag",
    EndDrag = "onEndDrag",
    Scroll = "onScroll",
    ApplicationFocus = "onApplicationFocus"
}

_enum("UIEventTriggerType", UIEventTriggerType)
--endregion

---@param gameObject UnityEngine.GameObject
---@param eventTriggerType string UIEventTriggerType
---@param func function
function UIController:SetUIEventTrigger(gameObject, eventTriggerType, func)
    if not self.uiEventTriggers[eventTriggerType] then
        self.uiEventTriggers[eventTriggerType] = {}
    end

    local eventTriggerGOTable = self.uiEventTriggers[eventTriggerType]
    if table.icontains(eventTriggerGOTable, gameObject) then
        Log.fatal(gameObject.name .. "节点已注册" .. eventTriggerType .. "类型的触发器，不可重复注册！")
        return
    end

    ---@type UIEventTriggerListener
    local etl = UIEventTriggerListener.Get(gameObject)
    etl[eventTriggerType] = func
    eventTriggerGOTable[#eventTriggerGOTable + 1] = gameObject
end

function UIController:RemoveUIEventTrigger(gameObject, eventTriggerType)
    if not self.uiEventTriggers[eventTriggerType] then
        return
    end

    local eventTriggerGOTable = self.uiEventTriggers[eventTriggerType]
    if not table.icontains(eventTriggerGOTable, gameObject) then
        return
    end

    UIEventTriggerListener.Get(gameObject)[eventTriggerType] = nil
end

function UIController:RemoveAllUIEventTrigger()
    for eventTriggerType, eventTriggerGOTable in pairs(self.uiEventTriggers) do
        for i = 1, #eventTriggerGOTable do
            local go = eventTriggerGOTable[i]
            UIEventTriggerListener.Get(go)[eventTriggerType] = nil
        end
    end
end
--endregion

function UIController:OnFakeInput(t)
    if self.name == t.ui then
        self[t.input](self, table.unpack(t.args))
    end
end
