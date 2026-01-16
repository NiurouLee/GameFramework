---@class UnityEngine.UI.Shadow : UnityEngine.UI.BaseMeshEffect
---@field effectColor UnityEngine.Color
---@field effectDistance UnityEngine.Vector2
---@field useGraphicAlpha bool
local m = {}
---@param vh UnityEngine.UI.VertexHelper
function m:ModifyMesh(vh) end
UnityEngine = {}
UnityEngine.UI = {}
UnityEngine.UI.Shadow = m
return m