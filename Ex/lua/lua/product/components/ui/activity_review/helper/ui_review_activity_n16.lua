--[[
    n16活动 回顾信息
]]
---@class UIReviewActivityN16:UIReviewActivityBase
_class("UIReviewActivityN16", UIReviewActivityBase)
UIReviewActivityN16 = UIReviewActivityN16

function UIReviewActivityN16:Constructor(id, sample)
end

function UIReviewActivityN16:AssetPackageID()
    return 16
end

function UIReviewActivityN16:ActivityOnOpen()
    ---@type UIActivityReview
    local controller = GameGlobal.UIStateManager():GetController("UIActivityReview")
    local rt = controller:GetShotImage()
    local cache_rt = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
    cache_rt.format = UnityEngine.RenderTextureFormat.RGB111110Float--此处是为了处理截图后图片颜色会加深的问题
    GameGlobal.TaskManager():StartTask(
        function(TT)
            YIELD(TT)
            UnityEngine.Graphics.Blit(rt, cache_rt)
            GameGlobal.UIStateManager():SwitchState(UIStateType.UIActivityN16ReviewMainController, cache_rt)
        end
    )
end

function UIReviewActivityN16:GetBattleExitParam(comID, missionCreateInfo, isWin, battleresultRt)
    if comID == ECampaignReviewN16ComponentID.ECAMPAIGN_REVIEW_ReviewN16_LINE_MISSION then
        return UIStateType.UIActivityN16ReviewLineMissionController, nil
    end
end