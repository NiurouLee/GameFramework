---@class UILongPressTriggerListener : UnityEngine.MonoBehaviour
---@field IsLongPress bool
---@field onClick UIEventTriggerListener.DelegateGameObject
---@field onLongPress UIEventTriggerListener.DelegateGameObject
---@field onLongPressEnd UIEventTriggerListener.DelegateGameObject
---@field onApplicationFocus H3dDelegate.DelegateBool
---@field _longPressThreshold float
local m = {}
---@param longPressThreshold float
function m:Init(longPressThreshold) end
---@param go UnityEngine.GameObject
---@return UILongPressTriggerListener
function m.Get(go) end
UILongPressTriggerListener = m
return m