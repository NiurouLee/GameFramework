--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    资源池子。
    用来缓存可复用对象
**********************************************************************************************
]]--------------------------------------------------------------------------------------------
---@class BasePool:Object
_class("BasePool", Object)
BasePool = BasePool

local STRING_FORMAT = string.format
local TABLE_INSERT = table.insert
local TABLE_CONCAT = table.concat
function BasePool:Constructor(poolType, limit)
    self.poolType = poolType
    self.limitn = limit --queue的长度限制，若为-1表示池子没有长度限制
    
    ---@type table<ResRequest>
    self.queue = {} --缓存的队列

    --统计相关
    self.maxUsedCount = 0 --池子最大使用量
    self.curUseCount = 0 --池子当前使用量
	self.hit = 0
    self.total = 0
    ---@type table<string,table>
    self.nameToMaxUsedCount = {} --池子中存储过的各资源的最大使用量
end
function BasePool:Dispose()
end

---清理池子,还会清理统计数据
function BasePool:Clear()
    for i = 1, #self.queue do
        ---@type ResRequest
        local cacheObj = self.queue[i]
        if cacheObj then
            cacheObj:Dispose()
            cacheObj = nil
        end
    end
    table.clear(self.queue)

    --清理统计数据
    self.maxUsedCount = 0
    self.curUseCount = 0
	self.hit = 0
    self.total = 0
    table.clear(self.nameToMaxUsedCount)
end

---从池子中获取对象(同步)
---@param name string 资源名字,带后缀
---@param loadType LoadType 资源类型
---@param onSpawned function 初始化的回调函数，可以为空
---@return ResRequest
function BasePool:Spawn(name, loadType, onSpawned)
    local r = self:Pop(name)
    if not r then
        r = ResourceManager:GetInstance():SyncLoadAsset(name, loadType)
    end

    if r then
        self:Use(name)
        if onSpawned then
            onSpawned(r)
        end
    end
    return r
end

---从池子中获取对象(异步)
---@param name string 资源名字,带后缀
---@param loadType LoadType 资源类型
---@param onSpawned function 初始化的回调函数，可以为空
---@return ResRequest
function BasePool:AsyncSpawn(TT, name, loadType, onSpawned)
    local r = self:Pop(name)
    if not r then
        r = ResourceManager:GetInstance():AsyncLoadAsset(TT, name, loadType)
    end

    if r then
        self:Use(name)
        if onSpawned then
            onSpawned(r)
        end
    end
    return r
end

---将对象扔回池子
---@param resRequest ResRequest
---@param onDeSpawned function 扔回池子之前做的重置回调函数，可以为空
function BasePool:DeSpawn(resRequest, onDeSpawned)
    if not resRequest then Log.fatal("[Pool] DeSpawn Error,resRequest is nil") return end
    local name = resRequest.m_Name
    if onDeSpawned then
        onDeSpawned(resRequest)
    end

    self:UnUse(name)
    if NoCache then
        resRequest:Dispose()
        resRequest = nil
    else
        self:Push(name, resRequest)
    end
end

---设置池子上限
---@param limitn int
function BasePool:SetLimit(limitn)
    Log.debug("[Pool] poolType=",self.poolType, ",SetLimit, old=",self.limitn,", new=",limitn)
    self.limitn = limitn
end

---预加载资源
---@param name string 资源名称，带后缀
---@param loadType LoadType
function BasePool:PreLoad(name, loadType, preloadAmount)
    if NoCache then return end
    local hadCount = self:GetCount(name)
    local loadCount =  preloadAmount - hadCount
    --调整位置的
    local moveCount = preloadAmount >= hadCount and hadCount or preloadAmount
    if moveCount > 0 then
        Log.debug("[Pool] PreLoad,",name,", moveCount=",moveCount)
        self:Move(name, moveCount)
    end
    
    --新加载的
    Log.debug("[Pool] PreLoad,",name,", loadCount=",loadCount)
    for i = 1, loadCount do
        local resRequest = ResourceManager:GetInstance():SyncLoadAsset(name, loadType)
        self:Push(name, resRequest)
        if loadType == LoadType.GameObject and resRequest and resRequest.Obj then
            resRequest.Obj.transform.parent = self:Root()
        end
    end
end

---异步预加载资源
---@param name string 资源名称，带后缀
---@param loadType LoadType
function BasePool:AsyncPreLoad(TT, name, loadType, preloadAmount)
    if NoCache then return end
    local hadCount = self:GetCount(name)
    local loadCount =  preloadAmount - hadCount
    --调整位置的
    local moveCount = preloadAmount >= hadCount and hadCount or preloadAmount
    if moveCount > 0 then
        Log.debug("[Pool] PreLoad,",name,", moveCount=",moveCount)
        self:Move(name, moveCount)
    end
    
    --新加载的
    Log.debug("[Pool] PreLoad,",name,", loadCount=",loadCount)
    for i = 1, loadCount do
        local resRequest = ResourceManager:GetInstance():AsyncLoadAsset(TT, name, loadType)
        self:Push(name, resRequest)
        if loadType == LoadType.GameObject and resRequest and resRequest.Obj then
            resRequest.Obj.transform.parent = self:Root()
        end
    end
