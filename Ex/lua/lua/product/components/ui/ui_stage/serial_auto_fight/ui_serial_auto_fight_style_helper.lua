--[[
    快速设置 Style 辅助类
]]
---@class UISerialAutoFightStyleHelper:Object
_class("UISerialAutoFightStyleHelper", Object)
UISerialAutoFightStyleHelper = UISerialAutoFightStyleHelper

function UISerialAutoFightStyleHelper.GetStyleInfo(name, key)
    if string.isnullorempty(name) or string.isnullorempty(key) then
        return
    end

    local style = {}

    --------------------------------------------------------------------------------
    local dark = {
        bg_di01 = {
            rawImageName = "fight_saodang_di02"
        },
        bg_di04 = {
            rawImageName = "fight_saodang_di06"
        },
        bg_di05 = {
            rawImageName = "fight_saodang_di07"
        },
        line01 = {
            atlasName = "UIAutoFightSweep.spriteatlas",
            spriteName = "fight_saodang_line02"
        },
        line03 = {
            atlasName = "UIAutoFightSweep.spriteatlas",
            spriteName = "fight_saodang_line04"
        },
        kuang01 = {
            atlasName = "UIAutoFightSweep.spriteatlas",
            spriteName = "fight_saodang_kuang02"
        },
        kuang03 = {
            atlasName = "UIAutoFightSweep.spriteatlas",
            spriteName = "fight_saodang_kuang04"
        },
        di08 = {
            atlasName = "UIAutoFightSweep.spriteatlas",
            spriteName = "fight_saodang_di09"
        },
        titleColor = {
            color = "#FFFFFF"
        },
        optionTitleColorOff = {
            color = "#F4F4F4"
        },
        optionTitleColorOn = {
            color = "#F4F4F4"
        },
        optionColor = {
            color = "#F4F4F4"
        },
        optionColor2 = {
            color = "#3E3D3D"
        },
        optionTabBtnOff1 = { -- Option Off 选项 1 bg
        },
        optionTabBtnOn1 = { -- Option On 选项 1 bg
        },
        optionTabBtnOff2 = { -- Option Off 选项 2 bg
        },
        optionTabBtnOn2 = { -- Option On 选项 2 bg
        },
        optionFightBtnBg = { -- Option 按钮 背景
        },
        optionFightBtnImg = { -- Option 按钮 装饰
        }
    }
    style.dark = dark
    
    --------------------------------------------------------------------------------
    local season = {
        bg_di01 = { -- 不带目标的矮背景 赛季不使用
            rawImageName = "exp_s1_map_di42"
        },
        bg_di04 = { -- 带目标的高背景
            rawImageName = "fight_saodang_di04"
        },
        bg_di05 = { -- 扫荡背景
            rawImageName = "exp_s1_map_di43"
        },
        line01 = { -- 复用 默认
            atlasName = "UIAutoFightSweep.spriteatlas",
            spriteName = "fight_saodang_line01"
        },
        line03 = { -- 复用 默认
            atlasName = "UIAutoFightSweep.spriteatlas",
            spriteName = "fight_saodang_line03"
        },
        kuang01 = { -- 赛季不使用
            atlasName = "UIAutoFightSweep.spriteatlas",
            spriteName = "fight_saodang_kuang02"
        },
        kuang03 = { -- 复用 默认
            atlasName = "UIAutoFightSweep.spriteatlas",
            spriteName = "fight_saodang_kuang03"
        },
        di08 = { -- 赛季 需要隐藏
            active = false
        },
        titleColor = {
            color = "#2A2A2C"
        },
        optionTitleColorOff = { -- Option Off 选项字体颜色
            color = "#68421F"
        },
        optionTitleColorOn = { -- Option On 选项字体颜色
            color = "#6F5F3E"
        },
        optionColor = {
            color = "#2E2E2E"
        },
        optionColor2 = {
            color = "#3E3D3D"
        },
        optionTabBtnOff1 = { -- Option Off 选项 1 bg
            active = false
        },
        optionTabBtnOn1 = { -- Option On 选项 1 bg
            atlasName = "UIS1Main.spriteatlas",
            spriteName = "exp_s1_map_di39"
        },
        optionTabBtnOff2 = { -- Option Off 选项 2 bg
            active = false
        },
        optionTabBtnOn2 = { -- Option On 选项 2 bg
            atlasName = "UIS1Main.spriteatlas",
            spriteName = "exp_s1_map_di40"
        },
        optionFightBtnBg = { -- Option 按钮 背景
            atlasName = "UIS1Main.spriteatlas",
            spriteName = "exp_s1_map_btn02"
        },
        optionFightBtnImg = { -- Option 按钮 装饰
            active = true,
            atlasName = "UIS1Main.spriteatlas",
            spriteName = "exp_s1_map_icon21"
        }
    }
    style.season = season

    --------------------------------------------------------------------------------
    local styleInfo = style[name] and style[name][key]
    if styleInfo == nil then
        Log.exception("UISerialAutoFightStyleHelper.GetStyle(", name, ", ", key, ") return nil")
    end
    return styleInfo
end

--------------------------------------------------------------------------------

function UISerialAutoFightStyleHelper.FitStyle_RichText(styleName, styleKey, text)
    local info = UISerialAutoFightStyleHelper.GetStyleInfo(styleName, styleKey)
    return UIStyleHelper.FitStyle_RichText(info, text)
end

function UISerialAutoFightStyleHelper.FitStyle_Widget(styleName, styleKey, uiView, widgetName)
    local info = UISerialAutoFightStyleHelper.GetStyleInfo(styleName, styleKey)
    return UIStyleHelper.FitStyle_Widget(info, uiView, widgetName)
end
