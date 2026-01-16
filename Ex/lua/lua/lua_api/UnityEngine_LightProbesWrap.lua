---@class UnityEngine.LightProbes : UnityEngine.Object
---@field positions table
---@field bakedProbes table
---@field count int
---@field cellCount int
local m = {}
---@param position UnityEngine.Vector3
---@param renderer UnityEngine.Renderer
---@param probe UnityEngine.Rendering.SphericalHarmonicsL2
function m.GetInterpolatedProbe(position, renderer, probe) end
---@overload fun(positions:table, lightProbes:table, occlusionProbes:table):void
---@param positions table
---@param lightProbes table
---@param occlusionProbes table
function m.CalculateInterpolatedLightAndOcclusionProbes(positions, lightProbes, occlusionProbes) end
UnityEngine = {}
UnityEngine.LightProbes = m
return m