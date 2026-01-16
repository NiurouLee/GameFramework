---@class UnityEngine.Matrix4x4
---@field rotation UnityEngine.Quaternion
---@field lossyScale UnityEngine.Vector3
---@field isIdentity bool
---@field determinant float
---@field decomposeProjection UnityEngine.FrustumPlanes
---@field inverse UnityEngine.Matrix4x4
---@field transpose UnityEngine.Matrix4x4
---@field Item float
---@field Item float
---@field zero UnityEngine.Matrix4x4
---@field identity UnityEngine.Matrix4x4
---@field m00 float
---@field m10 float
---@field m20 float
---@field m30 float
---@field m01 float
---@field m11 float
---@field m21 float
---@field m31 float
---@field m02 float
---@field m12 float
---@field m22 float
---@field m32 float
---@field m03 float
---@field m13 float
---@field m23 float
---@field m33 float
local m = {}
---@return bool
function m:ValidTRS() end
---@param m UnityEngine.Matrix4x4
---@return float
function m.Determinant(m) end
---@param pos UnityEngine.Vector3
---@param q UnityEngine.Quaternion
---@param s UnityEngine.Vector3
---@return UnityEngine.Matrix4x4
function m.TRS(pos, q, s) end
---@param pos UnityEngine.Vector3
---@param q UnityEngine.Quaternion
---@param s UnityEngine.Vector3
function m:SetTRS(pos, q, s) end
---@param m UnityEngine.Matrix4x4
---@return UnityEngine.Matrix4x4
function m.Inverse(m) end
---@param m UnityEngine.Matrix4x4
---@return UnityEngine.Matrix4x4
function m.Transpose(m) end
---@param left float
---@param right float
---@param bottom float
---@param top float
---@param zNear float
---@param zFar float
---@return UnityEngine.Matrix4x4
function m.Ortho(left, right, bottom, top, zNear, zFar) end
---@param fov float
---@param aspect float
---@param zNear float
---@param zFar float
---@return UnityEngine.Matrix4x4
function m.Perspective(fov, aspect, zNear, zFar) end
---@param from UnityEngine.Vector3
---@param to UnityEngine.Vector3
---@param up UnityEngine.Vector3
---@return UnityEngine.Matrix4x4
function m.LookAt(from, to, up) end
---@overload fun(fp:UnityEngine.FrustumPlanes):UnityEngine.Matrix4x4
---@param left float
---@param right float
---@param bottom float
---@param top float
---@param zNear float
---@param zFar float
---@return UnityEngine.Matrix4x4
function m.Frustum(left, right, bottom, top, zNear, zFar) end
---@return int
function m:GetHashCode() end
---@overload fun(other:UnityEngine.Matrix4x4):bool
---@param other object
---@return bool
function m:Equals(other) end
---@overload fun(lhs:UnityEngine.Matrix4x4, vector:UnityEngine.Vector4):UnityEngine.Vector4
---@param lhs UnityEngine.Matrix4x4
---@param rhs UnityEngine.Matrix4x4
---@return UnityEngine.Matrix4x4
function m.op_Multiply(lhs, rhs) end
---@param lhs UnityEngine.Matrix4x4
---@param rhs UnityEngine.Matrix4x4
---@return bool
function m.op_Equality(lhs, rhs) end
---@param lhs UnityEngine.Matrix4x4
---@param rhs UnityEngine.Matrix4x4
---@return bool
function m.op_Inequality(lhs, rhs) end
---@param index int
---@return UnityEngine.Vector4
function m:GetColumn(index) end
---@param index int
---@return UnityEngine.Vector4
function m:GetRow(index) end
---@param index int
---@param column UnityEngine.Vector4
function m:SetColumn(index, column) end
---@param index int
---@param row UnityEngine.Vector4
function m:SetRow(index, row) end
---@param point UnityEngine.Vector3
---@return UnityEngine.Vector3
function m:MultiplyPoint(point) end
---@param point UnityEngine.Vector3
---@return UnityEngine.Vector3
function m:MultiplyPoint3x4(point) end
---@param vector UnityEngine.Vector3
---@return UnityEngine.Vector3
function m:MultiplyVector(vector) end
---@param plane UnityEngine.Plane
---@return UnityEngine.Plane
function m:TransformPlane(plane) end
---@param vector UnityEngine.Vector3
---@return UnityEngine.Matrix4x4
function m.Scale(vector) end
---@param vector UnityEngine.Vector3
---@return UnityEngine.Matrix4x4
function m.Translate(vector) end
---@param q UnityEngine.Quaternion
---@return UnityEngine.Matrix4x4
function m.Rotate(q) end
---@overload fun(format:string):string
---@return string
function m:ToString() end
UnityEngine = {}
UnityEngine.Matrix4x4 = m
return m