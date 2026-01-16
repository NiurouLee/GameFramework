---@class UnityEngine.UI.GridLayoutGroup : UnityEngine.UI.LayoutGroup
---@field startCorner UnityEngine.UI.GridLayoutGroup.Corner
---@field startAxis UnityEngine.UI.GridLayoutGroup.Axis
---@field cellSize UnityEngine.Vector2
---@field spacing UnityEngine.Vector2
---@field constraint UnityEngine.UI.GridLayoutGroup.Constraint
---@field constraintCount int
local m = {}
function m:CalculateLayoutInputHorizontal() end
function m:CalculateLayoutInputVertical() end
function m:SetLayoutHorizontal() end
function m:SetLayoutVertical() end
UnityEngine = {}
UnityEngine.UI = {}
UnityEngine.UI.GridLayoutGroup = m
return m