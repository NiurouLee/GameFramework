---@class WorkWXPoster : object
---@field MessagePrefix string
---@field BotGUID string
---@field IsActive bool
---@field IsEnabled bool
---@field IsPauseOnError bool
---@field CurrenErrorCount int
---@field MaxErrorCount int
---@field DefaultMessageColor string
---@field ErrorMessageColor string
---@field InfoMessageColor string
local m = {}
---@param str string
---@param color string
function m.SendWorkWXMessage(str, color) end
---@param str string
function m.SendError(str) end
---@param str string
function m.SendInfo(str) end
---@param str string
function m.SendWorkWXMarkDown(str) end
---@param guid string
function m.ChangeBotGUID(guid) end
WorkWXPoster = m
return m