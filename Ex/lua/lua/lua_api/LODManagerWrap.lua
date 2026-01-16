---@class LODManager : MSingleton
---@field performanceScore float
---@field setting LODSetting
---@field performaceTestTime float
---@field defualtScreenWidth int
---@field defualtScreenHeight int
---@field ResolutionChanged bool
local m = {}
function m:SetResolution() end
---@param controller LODController
function m.Regist(controller) end
---@param controller LODController
function m.UnRegist(controller) end
---@param level int
function m:SetLODLevel(level) end
---@return int
function m:GetLODLevel() end
function m:SetGraphicLevel() end
LODManager = m
return m