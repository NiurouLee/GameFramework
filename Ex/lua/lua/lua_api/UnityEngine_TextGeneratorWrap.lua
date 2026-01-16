---@class UnityEngine.TextGenerator : object
---@field characterCountVisible int
---@field verts System.Collections.Generic.IList
---@field characters System.Collections.Generic.IList
---@field lines System.Collections.Generic.IList
---@field rectExtents UnityEngine.Rect
---@field vertexCount int
---@field characterCount int
---@field lineCount int
---@field fontSizeUsedForBestFit int
local m = {}
function m:Invalidate() end
---@param characters table
function m:GetCharacters(characters) end
---@param lines table
function m:GetLines(lines) end
---@param vertices table
function m:GetVertices(vertices) end
---@param str string
---@param settings UnityEngine.TextGenerationSettings
---@return float
function m:GetPreferredWidth(str, settings) end
---@param str string
---@param settings UnityEngine.TextGenerationSettings
---@return float
function m:GetPreferredHeight(str, settings) end
---@param str string
---@param settings UnityEngine.TextGenerationSettings
---@param context UnityEngine.GameObject
---@return bool
function m:PopulateWithErrors(str, settings, context) end
---@param str string
---@param settings UnityEngine.TextGenerationSettings
---@return bool
function m:Populate(str, settings) end
---@return table
function m:GetVerticesArray() end
---@return table
function m:GetCharactersArray() end
---@return table
function m:GetLinesArray() end
UnityEngine = {}
UnityEngine.TextGenerator = m
return m