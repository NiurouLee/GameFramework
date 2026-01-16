--[[
    n12活动 回顾信息
]]
---@class UIReviewActivityN12:UIReviewActivityBase
_class("UIReviewActivityN12", UIReviewActivityBase)
UIReviewActivityN12 = UIReviewActivityN12

function UIReviewActivityN12:Constructor(id, sample)
end

function UIReviewActivityN12:AssetPackageID()
    return 12
end

function UIReviewActivityN12:ActivityOnOpen()
    ---@type UIActivityReview
    local controller = GameGlobal.UIStateManager():GetController("UIActivityReview")
    local rt = controller:GetShotImage()
    local cache_rt = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
    cache_rt.format = UnityEngine.RenderTextureFormat.RGB111110Float--此处是为了处理截图后图片颜色会加深的问题
    GameGlobal.TaskManager():StartTask(
        function(TT)
            YIELD(TT)
            UnityEngine.Graphics.Blit(rt, cache_rt)
            GameGlobal.UIStateManager():SwitchState(UIStateType.UIN12MainController_Review, cache_rt)
        end
    )
end

function UIReviewActivityN12:GetBattleExitParam(comID, missionCreateInfo, isWin, battleresultRt)
    if comID == ECampaignReviewN12ComponentID.ECAMPAIGN_REVIEW_ReviewN12_POINT_PROGRESS then
        return UIStateType.UIN12IntegralController_Review, nil
    end
end