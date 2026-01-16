--[[
    常驻内存的资源
]]
CacheResLevel = {
    Minimum = 1, --最少加载，登录后
    Suitable = 2, --合适的量，登录后
    Maximum = 3, --最大加载，进入对局
    Empty = 4, --清空资源
}

_class("DonotDestroyResource", Object)
DonotDestroyResource = DonotDestroyResource

function DonotDestroyResource:Constructor()
    --name:request
    self._resTable = {}
    self._resCount = {} --配置的数量
    self._resLevel = CacheResLevel.Minimum
    self._cfgDonotDestroy = Cfg.cfg_regular_resource {}
    for i, v in ipairs(self._cfgDonotDestroy) do
        self._resCount[v.ResName] = v.DonotDestroyCount
    end
    self._cacheing = false

    self._uiResCache = {}
end

--获取常驻资源数量
function DonotDestroyResource:GetResCount(resName)
    return self._resCount[resName] or 0
end

function DonotDestroyResource:GetUIRes(uiPrefab)
    return self._uiResCache[uiPrefab]
end

function DonotDestroyResource:Dispose()
    for k, v in pairs(self._resTable) do
        for i, r in ipairs(v) do
            r:Dispose()
        end
    end

end

--异步加载资源，通过level调节内存占用
function DonotDestroyResource:ChangeCacheLevel(TT, level)
    if (self._cacheing) then
        return
    end

    level = level or CacheResLevel.Minimum
    if self._resLevel == level then
        return
    end

    self._cacheing = true
    self._resLevel = level

    --常驻内存资源
    local resArray = self._cfgDonotDestroy
    for i, v in ipairs(resArray) do
        local t = self._resTable[v.ResName] or {}
        local count = 1
        if level == CacheResLevel.Suitable then
            count = v.DonotDestroyCount - #t
        elseif level == CacheResLevel.Maximum then
            count = v.CacheCount - #t
        elseif level == CacheResLevel.Empty then
            count = -#t
        end

        --加载资源提升level
        for n = 1, count do
            local res = ResourceManager:GetInstance():AsyncLoadAsset(TT, v.ResName, LoadType[v.LoadType])
            t[#t + 1] = res
        end

        --释放资源降低level
        if count < 0 then
            for n = 1, -count do
                --Log.prof("[donotdestory] dispose resName=", v.ResName, " count=", -count)
                t[#t]:Dispose()
                t[#t] = nil
            end
        end

        self._resTable[v.ResName] = t
    end

    --缓存这个UI
    local uiPrefab = "UIBattle.prefab"
    local uiRes = self._uiResCache[uiPrefab]
    if level == CacheResLevel.Maximum then
        if not uiRes then
            uiRes = ResourceManager:GetInstance():AsyncLoadAsset(TT, uiPrefab, LoadType.GameObject)
            self._uiResCache[uiPrefab] = uiRes
        end
    elseif uiRes then
        self._uiResCache[uiPrefab] = nil
    --uiRes:Dispose()
    end
    self._cacheing = false
    Log.prof("[donnotDestoryResource] change cache  finished!!")
end

--获取资源
function DonotDestroyResource:GetRes(resName)
    local res = self._resTable[resName]
    self._resTable[resName] = {}
    return res
end

--归还资源
function DonotDestroyResource:PutRes(resName, res)
    local t = self._resTable[resName]
    if not t then
        t = {}
        self._resTable[resName] = t
    end
    t[#t + 1] = res
end
