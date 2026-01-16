---@class UICircleMaskLoader : UnityEngine.MonoBehaviour
---@field MainTexture string
---@field targetImage UnityEngine.UI.RawImage
---@field softFactor float
local m = {}
---@param _name string
function m:LoadImage(_name) end
function m:InitImage() end
---@param _mainTex string
function m:Load(_mainTex) end
function m:DestoryLastImage() end
UICircleMaskLoader = m
return m