end

---发起并发加载资源请求
---@param name string 资源名称，带后缀
---@param loadType LoadType
function BasePool:ConcPreLoad(name, loadType, preloadAmount)
    if NoCache then return end
    local hadCount = self:GetCount(name)
    local loadCount =  preloadAmount - hadCount
    --调整位置的
    local moveCount = preloadAmount >= hadCount and hadCount or preloadAmount
    if moveCount > 0 then
        Log.debug("[Pool] PreLoad,",name,", moveCount=",moveCount)
        self:Move(name, moveCount)
    end
    
    --新加载的
    Log.debug("[Pool] PreLoad,",name,", loadCount=",loadCount)
    for i = 1, loadCount do
        TaskManager:GetInstance():StartTask(self.AsyncLoad, self, name, loadType)
    end
end

function BasePool:AsyncLoad(TT, name, loadType)
    local resRequest = ResourceManager:GetInstance():AsyncLoadAsset(TT, name, loadType)
    self:Push(name, resRequest)
    if loadType == LoadType.GameObject and resRequest and resRequest.Obj then
        resRequest.Obj.transform.parent = self:Root()
    end
end

---获取池子缓存对象总数
---@return int
function BasePool:Count()
    return #self.queue
end
---获取池子缓存某对象的数量
---@return int
function BasePool:GetCount(name)
    return 0
end

---打印池子统计信息
function BasePool:LogMessages()
    Log.sys(self:Message())
end

---@return string
function BasePool:Message()
    local messageTable = {}

    local t1, t2 = {},{}
    local cnt = 0
    for k,v in pairs(self.nameToMaxUsedCount) do
        cnt = cnt + v.maxUsedCount
        TABLE_INSERT(t1, STRING_FORMAT("Res name[%s], maxUsedCount[%d]", k,v.maxUsedCount))
        TABLE_INSERT(t2, STRING_FORMAT("Res name[%s], PreLoadAmount[%d]", k, v.maxUsedCount))
    end

    TABLE_INSERT(messageTable,STRING_FORMAT("--------------------Pool[%s]--------------------", self.poolType))
    TABLE_INSERT(messageTable,STRING_FORMAT("maxUsedCount[%d],limitn[%d],curCount[%d],hit[%d], total[%d], hitRate[%f%%]", 
    self.maxUsedCount, self.limitn, self:Count(), self.hit, self.total, self.total==0 and 0 or (self.hit*100/self.total)))

    TABLE_INSERT(messageTable, TABLE_CONCAT(t1,"\n"))

    TABLE_INSERT(messageTable, "\nPool limit suggest: ")
    TABLE_INSERT(messageTable, STRING_FORMAT("limit[%d]", cnt))
    if #t2 > 0 then
        TABLE_INSERT(messageTable, "Pool PreLoad suggest: ")
        TABLE_INSERT(messageTable, STRING_FORMAT("%s", TABLE_CONCAT(t2, "\n")))
    end
    TABLE_INSERT(messageTable, "\n")
    
    return TABLE_CONCAT(messageTable, "\n")
end

--region Private
---@private
---@return UnityEngine.Transform
function BasePool:Root()
    return
end

---@private
function BasePool:Use(name)
    self.curUseCount = self.curUseCount + 1
    if self.curUseCount > self.maxUsedCount then
        self.maxUsedCount = self.curUseCount
    end

    local t = self.nameToMaxUsedCount[name]
    if not t then
        t = {curUseCount=0, maxUsedCount=0}
        self.nameToMaxUsedCount[name] = t
    end
    t.curUseCount = t.curUseCount + 1
    if t.curUseCount > t.maxUsedCount then
        t.maxUsedCount = t.curUseCount
    end
end
---@private
function BasePool:UnUse(name)
    self.curUseCount = self.curUseCount - 1

    local t = self.nameToMaxUsedCount[name]
    if t then
        t.curUseCount = t.curUseCount - 1
    else
        Log.fatal("[Pool] UnUse, cannot find name=", name, " in self.nameToMaxUsedCount")
    end
end
---@private
function BasePool:Move(name, moveCount)
    -- body
end

---@return ResRequest
function BasePool:Pop(name)
    return
end
---@private
function BasePool:Push(name, resRequest)
end

---@private
function BasePool:RemoveFromCacheTable(name)
end

--和引擎相关，todo:考虑优化一下
---@private
function BasePool:OnCreated()
end
---@private
function BasePool:OnDestroyed()
end
--endregion