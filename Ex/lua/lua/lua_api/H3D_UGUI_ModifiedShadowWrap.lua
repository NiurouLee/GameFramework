---@class H3D.UGUI.ModifiedShadow : UnityEngine.UI.Shadow
local m = {}
---@param vh UnityEngine.UI.VertexHelper
function m:ModifyMesh(vh) end
---@param verts table
function m:ModifyVertices(verts) end
H3D = {}
H3D.UGUI = {}
H3D.UGUI.ModifiedShadow = m
return m