---@class TLayerOrderComponent : UnityEngine.MonoBehaviour
---@field sortingLayerID int
---@field sortedData table
local m = {}
---@param name string
function m:SetSortLayer(name) end
---@return string
function m:GetSortLayerName() end
function m:InitLayerOrderData() end
function m:Sorted() end
function m:TLayerOrderManagerClearAll() end
TLayerOrderComponent = m
return m