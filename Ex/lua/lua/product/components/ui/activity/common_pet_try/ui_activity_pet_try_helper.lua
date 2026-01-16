--[[
    活动辅助类
]]
---@class UIActivityPetTryHelper:Object
_class("UIActivityPetTryHelper", Object)
UIActivityPetTryHelper = UIActivityPetTryHelper

--region Red
---@return boolean
function UIActivityPetTryHelper.CheckCampaignRedPoint(campaign)
    return campaign:CheckCampaignNew() -- 光灵试用 用服务器的 new 数据代替 red
end
--endregion
