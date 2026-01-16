--[[
    回流系统活动辅助类
]]
---@class UIActivityReturnSystemHelper
_class("UIActivityReturnSystemHelper", Object)
UIActivityReturnSystemHelper = UIActivityReturnSystemHelper

function UIActivityReturnSystemHelper:Constructor()
end

function UIActivityReturnSystemHelper.LoadDataOnEnter(TT, res)
    local campaignType = UIActivityReturnSystemHelper.GetCampaignType()
    -- local componentIds = UIActivityReturnSystemHelper.GetAllComponentId()
    local componentIds = {}

    ---@type UIActivityCampaign
    local campaign = UIActivityHelper.LoadDataOnEnter(TT, res, campaignType, componentIds)
    return campaign
end

function UIActivityReturnSystemHelper.GetTabIndexByTabName(name)
    local tb = {
        ["welecome"] = 1,
        ["login"] = 2,
        ["quest"] = 3,
        ["shop"] = 4,
        ["gift"] = 5,
        ["boost"] = 6
    }
    return tb[name] or 1
end

--region campaign
function UIActivityReturnSystemHelper.GetComponentIdByTabIndex(index)
    local tb = {
        [1] = { ECampaignPlayerBackphaseIIComponentID.ECAMPAIGN_BACK_PHASEII_COMPONENT },
        [2] = { ECampaignPlayerBackphaseIIComponentID.ECAMPAIGN_BACK_PHASEII_CUMULATIVE_LOGIN },
        [3] = {
            ECampaignPlayerBackphaseIIComponentID.ECAMPAIGN_BACK_PHASEII_QUEST,
            ECampaignPlayerBackphaseIIComponentID.ECAMPAIGN_BACK_PHASEII_PERSON_PROGRESS
        },
        [4] = {
            ECampaignPlayerBackphaseIIComponentID.ECAMPAIGN_BACK_PHASEII_SHOP,
            ECampaignPlayerBackphaseIIComponentID.ECAMPAIGN_BACK_PHASEII_POWER2ITEM 
        },
        [5] = { ECampaignPlayerBackphaseIIComponentID.ECAMPAIGN_BACK_PHASEII_BUY_GIFT },
        [6] = { ECampaignPlayerBackphaseIIComponentID.ECAMPAIGN_BACK_PHASEII_RES_HELP }
    }
    return tb[index]
end

function UIActivityReturnSystemHelper.GetCampaignType()
    return ECampaignType.CAMPAIGN_TYPE_BACK_PHASE_II
end

function UIActivityReturnSystemHelper.GetAllComponentId()
    local tb_out = {}
    for i = 1, 6 do
        local tb = UIActivityReturnSystemHelper.GetComponentIdByTabIndex(i)
        for _, v in ipairs(tb) do
            table.insert(tb_out, v)
        end
    end
    return tb_out
end

function UIActivityReturnSystemHelper.GetComponentByTabName(campaign, name, i)
    i = i or 1
    local index = UIActivityReturnSystemHelper.GetTabIndexByTabName(name)
    local ids = UIActivityReturnSystemHelper.GetComponentIdByTabIndex(index)
    local tb_out = {}
    for _, v in ipairs(ids) do
        table.insert(tb_out, campaign:GetComponent(v))
    end
    return tb_out[i]
end

--endregion

--region Red
---@return boolean
function UIActivityReturnSystemHelper.CheckCampaignRedPoint(campaign)
    local ids = UIActivityReturnSystemHelper.GetAllComponentId()
    return campaign:CheckComponentRed(table.unpack(ids))
end


function UIActivityReturnSystemHelper.GetShopRedPointKey()
    local key = UIActivityHelper.GetLocalDBKeyWithPstId("UIActivityReturnSystemShopRed_")
    return key
end

function UIActivityReturnSystemHelper.GetShopRedPointTime()
    local timeModule =  GameGlobal.GameLogic():GetModule(SvrTimeModule)
    local nowTime = timeModule:GetServerTime() / 1000  --服务器时间 秒
    return nowTime
end

function UIActivityReturnSystemHelper.GetShopRedPoint()
    local campaignLen = 86400 * 10  --活动时长

    local key = UIActivityReturnSystemHelper.GetShopRedPointKey()
    local time = UIActivityReturnSystemHelper.GetShopRedPointTime()

    local isRed = not LocalDB.HasKey(key) or math.abs(LocalDB.GetInt(key) - time) >= campaignLen
    return isRed
end

function UIActivityReturnSystemHelper.SetShopRedPoint()
    local key = UIActivityReturnSystemHelper.GetShopRedPointKey()
    local time = UIActivityReturnSystemHelper.GetShopRedPointTime()
    LocalDB.SetInt(key, time)
end

--endregion
