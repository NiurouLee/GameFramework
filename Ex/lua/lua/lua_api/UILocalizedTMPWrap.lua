---@class UILocalizedTMP : TMPro.TextMeshProUGUI
---@field onHrefClick UILocalizedTMP.HrefDelegate
local m = {}
---@param strText string
function m:SetText(strText) end
---@param eventData UnityEngine.EventSystems.PointerEventData
function m:OnPointerClick(eventData) end
UILocalizedTMP = m
return m