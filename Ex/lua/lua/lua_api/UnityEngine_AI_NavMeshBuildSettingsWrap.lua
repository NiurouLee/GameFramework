---@class UnityEngine.AI.NavMeshBuildSettings
---@field agentTypeID int
---@field agentRadius float
---@field agentHeight float
---@field agentSlope float
---@field agentClimb float
---@field minRegionArea float
---@field overrideVoxelSize bool
---@field voxelSize float
---@field overrideTileSize bool
---@field tileSize int
---@field debug UnityEngine.AI.NavMeshBuildDebugSettings
local m = {}
---@param buildBounds UnityEngine.Bounds
---@return table
function m:ValidationReport(buildBounds) end
UnityEngine = {}
UnityEngine.AI = {}
UnityEngine.AI.NavMeshBuildSettings = m
return m