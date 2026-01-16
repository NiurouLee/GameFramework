--region资源管理器
---@class ResourceManager:Singleton
---@field GetInstance ResourceManager
_class("ResourceManager", Singleton)
ResourceManager = ResourceManager

local unpack = table.unpack
---私有函数实例
---@private
function ResourceManager:Constructor()
    ---私有变量
    ---@private
    self.finishes = {}
    ---@private
    self.loader = ResourceLoader:New()
    ---缓存常驻内存资源
    if PUBLIC then
        ---shader
        self.loader:CacheAB(App.ShaderABName)
        ---font
        App.CacheFont = true
    end
    self.loader:OnFinish(self.OnFinish, self)
    if App.Profiler then
        self.traces = {}
        self.profiler = true
    end
    if App.SpeedStatistics then
        Monitor:GetInstance()
    end
end

---同步加载资源(此方法已废弃、暂时可用，建议使用SyncLoad)
---@public
---@type deprecated
---@param name string 资源名字,带后缀
---@param loadType LoadType 资源类型
---@return ResRequest
function ResourceManager:SyncLoadAsset(name, loadType)
    Log.info("[ResourceManager Lua] Loading Asset: " .. name)
    local request = self.loader:SyncLoadAsset(name, loadType)
    if self.profiler then
        if not self.traces[name] then
            self.traces[name] = {}
        end
        self.traces[name][request:GetHashCode()] = debug.traceback(nil, 2)
    end
    return request
end

---协程方式同步加载资源
---@public
---@param TT  TT 协程函数标识
---@param name string 资源名字,带后缀
---@param loadType LoadType 资源类型
---@return ResRequest
function ResourceManager:SyncLoad(TT, name, loadType)
    local request = self.loader:SyncLoadAsset(name, loadType)
    if self.profiler then
        if not self.traces[name] then
            self.traces[name] = {}
        end
        self.traces[name][request:GetHashCode()] = debug.traceback(nil, 2)
    end
    return request
end

---协程方式异步加载资源
---@public
---@param TT  TT 协程函数标识
---@param name string 资源名字带后缀
---@param loadType LoadType 资源类型
---@return ResRequest
function ResourceManager:AsyncLoadAsset(TT, name, loadType)
    local id = GetCurTaskId()
    local request =
        self:AsyncLoad(
        name,
        loadType,
        function(ready)
            if not ready then
                RESUME(TT, id)
            end
        end
    )
    if not request then
        Log.error("AsyncLoadAsset failed:", name)
        return nil
    end
    if self.profiler then
        if not self.traces[name] then
            self.traces[name] = {}
        end
        self.traces[name][request:GetHashCode()] = debug.traceback(nil, 2)
    end
    if not request:Ready() then
        SUSPEND(TT)
    end
    return request
end

---异步加载资源
---@private
---@param name string 资源名字,带后缀
---@param loadType LoadType 资源类型
---@param func function 加载完回调函数
---@param ... any 各种参数
function ResourceManager:AsyncLoad(name, loadType, func, ...)
    local request = self.loader:AsyncLoadAsset(name, loadType)
    if not request then
        return nil
    end
    if request:Ready() then
        func(true, ...)
    else
        self.finishes[request] = {func = func, args = {...}}
    end
    return request
end

---@private
function ResourceManager:OnFinish(request)
    local finish = self.finishes[request]
    if finish then
        finish.func(unpack(finish.args, 1, table.maxn(finish.args)))
    end
    self.finishes[request] = nil
end

---得到文件加载绝对路径
---@public
---@param name string 资源名字,带后缀
---@param loadType LoadType 资源类型
---@return string 文件加载绝对路径
function ResourceManager:GetAssetPath(name, loadType)
    return self.loader:GetAssetPath(name, loadType)
end

---得到文件里的内容，支持xml，json，txt等格式
---@public
---@param name string 资源名字,带后缀
---@return string 文件内容
function ResourceManager:GetTextAsset(name)
    local path = self.loader:GetAssetPath(name, LoadType.Txt)
    if path then
        local file = io.open(path, "r")
        local text = file:read("a")
        file:close()
        return text
    end
end

---设置一帧能同步加载的资源数量
---@public
function ResourceManager:SetSyncLoadNum(num)
    self.loader:SetSyncLoadNum(num)
end

---是否有资源
---@public
---@param name string 资源名，包含后缀
---@return bool
function ResourceManager:HasResource(name)
    return self.loader:HasResource(name)
end

---是否有lua文件
---@public
---@param name string lua文件名，不带后缀
---@return bool
function ResourceManager:HasLua(name)
    return self.loader:HasLua(name)
end

---得到资源加载trace
---@public
---@return table traces
function ResourceManager:GetTraces()
    return self.traces
end

---卸载所有已加载的ab
---@public
function ResourceManager:UnloadAllABs()
    if not PUBLIC then
        return
    end

    local abs = App.GetABs()
    local length = abs.Length
    local tb = {}
    for i = 0, length - 1 do
        if abs[i] ~= "h3d_ttf.bundle" then
            self.loader:DiposeAB(abs[i])
        end
    end
    local name = App.ShaderABName
    self.loader:CacheAB(name)
end

---缓存常驻内存的 AB，一般用于 Shader 或 ShaderLOD 优化中的法线贴图 AB 等
---NOTE: 记得调用 DisposeAB 手动释放
---@public
function ResourceManager:CacheAB(abName)
    self.loader:CacheAB(abName)
end

---手动主动卸载 AB，譬如常驻内存的 CacheAB 等，实际调用的 AssetBundle.Unload(false)
---@public
function ResourceManager:DisposeAB(abName)
    self.loader:DiposeAB(abName)
end

---@private
function ResourceManager:Dispose()
    self.loader:Dispose()
    self.loader = nil
end

function ResourceManager:WarmUpCoreGameShader()
    self.loader:WarmUpShader()
end
--endregion
