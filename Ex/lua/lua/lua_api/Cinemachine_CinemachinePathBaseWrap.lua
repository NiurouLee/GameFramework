---@class Cinemachine.CinemachinePathBase : UnityEngine.MonoBehaviour
---@field MinPos float
---@field MaxPos float
---@field Looped bool
---@field DistanceCacheSampleStepsPerSegment int
---@field PathLength float
---@field m_Resolution int
---@field m_Appearance Cinemachine.CinemachinePathBase.Appearance
local m = {}
---@param pos float
---@return float
function m:StandardizePos(pos) end
---@param pos float
---@return UnityEngine.Vector3
function m:EvaluatePosition(pos) end
---@param pos float
---@return UnityEngine.Vector3
function m:EvaluateTangent(pos) end
---@param pos float
---@return UnityEngine.Quaternion
function m:EvaluateOrientation(pos) end
---@param p UnityEngine.Vector3
---@param startSegment int
---@param searchRadius int
---@param stepsPerSegment int
---@return float
function m:FindClosestPoint(p, startSegment, searchRadius, stepsPerSegment) end
---@param units Cinemachine.CinemachinePathBase.PositionUnits
---@return float
function m:MinUnit(units) end
---@param units Cinemachine.CinemachinePathBase.PositionUnits
---@return float
function m:MaxUnit(units) end
---@param pos float
---@param units Cinemachine.CinemachinePathBase.PositionUnits
---@return float
function m:StandardizeUnit(pos, units) end
---@param pos float
---@param units Cinemachine.CinemachinePathBase.PositionUnits
---@return UnityEngine.Vector3
function m:EvaluatePositionAtUnit(pos, units) end
---@param pos float
---@param units Cinemachine.CinemachinePathBase.PositionUnits
---@return UnityEngine.Vector3
function m:EvaluateTangentAtUnit(pos, units) end
---@param pos float
---@param units Cinemachine.CinemachinePathBase.PositionUnits
---@return UnityEngine.Quaternion
function m:EvaluateOrientationAtUnit(pos, units) end
function m:InvalidateDistanceCache() end
---@return bool
function m:DistanceCacheIsValid() end
---@param distance float
---@return float
function m:StandardizePathDistance(distance) end
---@param pos float
---@param units Cinemachine.CinemachinePathBase.PositionUnits
---@return float
function m:ToNativePathUnits(pos, units) end
---@param pos float
---@param units Cinemachine.CinemachinePathBase.PositionUnits
---@return float
function m:FromPathNativeUnits(pos, units) end
Cinemachine = {}
Cinemachine.CinemachinePathBase = m
return m