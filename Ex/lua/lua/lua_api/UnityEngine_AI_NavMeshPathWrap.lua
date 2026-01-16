---@class UnityEngine.AI.NavMeshPath : object
---@field corners table
---@field status UnityEngine.AI.NavMeshPathStatus
local m = {}
---@param results table
---@return int
function m:GetCornersNonAlloc(results) end
function m:ClearCorners() end
UnityEngine = {}
UnityEngine.AI = {}
UnityEngine.AI.NavMeshPath = m
return m