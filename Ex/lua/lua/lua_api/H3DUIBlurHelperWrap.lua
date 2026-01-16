---@class H3DUIBlurHelper : UnityEngine.MonoBehaviour
---@field width int
---@field height int
---@field blurTimes int
---@field OwnerCamera UnityEngine.Camera
---@field UseAllCamerasCapture bool
---@field UseOwnerCamera bool
local m = {}
---@return UnityEngine.RenderTexture
function m:RefreshBlurTexture() end
---@param w int
---@param h int
---@param b int
---@return UnityEngine.RenderTexture
function m:BlurTexture(w, h, b) end
function m:CleanRenderTexture() end
function m:OnEnable() end
H3DUIBlurHelper = m
return m