--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    UISelectObjectPath在Lua侧的代理，负责动态加载脚本和资源,并缓存UICustomWidget
**********************************************************************************************
]] --------------------------------------------------------------------------------------------

---@class UICustomWidgetPool : Object
_class("UICustomWidgetPool", Object)
UICustomWidgetPool = UICustomWidgetPool
local TABLE_CLEAR = table.clear

---@param parent UIController
function UICustomWidgetPool:Constructor(parent, dynamicInfoOfEngine)
    self.parent = parent
    ---@type UICustomWidget[]
    self.uiCustomWidgets = {}

    ---@type UISelectObjectPath
    self.dynamicInfoOfEngine = dynamicInfoOfEngine
end

function UICustomWidgetPool:Dispose()
    local uiCustomWidgets = self.uiCustomWidgets
    for i = 1, #uiCustomWidgets do
        local uiCustomWidget = uiCustomWidgets[i]
        uiCustomWidget:UnLoad()
        uiCustomWidget:Dispose()
    end
    self.uiCustomWidgets = nil

    self.parent = nil
    self.dynamicInfoOfEngine = nil
end
--清空已创建的go
function UICustomWidgetPool:ClearWidgets()
    local uiCustomWidgets = self.uiCustomWidgets
    for i = 1, #uiCustomWidgets do
        local uiCustomWidget = uiCustomWidgets[i]
        uiCustomWidget:UnLoad()
        uiCustomWidget:Dispose()
    end
    self.uiCustomWidgets = {}
end
---@return UICustomWidget[]
function UICustomWidgetPool:GetAllSpawnList()
    return self.uiCustomWidgets
end

---同步加载UISelectObjectPath记录的资源对象，并创建UICustomWidget对象
---@param uiCustomWidgetName string
---@return UICustomWidget
function UICustomWidgetPool:SpawnObject(uiCustomWidgetName)
    local haveItemCount = #self.uiCustomWidgets
    if haveItemCount == 0 then
        -- 创建资源
        local go = self.dynamicInfoOfEngine:SpawnOneObject("0")
        -- 创建脚本
        return self:CreateScript(uiCustomWidgetName, go)
    else
        return self:SpawnObjectFromPool()
    end
end

---异步加载UISelectObjectPath记录的资源对象，并创建UICustomWidget对象
---@param uiCustomWidgetName string
---@return UICustomWidget
function UICustomWidgetPool:AsyncSpawnObject(TT, uiCustomWidgetName)
    local haveItemCount = #self.uiCustomWidgets
    if haveItemCount == 0 then
        -- 创建资源
        local go = self:AsyncCreateResources(TT, "0")
        -- 创建脚本
        return self:CreateScript(uiCustomWidgetName, go)
    else
        self:SpawnObjectFromPool()
    end
end

---同步加载多个UISelectObjectPath记录的资源对象，并创建UICustomWidget对象
---@overload fun(uiCustomWidgetName:string, count:int):UICustomWidget[]
---@param uiCustomWidgetName string
---@param count int
---@param outSpawnList UICustomWidget[]
function UICustomWidgetPool:SpawnObjects(uiCustomWidgetName, count, outSpawnList)
    if outSpawnList then
        TABLE_CLEAR(outSpawnList)
        self:SpawnObjectsInternal(uiCustomWidgetName, count, outSpawnList)
    else
        outSpawnList = {}
        self:SpawnObjectsInternal(uiCustomWidgetName, count, outSpawnList)
        return outSpawnList
    end
end

---异步加载多个UISelectObjectPath记录的资源对象，并创建UICustomWidget对象
---@overload fun(TT, uiCustomWidgetName:string, count:int):UICustomWidget[]
---@param uiCustomWidgetName string
---@param count int
---@param outSpawnList UICustomWidget[]
function UICustomWidgetPool:AsyncSpawnObjects(TT, uiCustomWidgetName, count, outSpawnList)
    if outSpawnList then
        TABLE_CLEAR(outSpawnList)
        self:AsyncSpawnObjectsInternal(TT, uiCustomWidgetName, count, outSpawnList)
    else
        outSpawnList = {}
        self:AsyncSpawnObjectsInternal(TT, uiCustomWidgetName, count, outSpawnList)
        return outSpawnList
    end
end

---@return UISelectObjectPath
function UICustomWidgetPool:Engine()
    return self.dynamicInfoOfEngine
end

