---@class UnityEngine.MaterialPropertyBlock : object
---@field isEmpty bool
local m = {}
function m:Clear() end
---@overload fun(nameID:int, value:float):void
---@param name string
---@param value float
function m:SetFloat(name, value) end
---@overload fun(nameID:int, value:int):void
---@param name string
---@param value int
function m:SetInt(name, value) end
---@overload fun(nameID:int, value:UnityEngine.Vector4):void
---@param name string
---@param value UnityEngine.Vector4
function m:SetVector(name, value) end
---@overload fun(nameID:int, value:UnityEngine.Color):void
---@param name string
---@param value UnityEngine.Color
function m:SetColor(name, value) end
---@overload fun(nameID:int, value:UnityEngine.Matrix4x4):void
---@param name string
---@param value UnityEngine.Matrix4x4
function m:SetMatrix(name, value) end
---@overload fun(nameID:int, value:UnityEngine.ComputeBuffer):void
---@param name string
---@param value UnityEngine.ComputeBuffer
function m:SetBuffer(name, value) end
---@overload fun(nameID:int, value:UnityEngine.Texture):void
---@param name string
---@param value UnityEngine.Texture
function m:SetTexture(name, value) end
---@overload fun(nameID:int, values:table):void
---@overload fun(name:string, values:table):void
---@overload fun(nameID:int, values:table):void
---@param name string
---@param values table
function m:SetFloatArray(name, values) end
---@overload fun(nameID:int, values:table):void
---@overload fun(name:string, values:table):void
---@overload fun(nameID:int, values:table):void
---@param name string
---@param values table
function m:SetVectorArray(name, values) end
---@overload fun(nameID:int, values:table):void
---@overload fun(name:string, values:table):void
---@overload fun(nameID:int, values:table):void
---@param name string
---@param values table
function m:SetMatrixArray(name, values) end
---@overload fun(nameID:int):float
---@param name string
---@return float
function m:GetFloat(name) end
---@overload fun(nameID:int):int
---@param name string
---@return int
function m:GetInt(name) end
---@overload fun(nameID:int):UnityEngine.Vector4
---@param name string
---@return UnityEngine.Vector4
function m:GetVector(name) end
---@overload fun(nameID:int):UnityEngine.Color
---@param name string
---@return UnityEngine.Color
function m:GetColor(name) end
---@overload fun(nameID:int):UnityEngine.Matrix4x4
---@param name string
---@return UnityEngine.Matrix4x4
function m:GetMatrix(name) end
---@overload fun(nameID:int):UnityEngine.Texture
---@param name string
---@return UnityEngine.Texture
function m:GetTexture(name) end
---@overload fun(nameID:int):table
---@overload fun(name:string, values:table):void
---@overload fun(nameID:int, values:table):void
---@param name string
---@return table
function m:GetFloatArray(name) end
---@overload fun(nameID:int):table
---@overload fun(name:string, values:table):void
---@overload fun(nameID:int, values:table):void
---@param name string
---@return table
function m:GetVectorArray(name) end
---@overload fun(nameID:int):table
---@overload fun(name:string, values:table):void
---@overload fun(nameID:int, values:table):void
---@param name string
---@return table
function m:GetMatrixArray(name) end
---@overload fun(lightProbes:table):void
---@overload fun(lightProbes:table, sourceStart:int, destStart:int, count:int):void
---@overload fun(lightProbes:table, sourceStart:int, destStart:int, count:int):void
---@param lightProbes table
function m:CopySHCoefficientArraysFrom(lightProbes) end
---@overload fun(occlusionProbes:table):void
---@overload fun(occlusionProbes:table, sourceStart:int, destStart:int, count:int):void
---@overload fun(occlusionProbes:table, sourceStart:int, destStart:int, count:int):void
---@param occlusionProbes table
function m:CopyProbeOcclusionArrayFrom(occlusionProbes) end
UnityEngine = {}
UnityEngine.MaterialPropertyBlock = m
return m