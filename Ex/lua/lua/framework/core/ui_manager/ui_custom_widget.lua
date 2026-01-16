--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    动态加载窗口的UI逻辑，关联一个UIView，封装了和View的交互

    目的：
    1、负责动态加载窗口的逻辑
    2、资源和逻辑脚本分离
    3、可以是UIController、UIMessageBox、UICustomWidget触发创建
    4、根Owner是UIController或UIMessageBox,在根Owner销毁之前释放资源和脚本
**********************************************************************************************
]] --------------------------------------------------------------------------------------------

---@class UICustomWidget : GameEventListener
_class("UICustomWidget", GameEventListener)
local TABLE_CLEAR = table.clear

--region 初始化/销毁
function UICustomWidget:Constructor()
    self.enabled = true
    self.name = nil
    self.view = nil
    ---@type UIController|UIMessageBox
    self.uiOwner = nil

    -- GameEvent
    ---@type FastArray<GameEventType>
    self.attachedEventTypes = nil
    ---@type table<string, Callback>
    self.type2Callbacks = nil

    -- 缓存的用于动态加载脚本的UICustomWidgetPool
    ---@type table<string, UICustomWidgetPool>
    self.key2CustomWidgetPools = {}

    -- 缓存的主动动态加载的 Unity Assets/GameObject资源
    self.name2Assets = {}
    self.go2ResRequest = {}
    -- 缓存的UI View上提前编辑关联的 GameObject/组件
    self.gameobject = nil
    self.name2Gameobjects = {}
    self.type2ComponentTable = {}

    --- product append
    -- UIEventTrigger
    self.uiEventTriggers = {}
    self.uiCustomEventListener = UICustomUIEventListener:New()
end

function UICustomWidget:Dispose()
    -- 清理各种事件
    self.attachedEventTypes = nil
    self.type2Callbacks = nil

    self.key2CustomWidgetPools = nil

    -- 缓存的Unity Assets资源
    self.name2Assets = nil
    self.name2ObjRequests = nil

    -- 清空缓存的Unity相关的GameObject和Component
    self.gameobject = nil
    self.name2Gameobjects = nil
    self.type2ComponentTable = nil
    self.uiOwner = nil
    self.uiCustomEventListener = nil
end
--endregion

--region 子类可以重写的相关函数

---@protected
---显示的时候，这里可以提前设置控件
function UICustomWidget:OnShow()
end

---@protected
---隐藏的时候，这里可以处理事件的注销
function UICustomWidget:OnHide()
end
--endregion

--region 其他辅助函数接口

---@return UIController|UIMessageBox
function UICustomWidget:RootUIOwner()
    return self.uiOwner
end

function UICustomWidget:RemoveCustomEventListener(delegate)
    self.uiCustomEventListener:RemoveCustomEventListener(delegate)
end
function UICustomWidget:RemoveAllCustomEventListener()
    self.uiCustomEventListener:RemoveAllCustomEventListener()
end
function UICustomWidget:AddUICustomEventListener(go, type, func)
    self.uiCustomEventListener:AddUICustomEventListener(go, type, func)
end
---@param uiStateType UIStateType
function UICustomWidget:PushAndSwitchState(uiStateType, ...)
    GameGlobal.UIStateManager():PushAndSwitchState(uiStateType, ...)
end

---@param uiStateType UIStateType
function UICustomWidget:SwitchState(uiStateType, ...)
    GameGlobal.UIStateManager():SwitchState(uiStateType, ...)
end

function UICustomWidget:PopState()
    GameGlobal.UIStateManager():PopState()
end

---@param uiStateType UIStateType
---@param doSwitch boolean
function UICustomWidget:PopStateTo(uiStateType, doSwitch, ...)
    GameGlobal.UIStateManager():PopStateTo(uiStateType, doSwitch, ...)
end

---@param uiName string
function UICustomWidget:ShowDialog(uiName, ...)
    GameGlobal.UIStateManager():ShowDialog(uiName, ...)
end

