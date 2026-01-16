---@class UnityEngine.EventSystems.EventSystem : UnityEngine.EventSystems.UIBehaviour
---@field current UnityEngine.EventSystems.EventSystem
---@field sendNavigationEvents bool
---@field pixelDragThreshold int
---@field currentInputModule UnityEngine.EventSystems.BaseInputModule
---@field firstSelectedGameObject UnityEngine.GameObject
---@field currentSelectedGameObject UnityEngine.GameObject
---@field isFocused bool
---@field alreadySelecting bool
local m = {}
function m:UpdateModules() end
---@overload fun(selected:UnityEngine.GameObject):void
---@param selected UnityEngine.GameObject
---@param pointer UnityEngine.EventSystems.BaseEventData
function m:SetSelectedGameObject(selected, pointer) end
---@param eventData UnityEngine.EventSystems.PointerEventData
---@param raycastResults table
function m:RaycastAll(eventData, raycastResults) end
---@overload fun(pointerId:int):bool
---@return bool
function m:IsPointerOverGameObject() end
---@return string
function m:ToString() end
UnityEngine = {}
UnityEngine.EventSystems = {}
UnityEngine.EventSystems.EventSystem = m
return m