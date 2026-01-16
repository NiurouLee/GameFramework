---@class UISelectItem : UnityEngine.MonoBehaviour
---@field state UISelectItem.State
---@field itemIndex int
---@field selectItemHandler UISelectItem.OnSelectItemTriggerHandler
---@field onStateChange UISelectItem.OnStateChange
---@field disableWhenSelected bool
---@field disableWhenDisable bool
---@field isColliderItem bool
local m = {}
---@param eventData UnityEngine.EventSystems.PointerEventData
function m:OnPointerClick(eventData) end
UISelectItem = m
return m