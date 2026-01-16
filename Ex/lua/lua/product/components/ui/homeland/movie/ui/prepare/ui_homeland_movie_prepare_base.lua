--准备阶段基类
---@class UIHomelandMoviePrepareBase : UICustomWidget
_class("UIHomelandMoviePrepareBase", UICustomWidget)
UIHomelandMoviePrepareBase = UIHomelandMoviePrepareBase

--进入
---@param prepareType MoviePrepareType 
function UIHomelandMoviePrepareBase:OnEnter(prepareType)
    self:Refresh(prepareType)
end

--退出
---@param prepareType MoviePrepareType 
function UIHomelandMoviePrepareBase:OnExit(prepareType)
end

--检查推出
---@param prepareType MoviePrepareType 
---@return boolean true：可以退出 fasle 不可推出
function UIHomelandMoviePrepareBase:CheckExit(prepareType)
    return true
end

--根据数据刷新
---@param prepareType MoviePrepareType 
function UIHomelandMoviePrepareBase:Refresh(prepareType)
end

--清理接口
---@param prepareType MoviePrepareType 
function UIHomelandMoviePrepareBase:Clear(prepareType)
    MoviePrepareData:GetInstance():ClearData(prepareType)
    self:Refresh(prepareType)
end