---@class PassEventComponent : UnityEngine.MonoBehaviour
local m = {}
---@param action System.Action
function m:SetClickCallback(action) end
---@param checkScrollIdx int
---@param checkClickIdx int
function m:SetCheckIdx(checkScrollIdx, checkClickIdx) end
---@param data UnityEngine.EventSystems.PointerEventData
---@param type int
function m:PassEvent(data, type) end
---@param eventData UnityEngine.EventSystems.PointerEventData
function m:OnPointerClick(eventData) end
PassEventComponent = m
return m