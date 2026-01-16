---@class Localization : object
local m = {}
---@param bstring bool
---@return string
function m.GetCurLanguage(bstring) end
---@param language string
function m.SetLocalLanguage(language) end
---@return table
function m.GetLanguages() end
---@param curLangStr string
---@param langStrList table
---@return byte
function m.Convert2LangID(curLangStr, langStrList) end
Localization = m
return m