---@class UIMapNodeItemPlot:UIMapNodeItemBase
_class("UIMapNodeItemPlot", UIMapNodeItemBase)
UIMapNodeItemPlot = UIMapNodeItemPlot

---@overload
function UIMapNodeItemPlot:GetUIComponentStar()
end
---@overload
function UIMapNodeItemPlot:FlushStar()
end

---@overload
function UIMapNodeItemPlot:GetTipAnimName()
    return "uieff_UINormNodePlot_in"
end