--region private
---@private
function UICustomWidgetPool:SpawnObjectsInternal(uiCustomWidgetName, count, outSpawnList)
    if self.uiCustomWidgets == nil then
        Log.fatal("uiCustomWidgets为空：", debug.traceback())
    end

    local haveItemCount = #self.uiCustomWidgets
    local subNum = haveItemCount - count
    for i = 1, -subNum do
        -- 创建资源
        local go = self.dynamicInfoOfEngine:SpawnOneObject(haveItemCount + i - 1)
        -- 创建脚本
        if not self:CreateScript(uiCustomWidgetName, go) then
            return
        end
    end
    self:AfterSpawnObjects(count, outSpawnList)
end
---@private
function UICustomWidgetPool:AsyncSpawnObjectsInternal(TT, uiCustomWidgetName, count, outSpawnList)
    local haveItemCount = #self.uiCustomWidgets
    local subNum = haveItemCount - count
    for i = 1, -subNum do
        -- 创建资源
        local go = self:AsyncCreateResources(TT, haveItemCount + i - 1)
        -- 创建脚本
        if not self:CreateScript(uiCustomWidgetName, go) then
            return
        end
    end
    self:AfterSpawnObjects(count, outSpawnList)
end

---@private
---@param uiCustomWidgetName string
---@return UICustomWidget
function UICustomWidgetPool:CreateUICustomWidget(uiCustomWidgetName)
    -- 然后创建实例
    ---@type UICustomWidget
    local uiCustomWidget = _createInstance(uiCustomWidgetName)
    if not uiCustomWidget then
        Log.fatal(
            "[UI] UICustomWidgetPool:CreateUICustomWidget Error, No UICustomWidget of name = ",
            uiCustomWidgetName
        )
    else
        if not uiCustomWidget:IsChildOf("UICustomWidget") then
            Log.fatal(
                "[UI] UICustomWidgetPool:CreateUICustomWidget Fail, ",
                uiCustomWidgetName,
                " is not inherited from UICustomWidget!"
            )
            return
        end

        uiCustomWidget:SetName(uiCustomWidgetName)
    end
    return uiCustomWidget
end

---@private
---@param uiCustomWidget UICustomWidget
---@param enable boolean
function UICustomWidgetPool:SurplusSpawnItem(uiCustomWidget, enable)
    uiCustomWidget:Enable(enable)
end

---@private
---@param uiCustomWidgetName string
---@param go UnityEngine.GameObject
---@return UICustomWidget
function UICustomWidgetPool:CreateScript(uiCustomWidgetName, go)
    if uiCustomWidgetName then
        local uiCustomWidget = self:CreateUICustomWidget(uiCustomWidgetName)
        if not uiCustomWidget then
            Log.fatal("[UI] UICustomWidgetPool:CreateScript Error, ", uiCustomWidgetName)
            return
        end

        local view = go:GetComponent("UIView")
        if not view then
            Log.fatal("[UI] UICustomWidgetPool:CreateScript Error, View is Null ", uiCustomWidgetName)
            return
        end

        uiCustomWidget:Load(view, self.parent)
        self.uiCustomWidgets[#self.uiCustomWidgets + 1] = uiCustomWidget
        return uiCustomWidget
    end
end

---@private
---@param name string
---@return UnityEngine.GameObject
function UICustomWidgetPool:AsyncCreateResources(TT, name)
    local req
    if self.dynamicInfoOfEngine.selectType == UISelectObjectPath.SelectType.selectByPath then
        req =
            ResourceManager:GetInstance():AsyncLoadAsset(TT, self.dynamicInfoOfEngine.m_ObjectName, LoadType.GameObject)
    end
    return self.dynamicInfoOfEngine:CallAfterLoad(name, req)
end

---@private
function UICustomWidgetPool:AfterSpawnObjects(count, outSpawnList)
    local uiCustomWidgets = self.uiCustomWidgets
    for i = 1, #uiCustomWidgets do
        local uiCustomWidget = uiCustomWidgets[i]
        if i <= count then
            outSpawnList[#outSpawnList + 1] = uiCustomWidget
            uiCustomWidget:Enable(true)
        else
            uiCustomWidget:Enable(false)
        end
    end
end

---@private
---@return UICustomWidget
function UICustomWidgetPool:SpawnObjectFromPool()
    for i = 1, #self.uiCustomWidgets do
        local uiCustomWidget = self.uiCustomWidgets[i]
        uiCustomWidget:Enable(i == 1)
    end
    if #self.uiCustomWidgets > 0 then
        return self.uiCustomWidgets[1]
    end
end
--endregion
