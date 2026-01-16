--[[
    n9活动 回顾信息
]]
---@class UIReviewActivityN9:UIReviewActivityBase
_class("UIReviewActivityN9", UIReviewActivityBase)
UIReviewActivityN9 = UIReviewActivityN9

function UIReviewActivityN9:Constructor(id, sample)
end

function UIReviewActivityN9:AssetPackageID()
    return 9
end

-- ---@return boolean 是否有红点
-- function UIReviewActivityN9:HasRedPoint()
-- end

function UIReviewActivityN9:ActivityOnOpen()
    ---@type UIActivityReview
    local controller = GameGlobal.UIStateManager():GetController("UIActivityReview")
    local rt = controller:GetShotImage()
    local cache_rt = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
    GameGlobal.TaskManager():StartTask(
        function(TT)
            YIELD(TT)
            UnityEngine.Graphics.Blit(rt, cache_rt)
            GameGlobal.UIStateManager():SwitchState(UIStateType.UIActivityN9MainController_Review, cache_rt)
        end
    )
end

function UIReviewActivityN9:GetBattleExitParam(comID, missionCreateInfo, isWin, battleresultRt)
    if comID == ECampaignReviewN9ComponentID.ECAMPAIGN_REVIEW_ReviewN9_LINE_MISSION then
        return UIStateType.UIActivityN9LineMissionController_Review, nil
    end
end
