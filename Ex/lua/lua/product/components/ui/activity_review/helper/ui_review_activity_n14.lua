--[[
    n14活动 回顾信息
]]
---@class UIReviewActivityN14:UIReviewActivityBase
_class("UIReviewActivityN14", UIReviewActivityBase)
UIReviewActivityN14 = UIReviewActivityN14

function UIReviewActivityN14:Constructor(id, sample)
end

function UIReviewActivityN14:AssetPackageID()
    return 14
end

function UIReviewActivityN14:ActivityOnOpen()
    ---@type UIActivityReview
    local controller = GameGlobal.UIStateManager():GetController("UIActivityReview")
    local rt = controller:GetShotImage()
    local cache_rt = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
    cache_rt.format = UnityEngine.RenderTextureFormat.RGB111110Float--此处是为了处理截图后图片颜色会加深的问题
    GameGlobal.TaskManager():StartTask(
        function(TT)
            YIELD(TT)
            UnityEngine.Graphics.Blit(rt, cache_rt)
            GameGlobal.UIStateManager():SwitchState(UIStateType.UIN14MainReview, cache_rt)
        end
    )
end

function UIReviewActivityN14:GetBattleExitParam(comID, missionCreateInfo, isWin, battleresultRt)
    if comID == ECampaignReviewN14ComponentID.ECAMPAIGN_REVIEW_ReviewN14_LINE_MISSION then
        return UIStateType.UIActivityN14LineMissionControllerReview, nil
    end
end