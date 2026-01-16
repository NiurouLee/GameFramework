---@class UnityEngine.Canvas : UnityEngine.Behaviour
---@field renderMode UnityEngine.RenderMode
---@field isRootCanvas bool
---@field pixelRect UnityEngine.Rect
---@field scaleFactor float
---@field referencePixelsPerUnit float
---@field overridePixelPerfect bool
---@field pixelPerfect bool
---@field planeDistance float
---@field renderOrder int
---@field overrideSorting bool
---@field sortingOrder int
---@field targetDisplay int
---@field sortingLayerID int
---@field cachedSortingLayerValue int
---@field additionalShaderChannels UnityEngine.AdditionalCanvasShaderChannels
---@field sortingLayerName string
---@field rootCanvas UnityEngine.Canvas
---@field worldCamera UnityEngine.Camera
---@field normalizedSortingGridSize float
local m = {}
---@return UnityEngine.Material
function m.GetDefaultCanvasMaterial() end
---@return UnityEngine.Material
function m.GetETC1SupportedCanvasMaterial() end
function m.ForceUpdateCanvases() end
UnityEngine = {}
UnityEngine.Canvas = m
return m