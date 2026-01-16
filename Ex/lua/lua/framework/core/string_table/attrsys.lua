---@class AttrSys:Singleton
---@field GetInstance AttrSys
_class("AttrSys", Singleton)
AttrSys = AttrSys

local toint = math.tointeger
--属性显示
function AttrSys.GetFormatNum(num)
    local num0 = num / 1000000000 --十亿
    local num1 = num / 100000000 --亿
    local num2 = num / 100000 --十万
    local num3 = num / 10000 --万
    local s = num
    if num0 >= 1 then
        s = StringTable.Get("str_common_hundreds_of_millions_of", toint(num1))
    elseif num1 >= 1 then
        if num - num1 * 100000000 >= 10000000 then
            s = StringTable.Get("str_common_hundreds_of_millions_of", string.format("%0.1f", num1))
        else
            s = StringTable.Get("str_common_hundreds_of_millions_of", toint(num1))
        end
    elseif num2 >= 1 then
        s = StringTable.Get("str_common_tens_of_thousands_of", toint(num3))
    elseif num3 >= 1 then
        if num - math.floor(num3) * 10000 >= 1000 then
            s = StringTable.Get("str_common_tens_of_thousands_of", string.format("%0.1f", num3))
        else
            s = StringTable.Get("str_common_tens_of_thousands_of", toint(num3))
        end
    else
        s = toint(num)
    end
    return s
end

--战力数字显示（可能是图片字）
function AttrSys.FillForcenum()
end

---获取当前语言
function AttrSys.GetLanguage()
    return Localization.GetCurLanguage()
end

--获取安装包里所有的语言
function AttrSys.GetLanguages()
    return Localization.GetLanguages()
end