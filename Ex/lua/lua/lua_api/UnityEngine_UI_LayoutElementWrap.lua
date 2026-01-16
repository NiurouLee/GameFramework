---@class UnityEngine.UI.LayoutElement : UnityEngine.EventSystems.UIBehaviour
---@field ignoreLayout bool
---@field minWidth float
---@field minHeight float
---@field preferredWidth float
---@field preferredHeight float
---@field flexibleWidth float
---@field flexibleHeight float
---@field layoutPriority int
local m = {}
---@param endValue UnityEngine.Vector2
---@param duration float
---@param snapping bool
---@return DG.Tweening.Tweener
function m:DOFlexibleSize(endValue, duration, snapping) end
---@param endValue UnityEngine.Vector2
---@param duration float
---@param snapping bool
---@return DG.Tweening.Tweener
function m:DOMinSize(endValue, duration, snapping) end
---@param endValue UnityEngine.Vector2
---@param duration float
---@param snapping bool
---@return DG.Tweening.Tweener
function m:DOPreferredSize(endValue, duration, snapping) end
function m:CalculateLayoutInputHorizontal() end
function m:CalculateLayoutInputVertical() end
UnityEngine = {}
UnityEngine.UI = {}
UnityEngine.UI.LayoutElement = m
return m