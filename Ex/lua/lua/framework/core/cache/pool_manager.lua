--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    资源池子管理器。
    由各系统调用使用。
**********************************************************************************************
]]--------------------------------------------------------------------------------------------

---@class PoolManager:Object
_class("PoolManager", Object)
PoolManager = PoolManager

local TABLE_INSERT = table.insert
local TABLE_CONCAT = table.concat
local CACHE_DIR_NAME = "CachePoolStatistics"
local CACHE_FILE_NAME = "CachePool"
function PoolManager:Constructor()
    ---@type table<string,BasePool>
    self.Pools = {}
    --self.loadType2PoolType = {}

    ---@type UnityEngine.Transform
    self.root = CacheHelper.GetRoot()
end
---@private
function PoolManager:Dispose()
    self:DestroyAllPools()
    UIHelper.DestroyGameObject(self.root)
end
function PoolManager:Init()
    PoolRegister:RegisterPools(self)
end

---主动创建池子，指定池子类型、加载类型、池子上限等。
---可以同时做预加载功能
---@param poolType PoolType
---@param loadType LoadType
---@param limitn int
---@param enableShowInHierarchy bool 实例是否在引擎Hierarchy添加节点显示(默认是true)
---@param name string 资源名称,带后缀,不做预加载则可以为空.
---@param preloadAmount int 预加载数量(默认是1).会受池子上限的影响.
function PoolManager:CreatePool(poolType, loadType, limitn, enableShowInHierarchy, name, preloadAmount)
    self:CreatePoolInternal(poolType, loadType, limitn, enableShowInHierarchy)

    if name and loadType then
        preloadAmount = preloadAmount or 1
        self:PreLoad(poolType, name, loadType, preloadAmount)
    end
end
---主动异步创建池子，指定池子类型、加载类型、池子上限等。
---可以同时做预加载
---@param poolType PoolType
---@param loadType LoadType
---@param limitn int
---@param enableShowInHierarchy bool 实例是否在引擎Hierarchy添加节点显示(默认是true)
---@param name string 资源名称,带后缀,不做预加载则可以为空.
---@param preloadAmount int 预加载数量(默认是1).会受池子上限的影响.
function PoolManager:AsyncCreatePool(TT, poolType, loadType, limitn, enableShowInHierarchy, name, preloadAmount)
    self:CreatePoolInternal(poolType, loadType, limitn, enableShowInHierarchy)

    if name and loadType then
        preloadAmount = preloadAmount or 1
        self:AsyncPreLoad(TT, poolType, name, loadType, preloadAmount)
    end
end

---主动创建池子，指定池子类型、加载类型、池子上限等。
---可以同时并发做预加载
---@param poolType PoolType
---@param loadType LoadType
---@param limitn int
---@param enableShowInHierarchy bool 实例是否在引擎Hierarchy添加节点显示(默认是true)
---@param name string 资源名称,带后缀,不做预加载则可以为空.
---@param preloadAmount int 预加载数量(默认是1).会受池子上限的影响.
function PoolManager:ConcCreatePool(poolType, loadType, limitn, enableShowInHierarchy, name, preloadAmount)
    self:CreatePoolInternal(poolType, loadType, limitn, enableShowInHierarchy)

    if name and loadType then
        preloadAmount = preloadAmount or 1
        self:ConcPreLoad(poolType, name, loadType, preloadAmount)
    end
end

---从池子获取资源对象
---@param poolType PoolType 池子类型
---@param name string 资源名称，带后缀
---@param onSpawned function 获取对象后的的回调(可以为空),参数同返回对象ResRequest
---@return ResRequest
function PoolManager:Spawn(poolType, name, loadType, onSpawned)
    local pool = self.Pools[poolType]
    if not pool then
        Log.fatal("[Pool] PoolManager:Spawn Error, not find pool,",poolType,", need CreatePool first")
        return
    end

    local r = pool:Spawn(name,loadType,onSpawned)
    if loadType == LoadType.GameObject then
        if r and r.Obj then UIHelper.SetActive(r.Obj, true) end
    end
    return r
end

---异步从池子获取资源对象
---@param poolType PoolType 池子类型
---@param name string 资源名称，带后缀
---@param loadType LoadType
---@param onSpawned function 获取对象后的的回调(可以为空),参数同返回对象ResRequest
---@return ResRequest
function PoolManager:AsyncSpawn(TT, poolType, name, loadType, onSpawned)
    local pool = self.Pools[poolType]
    if not pool then
        Log.fatal("[Pool] PoolManager:AsyncSpawn Error, not find pool,",poolType,", need CreatePool first")
        return
    end

    local r = pool:AsyncSpawn(TT, name, loadType, onSpawned)
    if loadType == LoadType.GameObject then
        if r and r.Obj then UIHelper.SetActive(r.Obj, true) end
    end
    return r
