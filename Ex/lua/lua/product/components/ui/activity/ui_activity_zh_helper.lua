--[[
    活动辅助类
]]
---@class UIActivityZhHelper:Object
_class("UIActivityZhHelper", Object)
UIActivityZhHelper = UIActivityZhHelper

function UIActivityZhHelper:Constructor()
end

function UIActivityZhHelper.IsZh()
    return false -- [国服] = true [国际服] = false
end
