--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    操作UIExtendLogic的管理器，并且可以由项目先注册，然后进行继承扩展
    默认动态将UI放在high层，一般在这层就够了
**********************************************************************************************
]]--------------------------------------------------------------------------------------------
---@class UIExtendManager : Object
_class( "UIExtendManager", Object )
UIExtendManager = UIExtendManager

function UIExtendManager:Constructor()
    Log.debug("[UIExtend] UIExtendManager:Constructor")
    ---@type table<UIExtendLogic>
    self.logics = {}
    self.seq = 0
end

---不可以被子类重写
function UIExtendManager:Dispose()
    Log.debug("[UIExtend] UIExtendManager:Dispose")
    for _, v in pairs(self.logics) do
        v:Dispose()
    end
    self.logics = nil
    self.seq = 0
end

--region 子类可以重写的方法
---@protected
function UIExtendManager:OnDestroy()
end
--endregion

---创建UIExtendLogic
---@param uiName string 继承自UIExtendLogic的类名称
---@param uiPrefabName string 和UI扩展逻辑对应的UI资源
---@param ... any 传入UIExtendLogic:OnCreate的任意参数
---@return id
function UIExtendManager:CreateUI(uiName, uiPrefabName, ...)
    --加载UI预设，同时会依赖加载图集的AB
    local view, resRequest = UIResourceManager.GetView(uiName, uiPrefabName)
    if not view then
        Log.fatal("[UIExtend] UIExtendManager:CreateUI, Load Resources error: ", uiPrefabName)
        return
    end

    --创建脚本
    local logic,id = self:CreateExtendLogic(uiName)
    if not logic then
        resRequest:Dispose()
        return
    end
    logic:Load(view, resRequest)--绑定资源
    logic:Show()
    self:OnUILoaded(uiName, logic, ...)
    return id
end

---异步创建UIExtendLogic
---@param TT TT 协程函数标识
---@param uiName string 继承自UIExtendLogic的类名称
---@param uiPrefabName string 和UI扩展逻辑对应的UI资源
---@param ... any 传入UIExtendLogic:OnCreate的任意参数
---@return id
function UIExtendManager:CreateUIAsync(TT, uiName, uiPrefabName, ...)
    --异步加载UI预设，同时会依赖加载图集的AB
    local view, resRequest = UIResourceManager.GetViewAsync(TT, uiName, uiPrefabName)
    if not view then
        Log.fatal("[UIExtend] UIExtendManager:CreateUIAsync, Load Resources error: ", uiPrefabName)
        return
    end

    --创建脚本
    local logic,id = self:CreateExtendLogic(uiName)
    if not logic then
        resRequest:Dispose()
        return
    end
    logic:Load(view, resRequest)--绑定资源
    logic:Show()
    self:OnUILoaded(uiName, logic, ...)
    return id
end

---销毁UIExtendLogic
---@param logicID int 创建UIExtendLogic时返回的id
function UIExtendManager:DestroyUI(logicID)
    local logic = self.logics[logicID]
    if logic then
        logic:Dispose()
        self.logics[logicID] = nil
    end
end

--region Private
---@private
---@param logic UIExtendLogic
function UIExtendManager:OnUILoaded(uiName, logic, ...)
    logic:SetName(uiName)
    logic:OnCreate(...)
    GameGlobal.UIStateManager():SetHighParent(logic)
end

---@private
---@return UIExtendLogic, int
function UIExtendManager:CreateExtendLogic(uiName)
    local id = 0
    local logic = _createInstance(uiName)
    if logic then
        if not logic:IsChildOf("UIExtendLogic") then
            Log.fatal("[UIExtend] UIExtendManager:CreateExtendLogic Fail, ", uiName, " is not inherited from UIExtendLogic!")
            return
        end
        id = self.seq + 1
        if id < 0 then id = 1 end
        self.seq = id
        self.logics[id] = logic
    else
        Log.fatal("[UIExtend] UIExtendManager:CreateExtendLogic Error, ", uiName)
    end

	return logic, id
end
--endregion