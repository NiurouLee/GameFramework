---@class UnityEngine.TextGenerationSettings
---@field font UnityEngine.Font
---@field color UnityEngine.Color
---@field fontSize int
---@field lineSpacing float
---@field richText bool
---@field scaleFactor float
---@field fontStyle UnityEngine.FontStyle
---@field textAnchor UnityEngine.TextAnchor
---@field alignByGeometry bool
---@field resizeTextForBestFit bool
---@field resizeTextMinSize int
---@field resizeTextMaxSize int
---@field updateBounds bool
---@field verticalOverflow UnityEngine.VerticalWrapMode
---@field horizontalOverflow UnityEngine.HorizontalWrapMode
---@field generationExtents UnityEngine.Vector2
---@field pivot UnityEngine.Vector2
---@field generateOutOfBounds bool
local m = {}
---@param other UnityEngine.TextGenerationSettings
---@return bool
function m:Equals(other) end
UnityEngine = {}
UnityEngine.TextGenerationSettings = m
return m