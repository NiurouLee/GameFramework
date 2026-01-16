--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    UI资源加载相关接口
**********************************************************************************************
]] --------------------------------------------------------------------------------------------

---@class UIResourceManager:Singleton
_class("UIResourceManager", Singleton)
local TABLE_CLEAR = table.clear

---加载UI窗口
---该接口会等待其图集准备好返回
---@param uiName string
---@param uiPrefab string
function UIResourceManager.GetViewAsync(TT, uiName, uiPrefab)
    --加载UI预设
    --Log.debug("[UI] UIResourceManager.GetViewAsync, begin Load View, ", uiPrefab)
    
    local resRequest = GameGlobal.DonotDestroyRes():GetUIRes(uiPrefab)
    if not resRequest then
        resRequest = ResourceManager:GetInstance():AsyncLoadAsset(TT, uiPrefab, LoadType.GameObject)
    end

    local uiGo = resRequest.Obj
    if not uiGo then
        Log.fatal("[UI] UIResourceManager.GetViewAsync, Load View error: ", uiPrefab)
        return nil
    end
    Log.debug("[UI] UIResourceManager.GetViewAsync, end Load View, ", uiPrefab)

    uiGo.name = uiName
    return uiGo:GetComponent("UIView"), resRequest
end
function UIResourceManager.GetView(uiName, uiPrefab)
    --加载UI预设
    Log.debug("[UI] UIResourceManager.GetView, begin Load View, ", uiPrefab)
    local resRequest = ResourceManager:GetInstance():SyncLoadAsset(uiPrefab, LoadType.GameObject)
    local uiGo = resRequest.Obj
	if not uiGo then
        Log.fatal("[UI] UIResourceManager.GetView, Load View error: ", uiPrefab)
		return nil
    end
    Log.debug("[UI] UIResourceManager.GetView, end Load View, ", uiPrefab)

    uiGo.name = uiName
    return uiGo:GetComponent("UIView"), resRequest
end

function UIResourceManager.DisposeView(resRequest)
    resRequest:Dispose()
end

---主动加载Assets资源
---@param name string 资源名称，需要加后缀
---@param loadType LoadType
---@param name2Assets table<string,ResRequest>
---@return UnityEngine.Object
function UIResourceManager.GetAsset(name, loadType, name2Assets)
    local asset = name2Assets[name]
    if asset then
        return asset.Obj
    end

    local resRequest = ResourceManager:GetInstance():SyncLoadAsset(name, loadType)
    name2Assets[name] = resRequest
    return resRequest.Obj
end

---主动异步加载Assets资源
---@param name string 资源名称，需要加后缀
---@param loadType LoadType
---@param name2Assets table<string,ResRequest>
---@return UnityEngine.Object
function UIResourceManager.AsyncGetAsset(TT, name, loadType, name2Assets)
    local asset = name2Assets[name]
    if asset then
        return asset.Obj
    end

    local resRequest = ResourceManager:GetInstance():AsyncLoadAsset(TT, name, loadType)
    name2Assets[name] = resRequest
    return resRequest.Obj
end

---主动释放Assets资源
---@param name string 资源名称，需要加后缀
---@param uiName string
---@param name2Assets table<string,ResRequest>
function UIResourceManager.DisposeAsset(name, uiName, name2Assets)
    local asset = name2Assets[name]
    if asset then
        asset:Dispose()
    else
        Log.fatal("[UI] UIResourceManager.DisposeAsset Error, no asset name ", name, " in ui ", uiName)
    end
    name2Assets[name] = nil
end

---释放所有主动加载的Assets资源
---为了防止业务层忘记释放Asset,统一在Hide的时候释放所有主动加载的Asset
function UIResourceManager.DisposeAllAssets(name2Assets)
    for k, v in pairs(name2Assets) do
        v:Dispose()
    end
    TABLE_CLEAR(name2Assets)
end
---同步加载UI GameObject
---@param name string 资源名称，需要加后缀
---@param go2ResRequest table<UnityEngine.GameObject, ResRequest>
---@return UnityEngine.GameObject
function UIResourceManager.SyncGetGameObject(name, go2ResRequest)
    local resRequest = ResourceManager:GetInstance():SyncLoadAsset(name, LoadType.GameObject)
    local go = resRequest.Obj
    UIHelper.SetActive(go, true)
    go2ResRequest[go] = resRequest
    return go
end

---异步加载UI GameObject
---@param name string 资源名称，需要加后缀
---@param go2ResRequest table<UnityEngine.GameObject, ResRequest>
---@return UnityEngine.GameObject
function UIResourceManager.AsyncGetGameObject(TT, name, go2ResRequest)
    local resRequest = ResourceManager:GetInstance():AsyncLoadAsset(TT, name, LoadType.GameObject)
    local go = resRequest.Obj
    if not go then
        Log.fatal("[UI] UIResourceManager.AsyncGetGameObject error: ", name)
        return nil
    end

    UIHelper.SetActive(go, true)
    go2ResRequest[go] = resRequest
    return go
end

---销毁UI GameObject
---@param go UnityEngine.GameObject
---@param go2ResRequest table<UnityEngine.GameObject, ResRequest>
function UIResourceManager.DisposeGameObject(go, go2ResRequest)
    local resRequest = go2ResRequest[go]
    if resRequest then
        go2ResRequest[go] = nil
        resRequest:Dispose()
    end
end

---释放所有主动加载的UI GameObject
---@param go2ResRequest table<UnityEngine.GameObject, ResRequest>
function UIResourceManager.DisposeAllGameObjects(go2ResRequest)
    for k, v in pairs(go2ResRequest) do
        v:Dispose()
    end
    TABLE_CLEAR(go2ResRequest)
end