---@class UnityEngine.CanvasRenderer : UnityEngine.Component
---@field hasPopInstruction bool
---@field materialCount int
---@field popMaterialCount int
---@field absoluteDepth int
---@field hasMoved bool
---@field cullTransparentMesh bool
---@field hasRectClipping bool
---@field relativeDepth int
---@field cull bool
local m = {}
---@param color UnityEngine.Color
function m:SetColor(color) end
---@return UnityEngine.Color
function m:GetColor() end
---@param rect UnityEngine.Rect
function m:EnableRectClipping(rect) end
function m:DisableRectClipping() end
---@overload fun(material:UnityEngine.Material, texture:UnityEngine.Texture):void
---@param material UnityEngine.Material
---@param index int
function m:SetMaterial(material, index) end
---@overload fun():UnityEngine.Material
---@param index int
---@return UnityEngine.Material
function m:GetMaterial(index) end
---@param material UnityEngine.Material
---@param index int
function m:SetPopMaterial(material, index) end
---@param index int
---@return UnityEngine.Material
function m:GetPopMaterial(index) end
---@param texture UnityEngine.Texture
function m:SetTexture(texture) end
---@param texture UnityEngine.Texture
function m:SetAlphaTexture(texture) end
---@param mesh UnityEngine.Mesh
function m:SetMesh(mesh) end
function m:Clear() end
---@return float
function m:GetAlpha() end
---@param alpha float
function m:SetAlpha(alpha) end
---@return float
function m:GetInheritedAlpha() end
---@overload fun(verts:table, positions:table, colors:table, uv0S:table, uv1S:table, uv2S:table, uv3S:table, normals:table, tangents:table, indices:table):void
---@param verts table
---@param positions table
---@param colors table
---@param uv0S table
---@param uv1S table
---@param normals table
---@param tangents table
---@param indices table
function m.SplitUIVertexStreams(verts, positions, colors, uv0S, uv1S, normals, tangents, indices) end
---@overload fun(verts:table, positions:table, colors:table, uv0S:table, uv1S:table, uv2S:table, uv3S:table, normals:table, tangents:table, indices:table):void
---@param verts table
---@param positions table
---@param colors table
---@param uv0S table
---@param uv1S table
---@param normals table
---@param tangents table
---@param indices table
function m.CreateUIVertexStream(verts, positions, colors, uv0S, uv1S, normals, tangents, indices) end
---@overload fun(verts:table, positions:table, colors:table, uv0S:table, uv1S:table, uv2S:table, uv3S:table, normals:table, tangents:table):void
---@param verts table
---@param positions table
---@param colors table
---@param uv0S table
---@param uv1S table
---@param normals table
---@param tangents table
function m.AddUIVertexStream(verts, positions, colors, uv0S, uv1S, normals, tangents) end
UnityEngine = {}
UnityEngine.CanvasRenderer = m
return m