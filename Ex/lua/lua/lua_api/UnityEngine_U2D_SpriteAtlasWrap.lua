---@class UnityEngine.U2D.SpriteAtlas : UnityEngine.Object
---@field isVariant bool
---@field tag string
---@field spriteCount int
local m = {}
---@param sprite UnityEngine.Sprite
---@return bool
function m:CanBindTo(sprite) end
---@param name string
---@return UnityEngine.Sprite
function m:GetSprite(name) end
---@overload fun(sprites:table, name:string):int
---@param sprites table
---@return int
function m:GetSprites(sprites) end
UnityEngine = {}
UnityEngine.U2D = {}
UnityEngine.U2D.SpriteAtlas = m
return m