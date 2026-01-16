---@class UILinkSelectorTMP : UnityEngine.MonoBehaviour
local m = {}
---@param callback UILinkSelectorTMP.OnLinkSelect
function m:SetLinkSelectCallback(callback) end
---@param eventData UnityEngine.EventSystems.PointerEventData
function m:OnPointerClick(eventData) end
UILinkSelectorTMP = m
return m