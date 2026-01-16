---@class Cinemachine.CinemachineSmoothPath : Cinemachine.CinemachinePathBase
---@field MinPos float
---@field MaxPos float
---@field Looped bool
---@field DistanceCacheSampleStepsPerSegment int
---@field m_Looped bool
---@field m_Waypoints table
---@field m_Resolution int
---@field m_Appearance Cinemachine.CinemachinePathBase.Appearance
local m = {}
function m:InvalidateDistanceCache() end
---@param pos float
---@return UnityEngine.Vector3
function m:EvaluatePosition(pos) end
---@param pos float
---@return UnityEngine.Vector3
function m:EvaluateTangent(pos) end
---@param pos float
---@return UnityEngine.Quaternion
function m:EvaluateOrientation(pos) end
Cinemachine = {}
Cinemachine.CinemachineSmoothPath = m
return m