---@class WaterDepthCmd : UnityEngine.MonoBehaviour
local m = {}
function m:OnDestroy() end
---@param camera UnityEngine.Camera
function m:RenderTargetDepth(camera) end
function m:UpdateAllRender() end
---@param target UnityEngine.GameObject
function m:AddTarget(target) end
---@param target UnityEngine.GameObject
function m:RemoveTarget(target) end
WaterDepthCmd = m
return m