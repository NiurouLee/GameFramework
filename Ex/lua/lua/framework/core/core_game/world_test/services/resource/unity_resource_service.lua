--[[------------------------------------------------------------------------------------------
    UnityResourceService 示例
]] --------------------------------------------------------------------------------------------
require "i_resource_service"

---@class UnityResourceService:Singleton
_class("UnityResourceService", Singleton)
UnityResourceService = UnityResourceService

function UnityResourceService:Constructor()
end

---@return ResRequest
function UnityResourceService:LoadGameObject(ResPath)
    local request = ResourceManager:GetInstance():SyncLoadAsset(ResPath, LoadType.GameObject)
    if request == nil then
        --需要检查资源的时候，可以打开
        --G_ShowException("配置错误 ,没有找到资源 "..ResPath)
        Log.fatal("LoadGameObject failed", "[" .. ResPath .. "]")
        return
    end

    local u3dGo = request.Obj
    u3dGo:SetActive(true)
    return request
end

---@param view UnityViewWrapper
function UnityResourceService:DestroyView(view)
    --Test Simple
    if view.ViewType == "UnitySimple" then
        view.Transform = nil
        view.ResRequest:Dispose()
        view.ResRequest = nil
        view.GameObject = nil
    end
end
