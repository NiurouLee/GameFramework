--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    资源实例池子。
    用来缓存可复用对象
**********************************************************************************************
]]--------------------------------------------------------------------------------------------
require "base_pool"

---@class Pool:BasePool
_class("Pool", BasePool)
Pool = Pool

function Pool:Constructor(poolType, limit, _enableShowInHierarchy)
    ---@type table<string, table<ResRequest>>
    self.nameToCacheArray = {} --按资源名到缓存数组的资源

    ---@type UnityEngine.Transform
    self.root = nil
    self.enableShowInHierarchy = _enableShowInHierarchy
    self:OnCreated()
end
function Pool:Dispose()
    self:Clear()
    self:OnDestroyed()
end

---清理池子,还会清理统计数据
function Pool:Clear()
    Pool.super.Clear(self)
    table.clear(self.nameToCacheArray)
end

---获取池子缓存某对象的数量
---@return int
function Pool:GetCount(name)
    local cacheArray = self.nameToCacheArray[name]
    if cacheArray then
        return #cacheArray
    end
    return 0
end

--region Private
---@private
---@return UnityEngine.Transform
function Pool:Root()
    return self.root
end

---@private
function Pool:Move(name, moveCount)
    local cacheArray = self.nameToCacheArray[name]
    if not cacheArray then--未缓存过该资源
        Log.fatal("[Pool] Pool:Move Error, cannot find name,",name)
        return
    end
    if moveCount > #cacheArray then
        Log.fatal("[Pool] Pool:Move Error, moveCount,",moveCount,", is bigger than,",#cacheArray)
        return
    end

    for i = 1, moveCount do
        local cacheObj = cacheArray[i]
        local index = table.ikey(self.queue, cacheObj)
        if index < #self.queue then
            table.remove(self.queue, index)
            table.insert(self.queue, cacheObj)
        end
    end
end

---@private
---@return ResRequest
function Pool:Pop(name)
    self.total = self.total + 1
    local cacheArray = self.nameToCacheArray[name]
    if not cacheArray then--未缓存过该资源
        return nil
    end

    self.hit = self.hit + 1
    ---@type ResRequest
    local cacheObj = cacheArray[1]
    table.remove(cacheArray, 1)
    if #cacheArray < 1 then
        self.nameToCacheArray[name] = nil
    end
    local index = table.ikey(self.queue, cacheObj)
    table.remove(self.queue, index)
    return cacheObj
end
---@private
function Pool:Push(name, resRequest)
    local cacheArray = self.nameToCacheArray[name]
    if not cacheArray then
        cacheArray = {}
        self.nameToCacheArray[name] = cacheArray
    end

    table.insert(cacheArray, resRequest)
    table.insert(self.queue, resRequest)
    if self.limitn > -1 and #self.queue > self.limitn then --超出限制,挤出最老的CacheObject
        ---@type ResRequest
        local oldestCache = table.remove(self.queue, 1)
        self:RemoveFromCacheTable(oldestCache.m_Name)
    end
end

---@private
function Pool:RemoveFromCacheTable(name)
    local cacheArray = self.nameToCacheArray[name]
    assert(cacheArray)
    ---@type ResRequest
    local cacheObj = table.remove(cacheArray, 1)
    if #cacheArray < 1 then
        self.nameToCacheArray[name] = nil
    end
    cacheObj:Dispose()
    cacheObj = nil
end

--和引擎相关，todo:考虑优化一下
---@private
function Pool:OnCreated()
    if self.enableShowInHierarchy then
        self.root = UnityEngine.GameObject:New(self.poolType).transform
        self.root.parent = GameGlobal.PoolManager():Root()
    end
end
---@private
function Pool:OnDestroyed()
    if self.enableShowInHierarchy then
        UnityEngine.GameObject.Destroy(self.root.gameObject)
        self.root = nil
    end
end
--endregion