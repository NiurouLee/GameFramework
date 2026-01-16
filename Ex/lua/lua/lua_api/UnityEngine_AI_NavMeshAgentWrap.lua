---@class UnityEngine.AI.NavMeshAgent : UnityEngine.Behaviour
---@field destination UnityEngine.Vector3
---@field stoppingDistance float
---@field velocity UnityEngine.Vector3
---@field nextPosition UnityEngine.Vector3
---@field steeringTarget UnityEngine.Vector3
---@field desiredVelocity UnityEngine.Vector3
---@field remainingDistance float
---@field baseOffset float
---@field isOnOffMeshLink bool
---@field currentOffMeshLinkData UnityEngine.AI.OffMeshLinkData
---@field nextOffMeshLinkData UnityEngine.AI.OffMeshLinkData
---@field autoTraverseOffMeshLink bool
---@field autoBraking bool
---@field autoRepath bool
---@field hasPath bool
---@field pathPending bool
---@field isPathStale bool
---@field pathStatus UnityEngine.AI.NavMeshPathStatus
---@field pathEndPosition UnityEngine.Vector3
---@field isStopped bool
---@field path UnityEngine.AI.NavMeshPath
---@field navMeshOwner UnityEngine.Object
---@field agentTypeID int
---@field areaMask int
---@field speed float
---@field angularSpeed float
---@field acceleration float
---@field updatePosition bool
---@field updateRotation bool
---@field updateUpAxis bool
---@field radius float
---@field height float
---@field obstacleAvoidanceType UnityEngine.AI.ObstacleAvoidanceType
---@field avoidancePriority int
---@field isOnNavMesh bool
local m = {}
---@param target UnityEngine.Vector3
---@return bool
function m:SetDestination(target) end
---@param activated bool
function m:ActivateCurrentOffMeshLink(activated) end
function m:CompleteOffMeshLink() end
---@param newPosition UnityEngine.Vector3
---@return bool
function m:Warp(newPosition) end
---@param offset UnityEngine.Vector3
function m:Move(offset) end
function m:ResetPath() end
---@param path UnityEngine.AI.NavMeshPath
---@return bool
function m:SetPath(path) end
---@param hit UnityEngine.AI.NavMeshHit
---@return bool
function m:FindClosestEdge(hit) end
---@param targetPosition UnityEngine.Vector3
---@param hit UnityEngine.AI.NavMeshHit
---@return bool
function m:Raycast(targetPosition, hit) end
---@param targetPosition UnityEngine.Vector3
---@param path UnityEngine.AI.NavMeshPath
---@return bool
function m:CalculatePath(targetPosition, path) end
---@param areaMask int
---@param maxDistance float
---@param hit UnityEngine.AI.NavMeshHit
---@return bool
function m:SamplePathPosition(areaMask, maxDistance, hit) end
---@param areaIndex int
---@param areaCost float
function m:SetAreaCost(areaIndex, areaCost) end
---@param areaIndex int
---@return float
function m:GetAreaCost(areaIndex) end
UnityEngine = {}
UnityEngine.AI = {}
UnityEngine.AI.NavMeshAgent = m
return m