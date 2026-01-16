---@class UnityEngine.Rendering.RenderTargetIdentifier
local m = {}
---@overload fun(name:string):UnityEngine.Rendering.RenderTargetIdentifier
---@overload fun(nameID:int):UnityEngine.Rendering.RenderTargetIdentifier
---@overload fun(tex:UnityEngine.Texture):UnityEngine.Rendering.RenderTargetIdentifier
---@overload fun(buf:UnityEngine.RenderBuffer):UnityEngine.Rendering.RenderTargetIdentifier
---@param type UnityEngine.Rendering.BuiltinRenderTextureType
---@return UnityEngine.Rendering.RenderTargetIdentifier
function m.op_Implicit(type) end
---@return string
function m:ToString() end
---@return int
function m:GetHashCode() end
---@overload fun(obj:object):bool
---@param rhs UnityEngine.Rendering.RenderTargetIdentifier
---@return bool
function m:Equals(rhs) end
---@param lhs UnityEngine.Rendering.RenderTargetIdentifier
---@param rhs UnityEngine.Rendering.RenderTargetIdentifier
---@return bool
function m.op_Equality(lhs, rhs) end
---@param lhs UnityEngine.Rendering.RenderTargetIdentifier
---@param rhs UnityEngine.Rendering.RenderTargetIdentifier
---@return bool
function m.op_Inequality(lhs, rhs) end
UnityEngine = {}
UnityEngine.Rendering = {}
UnityEngine.Rendering.RenderTargetIdentifier = m
return m