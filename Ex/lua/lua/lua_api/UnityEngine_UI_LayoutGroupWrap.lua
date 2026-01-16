---@class UnityEngine.UI.LayoutGroup : UnityEngine.EventSystems.UIBehaviour
---@field padding UnityEngine.RectOffset
---@field childAlignment UnityEngine.TextAnchor
---@field minWidth float
---@field preferredWidth float
---@field flexibleWidth float
---@field minHeight float
---@field preferredHeight float
---@field flexibleHeight float
---@field layoutPriority int
local m = {}
function m:CalculateLayoutInputHorizontal() end
function m:CalculateLayoutInputVertical() end
function m:SetLayoutHorizontal() end
function m:SetLayoutVertical() end
UnityEngine = {}
UnityEngine.UI = {}
UnityEngine.UI.LayoutGroup = m
return m