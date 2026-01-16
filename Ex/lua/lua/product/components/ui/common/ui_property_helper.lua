---@class UIPropertyHelper:Singleton
---@field GetInstance UIPropertyHelper
_class("UIPropertyHelper", Singleton)
UIPropertyHelper = UIPropertyHelper

function UIPropertyHelper:Constructor()
    self.mapColorBlindSpriteName = {
        bing_color = "blind_bing_color",
        huo_color = "blind_huo_color",
        sen_color = "blind_sen_color",
        lei_color = "blind_lei_color",
        --
        bing_color_battle = "blind_bing_color_battle",
        huo_color_battle = "blind_huo_color_battle",
        sen_color_battle = "blind_sen_color_battle",
        lei_color_battle = "blind_lei_color_battle",
        --
        bing_color_team = "blind_bing_color_team",
        huo_color_team = "blind_huo_color_team",
        sen_color_team = "blind_sen_color_team",
        lei_color_team = "blind_lei_color_team"
    }
end

---获取属性精灵名，如果色盲模式开启就获取色盲模式的精灵名
---@return string
function UIPropertyHelper:GetColorBlindSprite(spriteName)
    local isColorBlind = self:GetColorBlindStyle() == 3 --是否色盲模式
    if isColorBlind then
        local nameColorBlind = self.mapColorBlindSpriteName[spriteName]
        if not string.isnullorempty(nameColorBlind) then
            return nameColorBlind
        end
    end
    return spriteName
end

function UIPropertyHelper:GetColorBlindStyle()
    local playerPrefsKey = self:GetColorBlindKey()
    local colorBlindCode = UnityEngine.PlayerPrefs.GetInt(playerPrefsKey, 1) --1华丽（默认）2普通3色觉辅助
    return colorBlindCode
end
function UIPropertyHelper:SetColorBlindStyle(idx)
    local playerPrefsKey = self:GetColorBlindKey()
    local colorBlindCode = UnityEngine.PlayerPrefs.SetInt(playerPrefsKey, idx)
    return colorBlindCode
end
---@private
function UIPropertyHelper:GetColorBlindKey()
    local mRole = GameGlobal.GetModule(RoleModule)
    local pstId = mRole:GetPstId()
    local playerPrefsKey = pstId .. "ColorBlindStyle" --XXXXXXXXColorBlindStyle
    return playerPrefsKey
end
