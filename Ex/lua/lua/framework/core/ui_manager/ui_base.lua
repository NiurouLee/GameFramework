--[[------------------------------------------------------------------------------------------
**********************************************************************************************

**********************************************************************************************
]]--------------------------------------------------------------------------------------------

---@class UIBase : GameEventListener
_class( "UIBase", GameEventListener )
UIBase = UIBase
local TABLE_CLEAR = table.clear
local SHALLOW_COPY = table.shallowcopy

--region 初始化/销毁
function UIBase:Constructor()
    Log.debug("[UI] UIBase:Constructor")
    self.name = nil
    self.view = nil

    -- GameEvent
    ---@type FastArray<GameEventType>
    self.attachedEventTypes = nil
    ---@type AutoEventBinder
    self.autoBinder = nil

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
end

function UIBase:Dispose()
    -- 清理各种事件
    self.attachedEventTypes = nil
    self.autoBinder = nil

    self.key2CustomWidgetPools = nil

    -- 缓存的Unity Assets资源
    self.name2Assets = nil
    self.go2ResRequest = nil

    -- 清空缓存的Unity相关的GameObject和Component
    self.gameobject = nil
    self.name2Gameobjects = nil
    self.type2ComponentTable = nil
    if self.resRequest then
        Log.fatal("[UI] UIBase:Dispose Error, resRequest Not Dispose,",self.name)
    end
end
--endregion

--region 其他辅助函数接口
---@return string
function UIBase:GetName()
    return self.name
end

---@param uiStateType UIStateType
function UIBase:PushAndSwitchState(uiStateType, ...)
    GameGlobal.UIStateManager():PushAndSwitchState(uiStateType, ...)
end

---@param uiStateType UIStateType
function UIBase:SwitchState(uiStateType, ...)
    GameGlobal.UIStateManager():SwitchState(uiStateType, ...)
end

function UIBase:PopState()
    GameGlobal.UIStateManager():PopState()
end

---@param uiStateType UIStateType
---@param doSwitch boolean
function UIBase:PopStateTo(uiStateType, doSwitch, ...)
    GameGlobal.UIStateManager():PopStateTo(uiStateType, doSwitch, ...)
end

---@param uiName string
function UIBase:ShowDialog(uiName, ...)
    GameGlobal.UIStateManager():ShowDialog(uiName, ...)
end

function UIBase:StartTask(func, ...)
    -- 协程开始
    if type(func) ~= "function" then
        return
    end

    local taskID = GameGlobal.TaskManager():StartTask(func, ...)
    Log.sys("[UI] UIBase StartTask, ID= ", taskID)
    return taskID
end

---@generic T:GameModule
---@param proto T
---@return T
function UIBase:GetModule(proto)
    return GameGlobal.GetModule(proto)
end

---@generic T:GameModule, K:UIModule
---@param gameModuleProto T
---@return K
function UIBase:GetUIModule(gameModuleProto)
    return GameGlobal.GetUIModule(gameModuleProto)
end
--endregion

--region Game Event 接口

---只在显示的时候能监听事件，隐藏(销毁)的时候自动注销
---两种事件通知方式，共存，可以同时使用两种方式关注一个事件类型
---1、注册事件，由UICustomWidget接受，统一回调到OnGameEvent
---2、注册事件，由具体的函数接受
---@param gameEventType GameEventType
function UIBase:AttachEvent(gameEventType, func)
    if func then
        --回调的是具体的函数
        if not self.autoBinder then
            self.autoBinder = AutoEventBinder:New(GameGlobal.EventDispatcher())
        end
        self.autoBinder:BindEvent(gameEventType, self, func)
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

function UIBase:DetachEvent(gameEventType, func)
    if func then
        if self.autoBinder then
            self.autoBinder:UnBindEvent(gameEventType)
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
function UIBase:DettachAllEvents()
    local attachedEventTypes = self.attachedEventTypes
    if attachedEventTypes then
        for i = 1, attachedEventTypes:Size() do
            local gameEventType = attachedEventTypes:GetAt(i)
            GameGlobal.EventDispatcher():RemoveListener(gameEventType, self:GetListenerID())
        end
        self.attachedEventTypes:Clear()
    end

    if self.autoBinder then
        self.autoBinder:UnBindAllEvents()
    end
end
--endregion


--region UI锁接口

---@param name string
function UIBase:Lock(name)
    GameGlobal.UIStateManager():Lock(name)
end
---@param name string
function UIBase:ExpirationLock(name, lockMs)
    GameGlobal.UIStateManager():ExpirationLock(name, lockMs)
end

---@param name string
function UIBase:UnLock(name)
    GameGlobal.UIStateManager():UnLock(name)
end

---SetShowBusy(True) 与 SetShowBusy(False)需要成对出现
---@param value boolean
function UIBase:SetShowBusy(value)
    GameGlobal.UIStateManager():ShowBusy(value)
end
--endregion


--region 获取引擎资源对象的接口

---@overload fun():UnityEngine.GameObject
---@param name string 自定义的名称（默认是控件名称），整个UI预设（包括子预设）唯一
---@return UnityEngine.GameObject
function UIBase:GetGameObject(name)
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
        Log.fatal("[UI] ", self.name, " GetGameObject ->", name, "<- is Null !")
        return nil
    end