end

---将资源对象放回池子
---@param poolType PoolType 池子类型
---@param resRequest ResRequest
---@param onDeSpawned function 放回池子前的回调(可以做重置功能,可以传空),参数是ResRequest
function PoolManager:DeSpawn(poolType, resRequest, onDeSpawned)
    local pool = self.Pools[poolType]
    if not pool then
        Log.fatal("[Pool] PoolManager:DeSpawn Error, not find pool,", poolType,
        ", you should create pool when spawn")
        return
    end

    if resRequest.m_LoadType == LoadType.GameObject then
        if not resRequest or not resRequest.Obj then
            Log.fatal("[Pool] PoolManager:DeSpawn Error, gameobject is nil")
            return
        end

        resRequest.Obj.transform.parent = pool:Root()
        UIHelper.SetActive(resRequest.Obj, false)
    end
    pool:DeSpawn(resRequest, onDeSpawned)
end

---动态设置某个池子的上限，-1表示该池子无上限。
---@param poolType PoolType
---@param limitn int
function PoolManager:SetLimit(poolType, limitn)
    local pool = self.Pools[poolType]
    if pool then
        pool:SetLimit(limitn)
    else
        Log.fatal("[Pool] PoolManager:SetLimit Error, not find pool,", poolType, ", need CreatePool first")
    end
end

---预加载
---@param poolType PoolType 池子类型
---@param name string 资源名称，带后缀
---@param loadType LoadType
---@param preloadAmount int 预加载数量,会受池子上限的影响
function PoolManager:PreLoad(poolType, name, loadType, preloadAmount)
    local pool = self.Pools[poolType]
    if not pool then
        Log.fatal("[Pool] PoolManager:PreLoad Error, not find pool,",poolType,", need CreatePool first")
        return
    end
    
    pool:PreLoad(name, loadType, preloadAmount)
end

---异步预加载
---@param poolType PoolType 池子类型
---@param name string 资源名称，带后缀
---@param loadType LoadType
---@param preloadAmount int 预加载数量,会受池子上限的影响
function PoolManager:AsyncPreLoad(TT, poolType, name, loadType, preloadAmount)
    local pool = self.Pools[poolType]
    if not pool then
        Log.fatal("[Pool] PoolManager:AsyncPreLoad Error, not find pool,",poolType,", need CreatePool first")
        return
    end
    pool:AsyncPreLoad(TT, name, loadType, preloadAmount)
end

---发起并发加载资源请求
---@param poolType PoolType 池子类型
---@param name string 资源名称，带后缀
---@param loadType LoadType
---@param preloadAmount int 预加载数量,会受池子上限的影响
function PoolManager:ConcPreLoad(poolType, name, loadType, preloadAmount)
    local pool = self.Pools[poolType]
    if not pool then
        Log.fatal("[Pool] PoolManager:AsyncPreLoad Error, not find pool,",poolType,", need CreatePool first")
        return
    end
    pool:ConcPreLoad(name, loadType, preloadAmount)
end

