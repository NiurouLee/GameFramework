---@class OutlineBlurLoader : UnityEngine.MonoBehaviour
---@field cgShowType OutlineBlurLoader.CGShowType
---@field MainTexture string
---@field BlurTexture string
---@field PureColorTexture string
---@field targetImage UnityEngine.UI.RawImage
---@field shadowImage UnityEngine.UI.RawImage
---@field shadowOffset UnityEngine.Vector2
local m = {}
---@overload fun(_mainTex:string, _blurlayTex:string):void
---@param _name string
function m:Load(_name) end
OutlineBlurLoader = m
return m