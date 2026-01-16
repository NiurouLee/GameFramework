---@class UIActivityN32HardLevel : UIActivityHardLevel
_class("UIActivityN32HardLevel", UIActivityHardLevel)
UIActivityN32HardLevel = UIActivityN32HardLevel

function UIActivityN32HardLevel:GetTimeDownString()
    return "str_n32_hard_level_remain_time"
end

function UIActivityN32HardLevel:NodePlayAnimationInterval(TT)
    -- YIELD(TT, 30)
end

function UIActivityN32HardLevel:GetLevelNodeName()
    return "UIActivityN32NHardLevelNode"
end
