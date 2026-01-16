---@class RollingText : UnityEngine.UI.BaseMeshEffect
---@field Speed int
---@field Space int
local m = {}
---@param content string
function m:RefreshText(content) end
---@param vh UnityEngine.UI.VertexHelper
function m:ModifyMesh(vh) end
RollingText = m
return m