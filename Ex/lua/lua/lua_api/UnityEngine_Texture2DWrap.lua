---@class UnityEngine.Texture2D : UnityEngine.Texture
---@field mipmapCount int
---@field format UnityEngine.TextureFormat
---@field whiteTexture UnityEngine.Texture2D
---@field blackTexture UnityEngine.Texture2D
---@field isReadable bool
---@field streamingMipmaps bool
---@field streamingMipmapsPriority int
---@field requestedMipmapLevel int
---@field desiredMipmapLevel int
---@field loadingMipmapLevel int
---@field loadedMipmapLevel int
local m = {}
---@param highQuality bool
function m:Compress(highQuality) end
function m:ClearRequestedMipmapLevel() end
---@return bool
function m:IsRequestedMipmapLevelLoaded() end
---@param nativeTex System.IntPtr
function m:UpdateExternalTexture(nativeTex) end
---@return table
function m:GetRawTextureData() end
---@overload fun(x:int, y:int, blockWidth:int, blockHeight:int):table
---@overload fun(miplevel:int):table
---@overload fun():table
---@param x int
---@param y int
---@param blockWidth int
---@param blockHeight int
---@param miplevel int
---@return table
function m:GetPixels(x, y, blockWidth, blockHeight, miplevel) end
---@overload fun():table
---@param miplevel int
---@return table
function m:GetPixels32(miplevel) end
---@overload fun(textures:table, padding:int, maximumAtlasSize:int):table
---@overload fun(textures:table, padding:int):table
---@param textures table
---@param padding int
---@param maximumAtlasSize int
---@param makeNoLongerReadable bool
---@return table
function m:PackTextures(textures, padding, maximumAtlasSize, makeNoLongerReadable) end
---@param width int
---@param height int
---@param format UnityEngine.TextureFormat
---@param mipChain bool
---@param linear bool
---@param nativeTex System.IntPtr
---@return UnityEngine.Texture2D
function m.CreateExternalTexture(width, height, format, mipChain, linear, nativeTex) end
---@param x int
---@param y int
---@param color UnityEngine.Color
function m:SetPixel(x, y, color) end
---@overload fun(x:int, y:int, blockWidth:int, blockHeight:int, colors:table):void
---@overload fun(colors:table, miplevel:int):void
---@overload fun(colors:table):void
---@param x int
---@param y int
---@param blockWidth int
---@param blockHeight int
---@param colors table
---@param miplevel int
function m:SetPixels(x, y, blockWidth, blockHeight, colors, miplevel) end
---@param x int
---@param y int
---@return UnityEngine.Color
function m:GetPixel(x, y) end
---@param x float
---@param y float
---@return UnityEngine.Color
function m:GetPixelBilinear(x, y) end
---@overload fun(data:table):void
---@param data System.IntPtr
---@param size int
function m:LoadRawTextureData(data, size) end
---@overload fun(updateMipmaps:bool):void
---@overload fun():void
---@param updateMipmaps bool
---@param makeNoLongerReadable bool
function m:Apply(updateMipmaps, makeNoLongerReadable) end
---@overload fun(width:int, height:int, format:UnityEngine.TextureFormat, hasMipMap:bool):bool
---@param width int
---@param height int
---@return bool
function m:Resize(width, height) end
---@overload fun(source:UnityEngine.Rect, destX:int, destY:int):void
---@param source UnityEngine.Rect
---@param destX int
---@param destY int
---@param recalculateMipMaps bool
function m:ReadPixels(source, destX, destY, recalculateMipMaps) end
---@param sizes table
---@param padding int
---@param atlasSize int
---@param results table
---@return bool
function m.GenerateAtlas(sizes, padding, atlasSize, results) end
---@overload fun(colors:table):void
---@overload fun(x:int, y:int, blockWidth:int, blockHeight:int, colors:table, miplevel:int):void
---@overload fun(x:int, y:int, blockWidth:int, blockHeight:int, colors:table):void
---@param colors table
---@param miplevel int
function m:SetPixels32(colors, miplevel) end
UnityEngine = {}
UnityEngine.Texture2D = m
return m