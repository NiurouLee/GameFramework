---@class UnityEngine.UI.ToggleGroup : UnityEngine.EventSystems.UIBehaviour
---@field allowSwitchOff bool
local m = {}
---@param toggle UnityEngine.UI.Toggle
function m:NotifyToggleOn(toggle) end
---@param toggle UnityEngine.UI.Toggle
function m:UnregisterToggle(toggle) end
---@param toggle UnityEngine.UI.Toggle
function m:RegisterToggle(toggle) end
---@return bool
function m:AnyTogglesOn() end
---@return System.Collections.Generic.IEnumerable
function m:ActiveToggles() end
function m:SetAllTogglesOff() end
UnityEngine = {}
UnityEngine.UI = {}
UnityEngine.UI.ToggleGroup = m
return m