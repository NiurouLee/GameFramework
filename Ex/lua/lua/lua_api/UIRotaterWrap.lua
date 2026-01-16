---@class UIRotater : UnityEngine.MonoBehaviour
---@field step float
---@field onAngleChanged UIRotater.AngleChangeEvent
---@field pointer UnityEngine.Transform
local m = {}
---@param angle float
function m:SetAngle(angle) end
UIRotater = m
return m