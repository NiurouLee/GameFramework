---@class UIResolutionHelper : object
local m = {}
---@return UnityEngine.RectTransform
function m:GetRTOfLeftBlackImage() end
---@return UnityEngine.RectTransform
function m:GetRTOfRightBlackImage() end
---@return UnityEngine.RectTransform
function m:GetRTOfTopBlackImage() end
---@return UnityEngine.RectTransform
function m:GetRTOfBottomBlackImage() end
---@param visible bool
function m:SetBlackSideVisible(visible) end
function m:Dispose() end
UIResolutionHelper = m
return m