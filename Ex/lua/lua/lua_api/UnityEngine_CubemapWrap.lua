---@class UnityEngine.Cubemap : UnityEngine.Texture
---@field mipmapCount int
---@field format UnityEngine.TextureFormat
---@field isReadable bool
local m = {}
---@overload fun():void
---@param smoothRegionWidthInPixels int
function m:SmoothEdges(smoothRegionWidthInPixels) end
---@overload fun(face:UnityEngine.CubemapFace):table
---@param face UnityEngine.CubemapFace
---@param miplevel int
---@return table
function m:GetPixels(face, miplevel) end
---@overload fun(colors:table, face:UnityEngine.CubemapFace):void
---@param colors table
---@param face UnityEngine.CubemapFace
---@param miplevel int
function m:SetPixels(colors, face, miplevel) end
---@param width int
---@param format UnityEngine.TextureFormat
---@param mipmap bool
---@param nativeTex System.IntPtr
---@return UnityEngine.Cubemap
function m.CreateExternalTexture(width, format, mipmap, nativeTex) end
---@param face UnityEngine.CubemapFace
---@param x int
---@param y int
---@param color UnityEngine.Color
function m:SetPixel(face, x, y, color) end
---@param face UnityEngine.CubemapFace
---@param x int
---@param y int
---@return UnityEngine.Color
function m:GetPixel(face, x, y) end
---@overload fun(updateMipmaps:bool):void
---@overload fun():void
---@param updateMipmaps bool
---@param makeNoLongerReadable bool
function m:Apply(updateMipmaps, makeNoLongerReadable) end
UnityEngine = {}
UnityEngine.Cubemap = m
return m