--- UICustomWidget中起的Task默认加锁、Show Busy
function UICustomWidget:StartTask(func, ...)
    -- 协程开始
    if type(func) ~= "function" then
        return
    end

    local taskID = GameGlobal.TaskManager():StartTask(func, ...)
    --Log.sys("[UI] UICustomWidget StartTask, ID= ", taskID)
    return taskID
end

--- UICustomWidget中起的Task safe version
function UICustomWidget:StartSafeTask(lockName, func, ...)
    local params = {...}
    if params[1] == self then
        table.insert(params, 2, lockName)
    else
        table.insert(params, 1, lockName)
    end

    local taskID = UICustomWidget.StartTask(self, func, table.unpack(params))

    if self._safeTasks == nil then
        self._safeTasks = {}
    end

    table.insert(self._safeTasks, {taskID = taskID, lockName = lockName})

    return taskID
end

function UICustomWidget:ReleaseSafeTasks()
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

---@generic T:GameModule
---@param proto T
---@return T
function UICustomWidget:GetModule(proto)
    return GameGlobal.GetModule(proto)
end

---@generic T:GameModule, K:UIModule
---@param gameModuleProto T
---@return K
function UICustomWidget:GetUIModule(gameModuleProto)
    return GameGlobal.GetUIModule(gameModuleProto)
end
--endregion

--region Game Event 接口