---获取已经存在缓存中的资源列表,效率没有CompareInPool好
---命中的资源按命中数量排序，数量越大，排在前面，建议优先预加载,优化IO
---@param names string[] 资源名称数组，带后缀
---@return string[],string[] ret1:命中在缓存的资源列表,ret2:不在缓存的资源列表
function PoolManager:Compare(names)
    if type(names) ~= "table" then
        Log.fatal("[Pool] PoolManager:Compare Error, names not valid")
        return {},names
    end

    local t, missNames = {},{}
    for i = 1, #names do
        local name = names[i]
        local miss = true
        for k ,pool in self.Pools do
            local hitCount = pool:GetCount(name)
            if hitCount > 0 then
                t[#t+1] = {_hitCount = hitCount, _name = name}
                miss = false
                break
            end
        end
        if miss then
            missNames[#missNames+1] = name
        end
    end

    table.sort(t, function(e1,e2)
        return e1._hitCount > e2._hitCount
    end)
    local res = {}
    for i = 1, #t do
        res[#res+1] = t[i]._name
    end
    return res, missNames
end

---从指定缓存池获取已经存在缓存中的资源列表
---命中的资源按命中数量排序，数量越大，排在前面，建议优先预加载,优化IO
---@param poolType PoolType 池子类型
---@param names string[] 资源名称数组，带后缀
---@return string[],string[] ret1:命中在缓存的资源列表,ret2:不在缓存的资源列表
function PoolManager:CompareInPool(poolType, names)
    if type(names) ~= "table" then
        Log.fatal("[Pool] PoolManager:CompareInPool Error, names not valid")
        return {},names
    end

    local pool = self.Pools[poolType]
    if not pool then
        Log.debug("[Pool] PoolManager:CompareInPool, no pool,", poolType,", now")
        return {},names
    end
    
    local t, missNames = {},{}
    for i = 1, #names do
        local name = names[i]
        local hitCount = pool:GetCount(name)
        if hitCount > 0 then
            t[#t+1] = {_hitCount = hitCount, _name = name}
        else
            missNames[#missNames+1] = name
        end
    end

    table.sort(t, function(e1,e2)
        return e1._hitCount > e2._hitCount
    end)
    local res = {}
    for i = 1, #t do
        res[#res+1] = t[i]._name
    end
    return res,missNames
end

--region统计相关接口

---打印池子统计信息
function PoolManager:LogMessages()
    for k, v in pairs(self.Pools) do
        v:LogMessages()
    end
end

---返回池子统计信息
---@return string
function PoolManager:Messages()
    local res = {}
    for k, v in pairs(self.Pools) do
        TABLE_INSERT(res, v:Message())
    end
    return TABLE_CONCAT(res, "\n")
end

---写池子统计信息到文件H3D_Mobile/CachePoolStatistics/CachePool.txt
function PoolManager:WriteMessagesToFile()
    local dir =  string.format("%s%s/", App.StoragePath,CACHE_DIR_NAME)
    local file = dir..string.format("%s%s.txt", CACHE_FILE_NAME, TimeToDate2(_now()))
    Monitor:GetInstance():WriteToFile(dir, file, self:Messages())
end
--endregion

--region 主动清理缓存相关接口

---销毁指定类型的池子
---@param poolType PoolType
function PoolManager:DestroyPool(poolType)
    local pool = self.Pools[poolType]
    if pool then
        pool:Dispose()
        self.Pools[poolType] = nil
    else
        Log.fatal("[Pool]PoolManager:DestroyPool Error,",poolType,", is nil")
    end
end

---将指定类型的池子清空缓存数据
---@param poolType PoolType
function PoolManager:ClearPool(poolType)
    local pool = self.Pools[poolType]
    if pool then
        pool:Clear()
    else
        Log.fatal("[Pool]PoolManager:ClearPool Error,",poolType,", is nil")
    end
end
--endregion

--region Private

---@private
---@return UnityEngine.Transform
function PoolManager:Root()
    return self.root
end

---@private
---@return Pool,int
function PoolManager:PreLoadInternal(poolType, name, loadType, preloadAmount)
    local pool = self.Pools[poolType]
    if not pool then
        Log.fatal("[Pool] PoolManager:PreLoad Error, not find pool,",poolType,", need CreatePool first")
        return
    end


    local hadCount = pool:GetCount(name)
    local leftPreloadAmount = preloadAmount - hadCount
    if leftPreloadAmount <= 0 then
        Log.debug("[Pool] PoolManager:PreLoad return, preloadAmount=",preloadAmount,",pool:",poolType,",",name,", is enough,",hadCount)
        return
    end

    Log.debug("[Pool] PoolManager:PreLoad,",leftPreloadAmount,",",poolType,",",name)
    return pool, leftPreloadAmount
end

---@private
function PoolManager:CreatePoolInternal(poolType,loadType, limitn, enableShowInHierarchy)
    local pool = self.Pools[poolType]
    if pool then
        Log.info("[Pool] PoolManager:CreatePool return,",poolType,", had created")
        return
    end

    --创建
    enableShowInHierarchy= enableShowInHierarchy ~= false

    if loadType == LoadType.GameObject then
        pool = Pool:New(poolType, limitn, enableShowInHierarchy)
    else
        pool = AssetPool:New(poolType, limitn)
    end
    self.Pools[poolType] = pool
end

---@private
---销毁所有池子
function PoolManager:DestroyAllPools()
    for k, v in pairs(self.Pools) do
        v:Dispose()
    end
    table.clear(self.Pools)
end

---@private
---@param loadType LoadType
---@param poolType PoolType
-- function PoolManager:RegisterLoadType2PoolType(loadType, poolType)
--     self.loadType2PoolType[loadType] = poolType
-- end
-- function PoolManager:GetPoolTypeByLoadType(loadType)
--     -- body
-- end
--endregion