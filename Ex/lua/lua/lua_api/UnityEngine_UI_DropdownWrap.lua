---@class UnityEngine.UI.Dropdown : UnityEngine.UI.Selectable
---@field template UnityEngine.RectTransform
---@field captionText UnityEngine.UI.Text
---@field captionImage UnityEngine.UI.Image
---@field itemText UnityEngine.UI.Text
---@field itemImage UnityEngine.UI.Image
---@field options table
---@field onValueChanged UnityEngine.UI.Dropdown.DropdownEvent
---@field value int
local m = {}
function m:RefreshShownValue() end
---@overload fun(options:table):void
---@overload fun(options:table):void
---@param options table
function m:AddOptions(options) end
function m:ClearOptions() end
---@param eventData UnityEngine.EventSystems.PointerEventData
function m:OnPointerClick(eventData) end
---@param eventData UnityEngine.EventSystems.BaseEventData
function m:OnSubmit(eventData) end
---@param eventData UnityEngine.EventSystems.BaseEventData
function m:OnCancel(eventData) end
function m:Show() end
function m:Hide() end
UnityEngine = {}
UnityEngine.UI = {}
UnityEngine.UI.Dropdown = m
return m