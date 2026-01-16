---@class UILockManagerHelper : object
local m = {}
function m:Dispose() end
function m:Lock() end
function m:UnLock() end
function m:UnLockAll() end
---@param active bool
---@param includeActiveSelf bool
function m:SetHighDepthObjectActive(active, includeActiveSelf) end
UILockManagerHelper = m
return m