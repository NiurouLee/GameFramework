---@class INTL.LevelInfinite.LevelInfinite
---@field Version string
---@field DefaultActivityKey string
local m = {}
---@param host string
---@param userData intlgn.INTLUserData
---@param fonts table
---@param isTest bool
function m.Init(host, userData, fonts, isTest) end
---@param lang string
function m.SetLanguage(lang) end
---@param root UnityEngine.GameObject
function m.SetUIRoot(root) end
function m.Close() end
---@param eventName string
---@param json string
function m.OnGameNativeEvent(eventName, json) end
function m.OpenLoginPanel() end
function m.OpenAccountCenter() end
function m.AutoLogin() end
---@param event_id string
function m.QueryBindRewardStatus(event_id) end
---@param event_id string
---@param extraJson string
function m.SendBindReward(event_id, extraJson) end
---@param liEvent INTL.LevelInfinite.LevelInfiniteEvent.OnLIEventResultHandler
function m.AddLIEventObserver(liEvent) end
---@param liEvent INTL.LevelInfinite.LevelInfiniteEvent.OnLIEventResultHandler
function m.RemoveLIEventObserver(liEvent) end
INTL = {}
INTL.LevelInfinite = {}
INTL.LevelInfinite.LevelInfinite = m
return m