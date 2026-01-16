---@class UnityEngine.Gizmos : object
---@field color UnityEngine.Color
---@field matrix UnityEngine.Matrix4x4
local m = {}
---@param from UnityEngine.Vector3
---@param to UnityEngine.Vector3
function m.DrawLine(from, to) end
---@param center UnityEngine.Vector3
---@param radius float
function m.DrawWireSphere(center, radius) end
---@param center UnityEngine.Vector3
---@param radius float
function m.DrawSphere(center, radius) end
---@param center UnityEngine.Vector3
---@param size UnityEngine.Vector3
function m.DrawWireCube(center, size) end
---@param center UnityEngine.Vector3
---@param size UnityEngine.Vector3
function m.DrawCube(center, size) end
---@overload fun(mesh:UnityEngine.Mesh, position:UnityEngine.Vector3, rotation:UnityEngine.Quaternion):void
---@overload fun(mesh:UnityEngine.Mesh, position:UnityEngine.Vector3):void
---@overload fun(mesh:UnityEngine.Mesh):void
---@overload fun(mesh:UnityEngine.Mesh, position:UnityEngine.Vector3, rotation:UnityEngine.Quaternion, scale:UnityEngine.Vector3):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, position:UnityEngine.Vector3, rotation:UnityEngine.Quaternion):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, position:UnityEngine.Vector3):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int):void
---@param mesh UnityEngine.Mesh
---@param submeshIndex int
---@param position UnityEngine.Vector3
---@param rotation UnityEngine.Quaternion
---@param scale UnityEngine.Vector3
function m.DrawMesh(mesh, submeshIndex, position, rotation, scale) end
---@overload fun(mesh:UnityEngine.Mesh, position:UnityEngine.Vector3, rotation:UnityEngine.Quaternion):void
---@overload fun(mesh:UnityEngine.Mesh, position:UnityEngine.Vector3):void
---@overload fun(mesh:UnityEngine.Mesh):void
---@overload fun(mesh:UnityEngine.Mesh, position:UnityEngine.Vector3, rotation:UnityEngine.Quaternion, scale:UnityEngine.Vector3):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, position:UnityEngine.Vector3, rotation:UnityEngine.Quaternion):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, position:UnityEngine.Vector3):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int):void
---@param mesh UnityEngine.Mesh
---@param submeshIndex int
---@param position UnityEngine.Vector3
---@param rotation UnityEngine.Quaternion
---@param scale UnityEngine.Vector3
function m.DrawWireMesh(mesh, submeshIndex, position, rotation, scale) end
---@overload fun(center:UnityEngine.Vector3, name:string):void
---@param center UnityEngine.Vector3
---@param name string
---@param allowScaling bool
function m.DrawIcon(center, name, allowScaling) end
---@overload fun(screenRect:UnityEngine.Rect, texture:UnityEngine.Texture):void
---@overload fun(screenRect:UnityEngine.Rect, texture:UnityEngine.Texture, mat:UnityEngine.Material):void
---@overload fun(screenRect:UnityEngine.Rect, texture:UnityEngine.Texture, leftBorder:int, rightBorder:int, topBorder:int, bottomBorder:int):void
---@param screenRect UnityEngine.Rect
---@param texture UnityEngine.Texture
---@param leftBorder int
---@param rightBorder int
---@param topBorder int
---@param bottomBorder int
---@param mat UnityEngine.Material
function m.DrawGUITexture(screenRect, texture, leftBorder, rightBorder, topBorder, bottomBorder, mat) end
---@param center UnityEngine.Vector3
---@param fov float
---@param maxRange float
---@param minRange float
---@param aspect float
function m.DrawFrustum(center, fov, maxRange, minRange, aspect) end
---@overload fun(from:UnityEngine.Vector3, direction:UnityEngine.Vector3):void
---@param r UnityEngine.Ray
function m.DrawRay(r) end
UnityEngine = {}
UnityEngine.Gizmos = m
return m