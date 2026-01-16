--[[******************************************************************************************
    Asset Detail Extensions

    职责：
    Asset Detail 是一份需要完整打包的资源描述
    描述资源的特化配置细节，使其对外隔离， ResourceService能够解读AssetDetail中信息的含义

    扩展大致会在2个方向：
    1、配置更复杂的资源使用细节
        eg：是否要异步加载、材质指定、动画状态机指定 等

    2、业务向的特化资源描述
        eg：SLG游戏的一队士兵方阵，在逻辑上始终是看做一个整体，因此绝不想把阵中每个兵都实现成一个Entity
            由于士兵模型、阵旗、将领模型 这些我都想做组合定制，此时就可以特化一个 ArmyAssetDetail 进行描述
            同时有必要的话也特化一个 ArmyViewWrapper、让这些纯渲染单元以一种轻量级的方式组合、控制。（Entity太重了）

        eg：要使用项目特制的Avatar描述，如炫舞那种 model + bodyparts[]

--******************************************************************************************]] --
---@class IAssetDetail:Object
_class("IAssetDetail", Object)
IAssetDetail = IAssetDetail

function IAssetDetail:Constructor(resPath)
    self.AssetType = "undefinition"
    self.AsyncLoad = false -- 是否异步加载
    self._ResPath = resPath
end

---@param resource_service IResourceService
function IAssetDetail:GenerateView(resource_service, finish_callback, ...)
end
function IAssetDetail:GetResPath()
    return self._ResPath
end
