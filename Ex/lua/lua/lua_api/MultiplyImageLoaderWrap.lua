---@class MultiplyImageLoader : UnityEngine.MonoBehaviour
---@field MainTexture string
---@field OverlayTexture string
---@field targetImage UnityEngine.UI.RawImage
---@field shadowImage UnityEngine.UI.RawImage
---@field shadowOffset UnityEngine.Vector2
local m = {}
---@overload fun(_mainTex:string, _overlayTex:string):void
---@param _name string
function m:Load(_name) end
function m:SetAsNormal() end
function m:DestoryLastImage() end
MultiplyImageLoader = m
return m