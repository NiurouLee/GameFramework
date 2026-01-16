---@class UnityEngine.AI.NavMesh
---@field avoidancePredictionTime float
---@field pathfindingIterationsPerFrame int
---@field AllAreas int
---@field onPreUpdate UnityEngine.AI.NavMesh.OnNavMeshPreUpdate
local m = {}
---@overload fun(sourcePosition:UnityEngine.Vector3, targetPosition:UnityEngine.Vector3, hit:UnityEngine.AI.NavMeshHit, filter:UnityEngine.AI.NavMeshQueryFilter):bool
---@param sourcePosition UnityEngine.Vector3
---@param targetPosition UnityEngine.Vector3
---@param hit UnityEngine.AI.NavMeshHit
---@param areaMask int
---@return bool
function m.Raycast(sourcePosition, targetPosition, hit, areaMask) end
---@overload fun(sourcePosition:UnityEngine.Vector3, targetPosition:UnityEngine.Vector3, filter:UnityEngine.AI.NavMeshQueryFilter, path:UnityEngine.AI.NavMeshPath):bool
---@param sourcePosition UnityEngine.Vector3
---@param targetPosition UnityEngine.Vector3
---@param areaMask int
---@param path UnityEngine.AI.NavMeshPath
---@return bool
function m.CalculatePath(sourcePosition, targetPosition, areaMask, path) end
---@overload fun(sourcePosition:UnityEngine.Vector3, hit:UnityEngine.AI.NavMeshHit, filter:UnityEngine.AI.NavMeshQueryFilter):bool
---@param sourcePosition UnityEngine.Vector3
---@param hit UnityEngine.AI.NavMeshHit
---@param areaMask int
---@return bool
function m.FindClosestEdge(sourcePosition, hit, areaMask) end
---@overload fun(sourcePosition:UnityEngine.Vector3, hit:UnityEngine.AI.NavMeshHit, maxDistance:float, filter:UnityEngine.AI.NavMeshQueryFilter):bool
---@param sourcePosition UnityEngine.Vector3
---@param hit UnityEngine.AI.NavMeshHit
---@param maxDistance float
---@param areaMask int
---@return bool
function m.SamplePosition(sourcePosition, hit, maxDistance, areaMask) end
---@param areaIndex int
---@param cost float
function m.SetAreaCost(areaIndex, cost) end
---@param areaIndex int
---@return float
function m.GetAreaCost(areaIndex) end
---@param areaName string
---@return int
function m.GetAreaFromName(areaName) end
---@return UnityEngine.AI.NavMeshTriangulation
function m.CalculateTriangulation() end
---@overload fun(navMeshData:UnityEngine.AI.NavMeshData, position:UnityEngine.Vector3, rotation:UnityEngine.Quaternion):UnityEngine.AI.NavMeshDataInstance
---@param navMeshData UnityEngine.AI.NavMeshData
---@return UnityEngine.AI.NavMeshDataInstance
function m.AddNavMeshData(navMeshData) end
---@param handle UnityEngine.AI.NavMeshDataInstance
function m.RemoveNavMeshData(handle) end
---@overload fun(link:UnityEngine.AI.NavMeshLinkData, position:UnityEngine.Vector3, rotation:UnityEngine.Quaternion):UnityEngine.AI.NavMeshLinkInstance
---@param link UnityEngine.AI.NavMeshLinkData
---@return UnityEngine.AI.NavMeshLinkInstance
function m.AddLink(link) end
---@param handle UnityEngine.AI.NavMeshLinkInstance
function m.RemoveLink(handle) end
---@return UnityEngine.AI.NavMeshBuildSettings
function m.CreateSettings() end
---@param agentTypeID int
function m.RemoveSettings(agentTypeID) end
---@param agentTypeID int
---@return UnityEngine.AI.NavMeshBuildSettings
function m.GetSettingsByID(agentTypeID) end
---@return int
function m.GetSettingsCount() end
---@param index int
---@return UnityEngine.AI.NavMeshBuildSettings
function m.GetSettingsByIndex(index) end
---@param agentTypeID int
---@return string
function m.GetSettingsNameFromID(agentTypeID) end
function m.RemoveAllNavMeshData() end
UnityEngine = {}
UnityEngine.AI = {}
UnityEngine.AI.NavMesh = m
return m