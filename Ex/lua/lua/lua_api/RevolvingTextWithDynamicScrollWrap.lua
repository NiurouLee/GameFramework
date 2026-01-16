---@class RevolvingTextWithDynamicScroll : UnityEngine.MonoBehaviour
---@field RevolvingTarget UnityEngine.UI.Text
---@field Spacing float
---@field Speed float
---@field useMaxWidth bool
---@field maxWidth float
local m = {}
function m:OnRefreshRevolving() end
RevolvingTextWithDynamicScroll = m
return m