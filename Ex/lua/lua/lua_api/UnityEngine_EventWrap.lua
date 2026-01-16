---@class UnityEngine.Event : object
---@field rawType UnityEngine.EventType
---@field mousePosition UnityEngine.Vector2
---@field delta UnityEngine.Vector2
---@field button int
---@field modifiers UnityEngine.EventModifiers
---@field pressure float
---@field clickCount int
---@field character char
---@field keyCode UnityEngine.KeyCode
---@field displayIndex int
---@field type UnityEngine.EventType
---@field commandName string
---@field shift bool
---@field control bool
---@field alt bool
---@field command bool
---@field capsLock bool
---@field numeric bool
---@field functionKey bool
---@field current UnityEngine.Event
---@field isKey bool
---@field isMouse bool
---@field isScrollWheel bool
local m = {}
---@param controlID int
---@return UnityEngine.EventType
function m:GetTypeForControl(controlID) end
---@param outEvent UnityEngine.Event
---@return bool
function m.PopEvent(outEvent) end
---@return int
function m.GetEventCount() end
---@param key string
---@return UnityEngine.Event
function m.KeyboardEvent(key) end
---@return int
function m:GetHashCode() end
---@param obj object
---@return bool
function m:Equals(obj) end
---@return string
function m:ToString() end
function m:Use() end
UnityEngine = {}
UnityEngine.Event = m
return m