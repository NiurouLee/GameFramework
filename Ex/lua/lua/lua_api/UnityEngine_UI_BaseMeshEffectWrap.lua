---@class UnityEngine.UI.BaseMeshEffect : UnityEngine.EventSystems.UIBehaviour
local m = {}
---@overload fun(vh:UnityEngine.UI.VertexHelper):void
---@param mesh UnityEngine.Mesh
function m:ModifyMesh(mesh) end
UnityEngine = {}
UnityEngine.UI = {}
UnityEngine.UI.BaseMeshEffect = m
return m