---只在显示的时候能监听事件，隐藏(销毁)的时候自动注销
---两种事件通知方式，共存，可以同时使用两种方式关注一个事件类型
---1、注册事件，由UICustomWidget接受，统一回调到OnGameEvent
---2、注册事件，由具体的函数接受
---@param gameEventType GameEventType
function UICustomWidget:AttachEvent(gameEventType, func)
    if func then
        --回调的是具体的函数
        if not self.type2Callbacks then
            self.type2Callbacks = {}
        end

        local callback = self.type2Callbacks[gameEventType]
        if callback then
            local str = ""
            for k, v in pairs(GameEventType) do
                if gameEventType == v then
                    str = k
                    break
                end
            end
            Log.fatal(
                "[UI] UICustomWidget:AttachEvent Error, had attached callback of event [",
                str .. "=" .. gameEventType .. "]"
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

function UICustomWidget:DetachEvent(gameEventType, func)
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

---@private
---释放所有+过的事件
function UICustomWidget:DetachAllEvents()
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
function UICustomWidget:DispatchEvent(gameEventType, ...)
    GameGlobal.EventDispatcher():Dispatch(gameEventType, ...)
end
--endregion

--region UI锁接口

---@param name string
function UICustomWidget:Lock(name)
    GameGlobal.UIStateManager():Lock(name)
end
---@param name string
function UICustomWidget:ExpirationLock(name, lockMs)
    GameGlobal.UIStateManager():ExpirationLock(name, lockMs)
end

---@param name string
function UICustomWidget:UnLock(name)
    GameGlobal.UIStateManager():UnLock(name)
end

---SetShowBusy(True) 与 SetShowBusy(False)需要成对出现
---@param value boolean
function UICustomWidget:SetShowBusy(value)
    GameGlobal.UIStateManager():ShowBusy(value)
end
--endregion

--region 获取引擎资源对象的接口

---得到customWidget
---@param customWidget string 自定义控件UI的名字
---@return UICustomWidget
function UICustomWidget:GetCustomWidget(customWidget)
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

---@overload fun():UnityEngine.GameObject
---@param name string 自定义的名称（默认是控件名称），整个UI预设（包括子预设）唯一
---@return UnityEngine.GameObject
function UICustomWidget:GetGameObject(name)
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
        Log.fatal("UICustomWidget", self.name, " GetGameObject ->", name, "<- is Null !")
        return nil
    end
end

---从View中获取组件
---@param componentTypeName string Unity组件名称
---@param name string 自定义的名称（默认是控件名称），整个UI预设（包括子预设）唯一
---@return UnityEngine.Component
function UICustomWidget:GetUIComponent(componentTypeName, name)
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
                uiCustomWidgetPool = UICustomWidgetPool:New(self.uiOwner, dynamicInfoOfEngine)
                self.key2CustomWidgetPools[name] = uiCustomWidgetPool
                return uiCustomWidgetPool
            end
        end
        Log.fatal("UICustomWidget", self.name, " GetUIComponent ->", componentTypeName, " ", name, "<- is Null !")
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

        Log.fatal("UICustomWidget", self.name, " GetUIComponent ->", componentTypeName, " ", name, "<- is Null !")
        return nil
    end
end

---从外部信息获取组件
---比如从动态滚动列表信息中获取UICustomWidgetPool
---@param dynamicObject UnityEngine.GameObject
function UICustomWidget:GetUIComponentDynamic(componentTypeName, dynamicObject)
    local key = dynamicObject:GetInstanceID()
    local uiCustomWidgetPool = self.key2CustomWidgetPools[key]
    if uiCustomWidgetPool then
        return uiCustomWidgetPool
    end

    local dynamicInfoOfEngine = dynamicObject:GetComponent(componentTypeName)
    if dynamicInfoOfEngine then
        uiCustomWidgetPool = UICustomWidgetPool:New(self.uiOwner, dynamicInfoOfEngine)
        self.key2CustomWidgetPools[key] = uiCustomWidgetPool
        return uiCustomWidgetPool
    end
    Log.fatal("UICustomWidget ", self.name, " GetUIComponentDynamic ->", componentTypeName, " ", key, "<- is Null !")
    return nil
end

function UICustomWidget:GetChildComponent(parent, componentTypeName, name)
    local child = parent.transform:Find(name)
    if child == nil then
        return nil
    end

    return child:GetComponent(componentTypeName)
end
--endregion

--region 资源加载接口

---主动加载Assets资源
---@param name string 资源名称，需要加后缀
---@param loadType LoadType
---@return UnityEngine.GameObject
function UICustomWidget:GetAsset(name, loadType)
    return UIResourceManager.GetAsset(name, loadType, self.name2Assets)
end

---主动释放Assets资源
---@param name string 资源名称，需要加后缀
function UICustomWidget:DisposeAsset(name)
    UIResourceManager.DisposeAsset(name, self:GetName(), self.name2Assets)
end

---同步加载UI GameObject
------该接口会在图集准备好后再Active GameObject，所以不要调完立马设置Active
---@param name string 资源名称，需要加后缀
---@param parentTransform UnityEngine.Transform 父节点，可以为空
---@return UnityEngine.GameObject
function UICustomWidget:SyncGetGameObject(name, parentTransform)
    local go = UIResourceManager.SyncGetGameObject(name, self.go2ResRequest)
    if parentTransform then
        go.transform:SetParent(parentTransform, false)
    end
    return go
end

---异步加载UI GameObject
---该接口会等待其图集准备好返回
---@param name string 资源名称，需要加后缀
---@param parentTransform UnityEngine.Transform 父节点，可以为空
---@return UnityEngine.GameObject
function UICustomWidget:AsyncGetGameObject(TT, name, parentTransform)
    local go = UIResourceManager.AsyncGetGameObject(TT, name, self.go2ResRequest)
    if parentTransform then
        go.transform:SetParent(parentTransform, false)
    end
    return go
end

---销毁UI GameObject
---@param name string 资源名称，需要加后缀
function UICustomWidget:DisposeGameObject(go)
    UIResourceManager.DisposeGameObject(go, self.go2ResRequest)
end

---@private
---释放所有主动加载的资源
---为了防止业务层忘记释放资源,统一在Hide的时候释放所有主动加载的资源
function UICustomWidget:DisposeAllResources()
    UIResourceManager.DisposeAllAssets(self.name2Assets)
    UIResourceManager.DisposeAllGameObjects(self.go2ResRequest)
end
--endregion

--region UI显示3D
---@return UI3DModule
function UICustomWidget:CreateUI3DModule()
    return UIHelper.CreateUI3DModule(self.name)
end

---@param ui3DModule UI3DModule
---@param modelPrefabPath string
---@param limitRotateAngle float
---@return int
function UICustomWidget:InitUI3DModule(ui3DModule, modelPrefabPath, limitRotateAngle)
    if self.uiOwner == nil or self.uiOwner.super._className == "UIMessageBox" then
        return
    end
    if ui3DModule then
        -- Init
        local callback = GameHelper:GetInstance():CreateCallback(ui3DModule.OnUIControllerDepthChange, ui3DModule)
        self.uiOwner:AddDepthChangeCallback(callback)

        limitRotateAngle = limitRotateAngle or -1
        ui3DModule:Init(modelPrefabPath, limitRotateAngle)
        return callback:GetID()
    end
end
function UICustomWidget:Show3DModule(
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
function UICustomWidget:Hide3DModule(ui3DModule)
    if ui3DModule then
        ui3DModule:Hide()
    end
end
function UICustomWidget:Dispose3DModule(ui3DModule, id)
    if self.uiOwner == nil or self.uiOwner.super._className == "UIMessageBox" then
        return
    end

    if ui3DModule then
        self.uiOwner:RemoveDepthChangeCallback(id)
        ui3DModule:Release()
    end
end
--endregion

--region 业务层不用关心的部分！
function UICustomWidget:SetName(name)
    self.name = name
end
function UICustomWidget:GetName()
    return self.name
end
function UICustomWidget:Enable(flag)
    if self.enabled ~= flag then
        self.enabled = flag

        UIHelper.SetActiveRecursively(self:GetGameObject(), flag)
    end
end

function UICustomWidget:IsEnable()
    return self.enabled
end

function UICustomWidget:Load(view, uiOwner)
    self.view = view
    self.luaView = LuaUIView:New()
    self.uiOwner = uiOwner
    self:Show()
end

---@private
function UICustomWidget:Show()
    -- 这个时候其他View还没有加载
    if self.view then
        self.view:SetShow(true, self)
    end
    if self.luaView then
        self.luaView:SetShow(true, self)
    end
    self:OnShow()
    if self.enableFakeInput then
        self:AttachEvent(GameEventType.FakeInput, self.OnFakeInput)
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIShowEnd, self.name)
end

---@private
function UICustomWidget:Hide()
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
    self.uiCustomEventListener:RemoveAllCustomEventListener()
    self:DisposeCustomWidgets()
    self:DisposeAllResources()
end

function UICustomWidget:UnLoad()
    self:Hide()

    UIHelper.DestroyGameObject(self:GetGameObject())
    self.view = nil
    self.luaView:Dispose()
    self.luaView = nil
end
function UICustomWidget:View()
    return self.view
end

---@private
---释放动态加载的脚本(和对应资源)
function UICustomWidget:DisposeCustomWidgets()
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
function UICustomWidget:AddUIEvent(uiEventType, widget, name)
    self.luaView:AddUIEvent(uiEventType, widget, name)
end
--endregion

--product append
--retion UI组件回调注册/清除/统一清除
---@param gameObject UnityEngine.GameObject
---@param eventTriggerType string UIEventTriggerType
---@param func function
function UICustomWidget:SetUIEventTrigger(gameObject, eventTriggerType, func)
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

function UICustomWidget:RemoveUIEventTrigger(gameObject, eventTriggerType)
    if not self.uiEventTriggers[eventTriggerType] then
        return
    end

    local eventTriggerGOTable = self.uiEventTriggers[eventTriggerType]
    if not table.icontains(eventTriggerGOTable, gameObject) then
        return
    end

    UIEventTriggerListener.Get(gameObject)[eventTriggerType] = nil
end

function UICustomWidget:RemoveAllUIEventTrigger()
    for eventTriggerType, eventTriggerGOTable in pairs(self.uiEventTriggers) do
        for i = 1, #eventTriggerGOTable do
            local go = eventTriggerGOTable[i]
            UIEventTriggerListener.Get(go)[eventTriggerType] = nil
        end
    end
end
--endregion

function UICustomWidget:OnFakeInput(t)
    if t.ui == self.name then
        if t.uiid and self.uiid ~= t.uiid then
            return
        else
            self[t.input](self, table.unpack(t.args))
        end
    end
end

---UI窗口（已显示）交互函数，可以返回值
---@param uiName string
---@param methodName string
---@param ... 函数参数
function UICustomWidget:CallUIMethod(uiName, methodName, ...)
    return GameGlobal.UIStateManager():CallUIMethod(uiName, methodName, ...)
end