---@class CampaignDataBase:Object
_class("CampaignDataBase", Object)
CampaignDataBase = CampaignDataBase

function CampaignDataBase:Constructor()
    self.activityCampaign = UIActivityCampaign:New()
end

---@param campaignType ECampaignType
---@param res AsyncRequestRes
function CampaignDataBase:RequestCampaign(TT, campaignType, res)
    res = res and res or AsyncRequestRes:New()
    if self.activityCampaign._type == -1 or self.activityCampaign._id == -1 then
        self.activityCampaign:LoadCampaignInfo(TT, res, campaignType)
    else
        self.activityCampaign:ReLoadCampaignInfo_Force(TT, res)
    end
    if res and res:GetSucc() then
    else
        Log.fatal("### [RequestCampaign]CampaignComProtoLoadInfo failed.")
    end
    return res
end
function CampaignDataBase:GetLocalProcess()
    return self.activityCampaign:GetLocalProcess()
end
---@return ECampaignType, number 活动类型，活动id
function CampaignDataBase:GetCampaignTypeId()
    return self.activityCampaign._type, self.activityCampaign._id
end
---@return campaign_sample
function CampaignDataBase:GetCampaignSample()
    return self.activityCampaign:GetSample()
end

---@return campaign_module
function CampaignDataBase:GetCampaignModule()
    return self.activityCampaign._campaign_module
end

---@return UIActivityCampaign
function CampaignDataBase:GetActivityCampaign()
    return self.activityCampaign
end

---@return number 该活动的货币道具id
function CampaignDataBase:GetCurrencyId()
    local cfg = Cfg.cfg_activity_shop_common_client[self.activityCampaign._id]
    if cfg then
        return cfg.CurrencyId
    end
    return 3000271 --如果找不到，就返回写死的货币道具
end
