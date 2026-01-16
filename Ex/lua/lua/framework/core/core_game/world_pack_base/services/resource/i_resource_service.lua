--[[
    处理资源管理，在resourceManager的基础之上，为业务层提供更方便资源加载帮助函数
    在不同的项目中，可能需要实现自己的ResourceService，来处理不同的资源加载逻辑。
    比如用Unity的项目和用UE的项目他们一定会有不同的资源加载逻辑

    此外 这里还可以负责资源缓存与释放的逻辑
]]

---@class IResourceService:Object
_class( "IResourceService", Object )
IResourceService = IResourceService

function IResourceService:Constructor()
end