--[[
    @风船行为过滤器
]]

_class("IAirFilter", Object)
---@class IAirFilter:Object
IAirFilter = IAirFilter

function IAirFilter:Filter(elements)
end


_class("SocialWeightFilter", IAirFilter)
---@class SocialWeightFilter:IAirFilter
SocialWeightFilter = SocialWeightFilter

function SocialWeightFilter:Filter(pet)
    -- if not pet then
    --     return false
    -- end
    -- local petTempId = pet:GetPetData():GetTemplateID()
    -- local cfg = Cfg.cfg_aircraft_pet[petTempId]
    -- if cfg then
    --     local r = math.random() --0.9
    --     local sw = cfg.SocialWeight --0.2
    --     return r <= sw
    -- end
    -- return false
    return true
end


_class("AreaFilter", IAirFilter)
---@class AreaFilter:IAirFilter
AreaFilter = AreaFilter

-- 方便以后筛选区域 目前是全区域
---@type AirRestAreaType
function AreaFilter:Filter(pet)
    local area = pet:GetWanderingArea()
    local spaceId = pet:GetSpace()
    return area ~= nil
end
