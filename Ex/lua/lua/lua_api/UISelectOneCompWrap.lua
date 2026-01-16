---@class UISelectOneComp : UnityEngine.MonoBehaviour
---@field selectItems table
---@field selectIndex int
---@field onSeletItemTriggerHandler UISelectItem.OnSelectItemTriggerHandler
local m = {}
---@param itemIndex int
function m:SelectHandler(itemIndex) end
function m:Reset() end
UISelectOneComp = m
return m