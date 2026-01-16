---@class UIEventTriggerListener : UnityEngine.MonoBehaviour
---@field IsPressd bool
---@field IsDragging bool
---@field CurrentPointerEventData UnityEngine.EventSystems.PointerEventData
---@field onClick UIEventTriggerListener.DelegateGameObject
---@field onDoubleClick UIEventTriggerListener.DelegateGameObject
---@field onDown UIEventTriggerListener.DelegateGameObject
---@field onEnter UIEventTriggerListener.DelegateGameObject
---@field onExit UIEventTriggerListener.DelegateGameObject
---@field onUp UIEventTriggerListener.DelegateGameObject
---@field onSelect UIEventTriggerListener.DelegateGameObject
---@field onUpdateSelect UIEventTriggerListener.DelegateGameObject
---@field onBeginDrag UIEventTriggerListener.PointerEventDataDelegate
---@field onDrag UIEventTriggerListener.PointerEventDataDelegate
---@field onEndDrag UIEventTriggerListener.PointerEventDataDelegate
---@field onScroll UIEventTriggerListener.PointerEventDataDelegate
---@field onApplicationFocus H3dDelegate.DelegateBool
local m = {}
---@param go UnityEngine.GameObject
---@return UIEventTriggerListener
function m.Get(go) end
UIEventTriggerListener = m
return m