require "asset_detail"
--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    普通UnityPrefab资源描述
]]
---@class NativeUnityPrefabAsset:IAssetDetail
_class("NativeUnityPrefabAsset", IAssetDetail)
NativeUnityPrefabAsset = NativeUnityPrefabAsset

---@param isShow bool 是否在加载之初就显示
function NativeUnityPrefabAsset:Constructor(path, isShow)
    self.AssetType = "NativeUnityPrefab"
    self.isShow = isShow == nil and true or isShow
end

---@param resource_service ResourcesPoolService
function NativeUnityPrefabAsset:GenerateView(resource_service, finish_callback, ...)
    local orignal_args = {...}
    local orignal_arg_num = select("#", ...)

    ---第二个参数是要显示的entity
    ---@type Entity
    local viewOwnerEntity = orignal_args[2]

    local resRequest = resource_service:LoadGameObject(self._ResPath)
    -- if self._ResPath == 'eff_1401271_atkult_gezi.prefab' then
    --     Log.error('-----------------------------------')
    -- end
    ---@type UnityViewWrapper
    local view = nil
    --注意：这里用组件判断需要加载的ViewWrapper，实际上是View组件与其他组件产生了耦合，需要明确组件之间的初始化顺序
    if resRequest then
        ---@type BuffViewComponent
        local buffCmpt = viewOwnerEntity:BuffView()
        --如果是星灵 或者 幻象怪物(使用星灵模型)
        if self:_IsPet(viewOwnerEntity) or (buffCmpt and buffCmpt:GetBuffValue("ChangeModelWithPetIndex")) then
            local ancName = HelperProxy:GetInstance():GetPetAnimatorControllerName(self._ResPath, PetAnimatorControllerType.Battle)
            local ancRes = resource_service:LoadGameObject(ancName)
            view = UnityPetViewWrapper:New(resource_service, resRequest, ancRes)
        elseif viewOwnerEntity:HasPiece() then 
            view = GridViewWrapper:New(resource_service, resRequest)
        else
            view = UnityViewWrapper:New(resource_service, resRequest)
        end
    end

    orignal_args[orignal_arg_num + 1] = view
    finish_callback(table.unpack(orignal_args, 1, table.maxn(orignal_args)))

    if viewOwnerEntity:HasLocation() then
        local cLocation = viewOwnerEntity:Location()
        cLocation:SyncLocation(viewOwnerEntity)
    end

    if view then
        view:SetVisible(self.isShow)
    end
end

--判断Asset是不是星灵
---@param entity Entity
function NativeUnityPrefabAsset:_IsPet(entity)
    if entity:HasPetPstID() then
        return true
    elseif entity:HasCutscenePlayer() then 
        return true
    else
        ---@type GhostComponent
        local ghost = entity:Ghost()
        if ghost then
            ---@type MainWorld
            local world = entity:GetOwnerWorld()
            ---@type Entity
            local owner = world:GetEntityByID(ghost:GetOwnerID())
            if owner and owner:HasPetPstID() then
                return true
            end
        end
        ---@type GuideGhostComponent
        local guideGhost = entity:GuideGhost()
        if guideGhost then
            ---@type MainWorld
            local world = entity:GetOwnerWorld()
            ---@type Entity
            local owner = world:GetEntityByID(guideGhost:GetOwnerID())
            if owner and owner:HasPetPstID() then
                return true
            end
        end
    end
    return false
end
