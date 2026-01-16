--[[
    快速设置 Style 辅助类
]]
---@class UIStyleHelper:Object
_class("UIStyleHelper", Object)
UIStyleHelper = UIStyleHelper

--region Text

function UIStyleHelper.FitStyle_RichText(styleInfo, text)
    if styleInfo then
        return UIActivityHelper.GetRichText(styleInfo, text)
    end
    return text
end

-- 设置 a/b 格式文字，a > b 时 a 为红色
function UIStyleHelper.ChangeColorStr_Style(styleColor, colorNormal, colorRed, change, a, b)
    local normal = styleColor or colorNormal
    local red = colorRed

    local c = change and red or normal
    local str = UIActivityHelper.GetColorText(c, a, normal, "/" .. b)
    return str
end

--endregion

function UIStyleHelper.FitStyle_Widget(styleInfo, uiView, widgetName)
    if styleInfo then
        local uiName = uiView and uiView:GetName() or ""
        Log.debug("UIStyleHelper.FitStyle_Widget() uiView = ", uiName, " widgetName = " .. widgetName)

        -- Active
        UIStyleHelper.FitStyle_Widget_Active(styleInfo, uiView, widgetName)

        -- Image
        UIStyleHelper.FitStyle_Widget_Image(styleInfo, uiView, widgetName)

        -- RawImage
        UIStyleHelper.FitStyle_Widget_RawImage(styleInfo, uiView, widgetName)

        -- LocalizationText Color
        UIStyleHelper.FitStyle_Widget_LocalizationText(styleInfo, uiView, widgetName)
    end
end

function UIStyleHelper.FitStyle_Widget_Active(styleInfo, uiView, widgetName)
    local active = styleInfo.active
    if active ~= nil then
        uiView:GetGameObject(widgetName):SetActive(active)
    end
end

function UIStyleHelper.FitStyle_Widget_Image(styleInfo, uiView, widgetName)
    local atlasName, spriteName = styleInfo.atlasName, styleInfo.spriteName
    if atlasName and spriteName then
        UIWidgetHelper.SetImageSprite(uiView, widgetName, atlasName, spriteName)
    end
end

function UIStyleHelper.FitStyle_Widget_RawImage(styleInfo, uiView, widgetName)
    local rawImageName = styleInfo.rawImageName
    if rawImageName then
        UIWidgetHelper.SetRawImage(uiView, widgetName, rawImageName)
    end
end

function UIStyleHelper.FitStyle_Widget_LocalizationText(styleInfo, uiView, widgetName)
    local color = styleInfo.color
    if color then
        local obj = uiView:GetUIComponent("UILocalizationText", widgetName)
        local c = UIStyleHelper._GetColorByHex(color)
        obj.color = c
    end
end

-- #FFFFFF 格式转换为 Color
function UIStyleHelper._GetColorByHex(text)
    local tb = {}
    for i = 2, 8, 2 do
        local j = i + 1
        local str = (#text >= j) and string.sub(text, i, j) or "FF"
        local num = tonumber(string.format("%d", "0x" .. str))
        table.insert(tb, num)
    end
    local r, g, b, a = tb[1], tb[2], tb[3], tb[4]
    return Color(r / 255, g / 255, b / 255, a / 255)
end
