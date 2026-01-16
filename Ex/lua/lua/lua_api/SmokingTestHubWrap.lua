---@class SmokingTestHub
---@field BoardLogPath string
---@field FullLogPath string
---@field StartupArgumentFilePath string
---@field StartupArgument string
local m = {}
---@return string
function m.GenerateFullLogPath() end
---@param msg string
function m.WriteBoardLog(msg) end
---@param msg string
function m.WriteFullLog(msg) end
---@return string
function m.LoadArgumentFromFile() end
---@param filepath string
function m.OpenLogFile(filepath) end
---@return bool
function m.IsCNVersion() end
SmokingTestHub = m
return m