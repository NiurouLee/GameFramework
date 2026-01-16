---@class UIDynamicScrollViewInitParam : object
---@field mDistanceForRecycle0 float
---@field mDistanceForNew0 float
---@field mDistanceForRecycle1 float
---@field mDistanceForNew1 float
---@field mSmoothDumpRate float
---@field mSnapFinishThreshold float
---@field mSnapVecThreshold float
---@field mItemDefaultWithPaddingSize float
local m = {}
---@return UIDynamicScrollViewInitParam
function m.CopyDefaultInitParam() end
UIDynamicScrollViewInitParam = m
return m