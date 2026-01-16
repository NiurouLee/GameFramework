--[[
    战斗通行证活动辅助类
]]
---@class UIActivityBattlePassHelper
_class("UIActivityBattlePassHelper", Object)
UIActivityBattlePassHelper = UIActivityBattlePassHelper

function UIActivityBattlePassHelper:Constructor()
end

--region Red
---@param campaign UIActivityCampaign
---@return boolean
function UIActivityBattlePassHelper.CheckComponentRedPoint(campaign, ...)
    if not campaign or not campaign:GetLocalProcess() or not campaign:CheckCampaignOpen() then
        return false
    end

    --- @type LVRewardComponent
    local component = campaign:GetComponent(ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_LV_REWARD)
    local extra = not component:CheckIsLevelMax()

    local componentExtraCondition = {
        [ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_LV_REWARD] = true,
        [ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_QUEST_1] = extra,
        [ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_QUEST_2] = extra,
        [ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_QUEST_3] = extra
    }

    local args = {...}
    for _, v in pairs(args) do
        if componentExtraCondition[v] and campaign:CheckComponentRed(v) then
            return true
        end
    end
    return false
end

---@return boolean
function UIActivityBattlePassHelper.CheckCampaignRedPoint(campaign)
    return UIActivityBattlePassHelper.CheckComponentRedPoint(
        campaign,
        ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_LV_REWARD,
        ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_QUEST_1,
        ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_QUEST_2,
        ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_QUEST_3
    )
end
--endregion

--region ShowDialog
function UIActivityBattlePassHelper.ShowBattlePassDialog(campaign)
    local cfg = Cfg.cfg_campaign[campaign._id]
    local uiName = cfg and cfg.MainUI
    if not string.isnullorempty(uiName) then
        GameGlobal.UIStateManager():ShowDialog(uiName)
    end
end
--endregion

--region UICG
function UIActivityBattlePassHelper.SetSpecialImg(campaign, obj, img, dialogName, desc1, desc2)
    --- @type LVRewardComponent
    local component = campaign:GetComponent(ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_LV_REWARD)
    local cfg = component:GetSpecialRewardCfg()
    local icon = cfg.SpecialRewardImage
    local descPos1 = cfg.SpeicalRewardDescPos1
    local descPos2 = cfg.SpeicalRewardDescPos2

    if not string.isnullorempty(icon) then
        img:LoadImage(icon)
        UICG.SetTransform(obj.transform, dialogName, icon)
    end

    if desc1 and descPos1 then
        desc1.transform.localPosition = Vector3(descPos1[1] or 0, descPos1[2] or 0, 0)
    end

    if desc2 and descPos2 then
        desc2.transform.localPosition = Vector3(descPos2[1] or 0, descPos2[2] or 0, 0)
    end
end
--endregion

--region GetStrIdInCampaign
-- 文字配置多期
function UIActivityBattlePassHelper.GetStrIdInCampaign(campaign, strId)
    return strId .. "_campaignid_" .. campaign._id
end
--endregion
