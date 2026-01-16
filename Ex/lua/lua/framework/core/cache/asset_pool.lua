--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    资源Asset池子。
    用来缓存可复用对象
**********************************************************************************************
]]--------------------------------------------------------------------------------------------
require "base_pool"
---@class AssetPool:BasePool
_class("AssetPool", BasePool)
AssetPool = AssetPool

function AssetPool:Constructor(poolType, limit)
    ---@type table<string, ResRequest>
    self.nameToCache = {} --按资源名到缓存的资源
end
function AssetPool:Dispose()
    self:Clear()
end

---清理池子,还会清理统计数据
function AssetPool:Clear()
    AssetPool.super.Clear(self)
    table.clear(self.nameToCache)
end

---获取池子缓存某对象的数量
---@return int
function AssetPool:GetCount(name)
    local resRequest = self.nameToCache[name]
    if resRequest then
        return 1
    end
    return 0
end

--region Private

---@private
function AssetPool:Use(name)
    self.curUseCount = self.curUseCount + 1
    if self.curUseCount > self.maxUsedCount then
        self.maxUsedCount = self.curUseCount
    end

    local t = self.nameToMaxUsedCount[name]
    if not t then
        t = {curUseCount=0, maxUsedCount=0}
        self.nameToMaxUsedCount[name] = t

        t.curUseCount = t.curUseCount + 1
        if t.curUseCount > t.maxUsedCount then
            t.maxUsedCount = t.curUseCount
        end
    end
end

---@private
function AssetPool:UnUse(name)
    self.curUseCount = self.curUseCount - 1

    local t = self.nameToMaxUsedCount[name]
    if t then
        local cnt = t.curUseCount - 1
        t.curUseCount = cnt < 0 and 0 or cnt
    else
        Log.fatal("[Pool] UnUse, cannot find name=", name, " in self.nameToMaxUsedCount")
    end
end

---@private
function AssetPool:Move(name, moveCount)
    local cacheObj = self.nameToCache[name]
    if not cacheObj then--未缓存过该资源
        Log.fatal("[Pool] AssetPool:Move Error, cannot find name,",name)
        return
    end
    if moveCount ~= 1 then
        Log.fatal("[Pool] AssetPool:Move Error, moveCount ,",moveCount)
        return
    end

    local index = table.ikey(self.queue, cacheObj)
    if index < #self.queue then
        table.remove(self.queue, index)
        table.insert(self.queue, cacheObj)
    end
end

---@private
---@return ResRequest
function AssetPool:Pop(name)
    self.total = self.total + 1
    ---@type ResRequest
    local cacheObj = self.nameToCache[name]
    if not cacheObj then--未缓存过该资源
        return nil
    end

    self.hit = self.hit + 1    
    self.nameToCache[name] = nil
    local index = table.ikey(self.queue, cacheObj)
    table.remove(self.queue, index)
    return cacheObj
end
---@private
function AssetPool:Push(name, resRequest)
    local cacheObj = self.nameToCache[name]
    if cacheObj then
        --这个不是错误，有可能就是同时多处地方对该Asset有引用，一起扔回的时候就会打印该log
        Log.warn("[Pool] AssetPool:Push, had same asset in cache,", name)
        resRequest:Dispose()
        resRequest = nil
        return
    end
    self.nameToCache[name] = resRequest

    table.insert(self.queue, resRequest)
    if self.limitn > -1 and #self.queue > self.limitn then --超出限制,挤出最老的CacheObject
        ---@type ResRequest
        local oldestCache = table.remove(self.queue, 1)
        self:RemoveFromCacheTable(oldestCache.m_Name)
    end
end

---@private
function AssetPool:RemoveFromCacheTable(name)
    ---@type ResRequest
    local cacheObj = self.nameToCache[name]
    assert(cacheObj)

    self.nameToCache[name] = nil
    cacheObj:Dispose()
    cacheObj = nil
end
--endregion