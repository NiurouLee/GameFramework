---@class UILocalizationText : UnityEngine.UI.Text
---@field m_LocalizedFontList table
---@field m_LocalizedSizeList table
---@field m_LocalizedTowardsList table
---@field m_LimitWidth bool
---@field m_MaxWidth int
local m = {}
---@param fontName string
function m:SwitchFont(fontName) end
---@param strText string
function m:SetText(strText) end
UILocalizationText = m
return m