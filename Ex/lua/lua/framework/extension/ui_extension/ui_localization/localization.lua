--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    游戏本地化
**********************************************************************************************
]]--------------------------------------------------------------------------------------------
--[[region LanguageType
---@class LanguageType
_enum("LanguageType", {
    ChineseSimplified = 1,
})
--endregion


---@class Localization:Singleton
_class("Localization", Singleton)
Localization=Localization


function Localization:Constructor()
    self.curLanguage = LanguageType.ChineseSimplified
    ---@type table<int,Callback>
    self.onLocalizes = {}
end

---@overload fun():LanguageType
---@param value LanguageType
function Localization:CurLanguage(value)
    if value then
        if self.curLanguage ~= value then
            self.curLanguage = value
            if self.onLocalizes then
                for k, v in pairs(self.onLocalizes) do
                    v:Call()
                end
            end
        end
    else
        return self.curLanguage
    end
end
function Localization:AddCallback(uiLocalizationText)
    if self.onLocalizes then
        local callback = GameHelper:GetInstance():CreateCallback(uiLocalizationText.OnLocalize, uiLocalizationText)
        self.onLocalizes[uiLocalizationText.gameObject:GetInstanceID()] = callback
    end
end
function Localization:RemoveCallback(uiLocalizationText)
    if self.onLocalizes then
        local id = uiLocalizationText.gameObject:GetInstanceID()
        self.onLocalizes[id] = nil
    end
end]]