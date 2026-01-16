---@class UnityEngine.ParticleSystem.Particle
---@field position UnityEngine.Vector3
---@field velocity UnityEngine.Vector3
---@field animatedVelocity UnityEngine.Vector3
---@field totalVelocity UnityEngine.Vector3
---@field remainingLifetime float
---@field startLifetime float
---@field startColor UnityEngine.Color32
---@field randomSeed uint
---@field axisOfRotation UnityEngine.Vector3
---@field startSize float
---@field startSize3D UnityEngine.Vector3
---@field rotation float
---@field rotation3D UnityEngine.Vector3
---@field angularVelocity float
---@field angularVelocity3D UnityEngine.Vector3
local m = {}
---@param system UnityEngine.ParticleSystem
---@return float
function m:GetCurrentSize(system) end
---@param system UnityEngine.ParticleSystem
---@return UnityEngine.Vector3
function m:GetCurrentSize3D(system) end
---@param system UnityEngine.ParticleSystem
---@return UnityEngine.Color32
function m:GetCurrentColor(system) end
UnityEngine = {}
UnityEngine.ParticleSystem = {}
UnityEngine.ParticleSystem.Particle = m
return m