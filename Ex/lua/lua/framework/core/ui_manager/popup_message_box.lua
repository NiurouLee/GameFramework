--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    Popup窗口的UI脚本，关联一个UIView，封装了和View的交互
    根据popup信息负责UI的显示、关闭、点击   
**********************************************************************************************
]]--------------------------------------------------------------------------------------------
---popup弹窗类型
---@class PopupMsgBoxType
local PopupMsgBoxType = {
    Ok = "Ok",
    OkCancel = "OkCancel",
    OkCancelClose= "OkCancelClose",
    OkClose = "OkClose",
    --可扩展
}
_enum("PopupMsgBoxType", PopupMsgBoxType)


---@class UIMessageBox:Object
_class( "UIMessageBox", Object )
UIMessageBox = UIMessageBox
local TABLE_CLEAR = table.clear
local SHALLOW_COPY = table.shallowcopy

function UIMessageBox:Constructor()
    self.bShow = false
    self.view = nil
    self.name = nil
    self.resRequest = nil

    -- 缓存的用于动态加载脚本的UICustomWidgetPool
    ---@type table<string, UICustomWidgetPool>
    self.key2CustomWidgetPools = {}

    -- 缓存的UI View上提前编辑关联的 GameObject/组件
    self.gameobject = nil
    self.name2Gameobjects = {}
    self.type2ComponentTable = {}
end

function UIMessageBox:Dispose()
    self.key2CustomWidgetPools = nil

    -- 清空缓存的Unity相关的GameObject和Component
    self.gameobject = nil
    self.name2Gameobjects = nil
    self.type2ComponentTable = nil
end

--region Get/Set
function UIMessageBox:GetName()
    return self.name
end
---@private
function UIMessageBox:SetName(name)
    self.name = name
end
--endregion

--region 子类可以重写的相关函数
---@param popup Popup
---@param params table
function UIMessageBox:Alert(popup, params)
end

---@protected
---显示的时候，这里可以提前设置控件
function UIMessageBox:OnShow()
end

---@protected
---销毁的时候，这里可以处理事件的注销
function UIMessageBox:OnHide()
end

function UIMessageBox:ClearCallback()
end
--endregion


--region 获取引擎资源对象的接口


---从View中获取GameObject
---@param name string 自定义的名称（默认是控件名称），整个UI预设（包括子预设）唯一
function UIMessageBox:GetGameObject(name)
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
        Log.fatal("UIMessageBox", self:GetName(), " GetGameObject ->", name, "<- is Null !")
        return nil
    end
end

---从View中获取组件
---@param componentTypeName string Unity组件名称
---@param name string 自定义的名称（默认是控件名称），整个UI预设（包括子预设）唯一
---@return UnityEngine.Component
function UIMessageBox:GetUIComponent(componentTypeName, name)
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
        Log.fatal("UIMessageBox", self.name, " GetUIComponent ->", componentTypeName, " ", name, "<- is Null !")
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

        Log.fatal("UIMessageBox ", self:GetName(), " GetUIComponent ->", componentTypeName, " ", name, "<- is Null !")
        return nil
    end
end
--endregion


--region 封装的按钮回调
function UIMessageBox:GetCallBack(popup, btnCallback, param)
    return function()
        --Log.fatal("UIMessageBox:GetCallBack")
        self:SetShow(false)
        if btnCallback then
            btnCallback(param)
        end
        Log.debug("[UIPopup] UIMessageBox:GetCallBack request ClosePopup")
        GameGlobal.UIStateManager():ClosePopup(popup)
    end
end
--endregion

--region 业务不用关心的部分！
---@type view UIView
---@type resRequest ResRequest
function UIMessageBox:Load(view, resRequest)
    self.view = view
    self.luaView = LuaUIView:New()
    self.resRequest = resRequest
    self:Show()
end
---@private
function UIMessageBox:Show()
    -- 这个时候其他View还没有加载
    if self.view then
        self.view:SetShow(true, self)
    end
    if self.luaView then
        self.luaView:SetShow(true, self)
    end
    self:OnShow()
end

---@private
function UIMessageBox:Hide()
    self:OnHide()

    local view = self.view
    if view then
        view:SetShow(false, nil)
    end
    if self.luaView then
        self.luaView:SetShow(false, nil)
    end
    self:DisposeCustomWidgets()
end

function UIMessageBox:UnLoad()
    self:Hide()

    local resRequest = self.resRequest
    if resRequest then
        UIResourceManager.DisposeView(resRequest)
    end

    self.resRequest = nil
    self.view = nil
    self.luaView:Dispose()
    self.luaView = nil
end

function UIMessageBox:SetShow(bShow)
    if self.bShow == bShow then
        return
    end
    self.bShow = bShow
    UIHelper.SetActiveRecursively(self:GetGameObject(), bShow)
end

---@private
---释放动态加载的脚本(和对应资源)
function UIMessageBox:DisposeCustomWidgets()
    local key2CustomWidgetPools = SHALLOW_COPY(self.key2CustomWidgetPools)
    for k, v in pairs(key2CustomWidgetPools) do
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
function UIMessageBox:AddUIEvent(uiEventType, widget, name)
    self.luaView:AddUIEvent(uiEventType, widget, name)
end
--endregion