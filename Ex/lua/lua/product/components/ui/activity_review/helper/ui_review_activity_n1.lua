--[[
    n1活动（伊芙醒山）回顾信息
]]
---@class UIReviewActivityN1:UIReviewActivityBase
_class("UIReviewActivityN1", UIReviewActivityBase)
UIReviewActivityN1 = UIReviewActivityN1

function UIReviewActivityN1:Constructor(id, sample)
end

function UIReviewActivityN1:AssetPackageID()
    return 1
end

function UIReviewActivityN1:ActivityOnOpen()
    GameGlobal.UIStateManager():SwitchState(UIStateType.UIActivityEveSinsaMainController_Review)
end

function UIReviewActivityN1:GetBattleExitParam(comID, missionCreateInfo, isWin, battleresultRt)
    if comID == ECampaignReviewEvaRescuePlanComponentID.ECAMPAIGN_REVIEW_EVARESCUEPLAN_LINE_MISSION then
        return UIStateType.UIActivityEveSinsaLevelAController_Review, nil
    elseif comID == ECampaignReviewEvaRescuePlanComponentID.ECAMPAIGN_REVIEW_EVARESCUEPLAN_TREE_MISSION then
        return UIStateType.UIActivityEveSinsaLevelBController_Review, nil
    end
end

--n1定制的红点数据
function UIReviewActivityN1:GetRedAndNewData()
    if self._redNewData == nil then
        self._redNewData = UIActivityEveSinaNewFlagRedPoint_Review:New()
    end
    return self._redNewData
end