end

---从View中获取组件
---@param componentTypeName string Unity组件名称
---@param name string 自定义的名称（默认是控件名称），整个UI预设（包括子预设）唯一
---@return UnityEngine.Component
function UIBase:GetUIComponent(componentTypeName, name)
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
        Log.fatal("[UI] ", self.name, " GetUIComponent ->", componentTypeName, " ", name, "<- is Null !")
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

        Log.fatal("[UI] ", self.name, " GetUIComponent ->", componentTypeName, " ", name, "<- is Null !")
        return nil
    end
end

---从外部信息获取组件
---比如从动态滚动列表信息中获取UICustomWidgetPool
---@param dynamicObject UnityEngine.GameObject
function UIBase:GetUIComponentDynamic(componentTypeName, dynamicObject)
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
    Log.fatal("[UI] ", self.name, " GetUIComponentDynamic ->", componentTypeName, " ", key, "<- is Null !")
    return nil
end
--endregion


--region 资源加载接口

---主动加载Assets资源
---@param name string 资源名称，需要加后缀
---@param loadType LoadType
---@return UnityEngine.Object
function UIBase:GetAsset(name, loadType)
    return UIResourceManager.GetAsset(name, loadType, self.name2Assets)
end

---主动释放Assets资源
---@param name string 资源名称，需要加后缀
function UIBase:DisposeAsset(name)
    UIResourceManager.DisposeAsset(name, self:GetName(), self.name2Assets)
end

---同步加载UI GameObject
---@param name string 资源名称，需要加后缀
---@return UnityEngine.GameObject
function UIBase:SyncGetGameObject(name)
    return UIResourceManager.SyncGetGameObject(name, self.go2ResRequest)
end

---异步加载UI GameObject
---@param name string 资源名称，需要加后缀
---@return UnityEngine.GameObject
function UIBase:AsyncGetGameObject(TT, name)
    return UIResourceManager.AsyncGetGameObject(TT, name, self.go2ResRequest)
end

---销毁UI GameObject
---@param go UnityEngine.GameObject
function UIBase:DisposeGameObject(go)
    UIResourceManager.DisposeGameObject(go, self.go2ResRequest)
end

---@private
---释放所有主动加载的资源
---为了防止业务层忘记释放资源,统一在Hide的时候释放所有主动加载的资源
function UIBase:DisposeAllResources()
    UIResourceManager.DisposeAllAssets(self.name2Assets)
    UIResourceManager.DisposeAllGameObjects(self.go2ResRequest)
end
--endregion


--region UI显示3D
---@return UI3DModule
function UIBase:CreateUI3DModule()
    return UIHelper.CreateUI3DModule(self.name)
end

---@param ui3DModule UI3DModule
---@param modelPrefabPath string
---@param limitRotateAngle float
---@return int
function UIBase:InitUI3DModule(ui3DModule, modelPrefabPath, limitRotateAngle)
end
function UIBase:Show3DModule(ui3DModule, camPfbPath, maxFov, uiOperationGraphic, uibaseDepth, isCanUpDown, isCanScale, isCanRot)
    if ui3DModule then
        isCanUpDown = isCanUpDown ~= false
        isCanScale = isCanScale ~= false
        isCanRot = isCanRot ~= false
        ui3DModule:Show(camPfbPath, maxFov, uiOperationGraphic, uibaseDepth, isCanUpDown, isCanScale, isCanRot)
    end
end
function UIBase:Hide3DModule(ui3DModule)
    if ui3DModule then
        ui3DModule:Hide()
    end
end
function UIBase:Dispose3DModule(ui3DModule, id)
end
--endregion


--region 业务层不用关心的部分！
function UIBase:SetName(name)
    self.name = name
end

function UIBase:Load(view, resRequest)
    self.view = view
    self.resRequest = resRequest
    self.luaView = LuaUIView:New()
end

---@private
function UIBase:Show()
    -- 这个时候其他View还没有加载
    if self.view then
        self.view:SetShow(true, self)
    end
    if self.luaView then
        self.luaView:SetShow(true, self)
    end
end

---@private
function UIBase:Hide()
    local view = self.view
    if view then
        view:SetShow(false, nil)
    end
    if self.luaView then
        self.luaView:SetShow(false, nil)
    end
end

function UIBase:UnLoad()
    self:DettachAllEvents()
    self:DisposeCustomWidgets()
    self:DisposeAllResources()

    local resRequest = self.resRequest
    if resRequest then
        UIResourceManager.DisposeView(resRequest)
    end

    self.resRequest = nil
    self.view = nil
    self.luaView:Dispose()
    self.luaView = nil
end

---@return UIView
function UIBase:View()
    return self.view
end

---@private
---释放动态加载的脚本(和对应资源)
function UIBase:DisposeCustomWidgets()
    local key2CustomWidgetPools = SHALLOW_COPY(self.key2CustomWidgetPools)
    for _, v in pairs(key2CustomWidgetPools) do
        v:Dispose()
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
function UIBase:AddUIEvent(uiEventType, widget, name)
    self.luaView:AddUIEvent(uiEventType, widget, name)
end
--endregion