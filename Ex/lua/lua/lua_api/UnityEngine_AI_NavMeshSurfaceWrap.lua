---@class UnityEngine.AI.NavMeshSurface : UnityEngine.MonoBehaviour
---@field agentTypeID int
---@field collectObjects UnityEngine.AI.CollectObjects
---@field size UnityEngine.Vector3
---@field center UnityEngine.Vector3
---@field layerMask UnityEngine.LayerMask
---@field useGeometry UnityEngine.AI.NavMeshCollectGeometry
---@field defaultArea int
---@field ignoreNavMeshAgent bool
---@field ignoreNavMeshObstacle bool
---@field overrideTileSize bool
---@field tileSize int
---@field overrideVoxelSize bool
---@field voxelSize float
---@field buildHeightMesh bool
---@field navMeshData UnityEngine.AI.NavMeshData
---@field activeSurfaces table
local m = {}
function m:AddData() end
function m:RemoveData() end
---@return UnityEngine.AI.NavMeshBuildSettings
function m:GetBuildSettings() end
function m:BuildNavMesh() end
---@param data UnityEngine.AI.NavMeshData
---@return UnityEngine.AsyncOperation
function m:UpdateNavMesh(data) end
UnityEngine = {}
UnityEngine.AI = {}
UnityEngine.AI.NavMeshSurface = m
return m