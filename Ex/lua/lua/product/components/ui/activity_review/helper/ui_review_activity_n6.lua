--[[
    n6活动 回顾信息
]]
---@class UIReviewActivityN6:UIReviewActivityBase
_class("UIReviewActivityN6", UIReviewActivityBase)
UIReviewActivityN6 = UIReviewActivityN6

function UIReviewActivityN6:Constructor(id, sample)
end

function UIReviewActivityN6:AssetPackageID()
    return 6
end

-- ---@return boolean 是否有红点
-- function UIReviewActivityN6:HasRedPoint()
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

function UIReviewActivityN6:ActivityOnOpen()
    TaskManager:GetInstance():StartTask(self.OpenActivity, self)
end

function UIReviewActivityN6:OpenActivity(TT)
    GameGlobal.UIStateManager():SwitchState(UIStateType.UIN6MainController_Review)
end


function UIReviewActivityN6:GetBattleExitParam(comID, missionCreateInfo, isWin, battleresultRt)
    if comID == ECampaignReviewN6ComponentID.LINE_MISSION then
        return UIStateType.UIActivityN6LineMissionReview, nil
    end
end

---@return boolean 是否已完成
function UIReviewActivityN6:IsFinished()
    if self:IsUnlock() then
        return self:ProgressPercent() >= 100
    end
    return false
end
