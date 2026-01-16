--[[
    活动数据加载类 基类
]]

---@class UIActivityDataLoaderBase:Object
_class("UIActivityDataLoaderBase", Object)
UIActivityDataLoaderBase = UIActivityDataLoaderBase

--- 接受参数
function UIActivityDataLoaderBase:SetData(params)
end

--- 加载数据
--- @param TT 协程函数标识
function UIActivityDataLoaderBase:LoadData(TT)
    Log.exception(self._className .. "必须重写 LoadData() 方法:", debug.traceback())
end

function UIActivityDataLoaderBase:CheckOpen()
    Log.exception(self._className .. "必须重写 CheckOpen() 方法:", debug.traceback())
end