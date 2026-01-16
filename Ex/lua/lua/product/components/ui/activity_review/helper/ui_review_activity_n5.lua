--[[
    n5活动 回顾信息
]]
---@class UIReviewActivityN5:UIReviewActivityBase
_class("UIReviewActivityN5", UIReviewActivityBase)
UIReviewActivityN5 = UIReviewActivityN5

function UIReviewActivityN5:Constructor(id, sample)
end

function UIReviewActivityN5:AssetPackageID()
    return 5
end

-- ---@return boolean 是否有红点
-- function UIReviewActivityN5:HasRedPoint()
--     if self:IsUnlock() then
--         ---@type campaign_sample
--         local sampleInfo = self._campObj:GetSampleInfo()
--         local key = sampleInfo.m_extend_info[CampainExtendKey.E_CAMPAIGN_EXTEND_KEY_COMPLETE_COND]
--         if key ~= 1 then --未开启
--             return false
--         end
--         return sampleInfo:GetStepStatus(ECampaignStep.CAMPAIGN_STEP_REWARD) --有未领取的进度奖励
--     end
--     return false
-- end

function UIReviewActivityN5:ActivityOnOpen()
    TaskManager:GetInstance():StartTask(self.OpenActivity, self)
end

function UIReviewActivityN5:OpenActivity(TT)
    GameGlobal.UIStateManager():SwitchState(UIStateType.UIN5MainController_Review)
end


function UIReviewActivityN5:GetBattleExitParam(comID, missionCreateInfo, isWin, battleresultRt)
    if comID == ECampaignReviewEvaRescuePlanComponentID.ECAMPAIGN_REVIEW_EVARESCUEPLAN_LINE_MISSION then
        return UIStateType.UIActivityN5SimpleLevelReview, nil
    end
end
