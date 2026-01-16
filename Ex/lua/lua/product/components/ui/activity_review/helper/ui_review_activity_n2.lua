--[[
    n2活动（绯）回顾信息
]]
---@class UIReviewActivityN2:UIReviewActivityBase
_class("UIReviewActivityN2", UIReviewActivityBase)
UIReviewActivityN2 = UIReviewActivityN2

function UIReviewActivityN2:Constructor(id, sample)
end

function UIReviewActivityN2:AssetPackageID()
    return 2
end

function UIReviewActivityN2:ActivityOnOpen()
    ---@type UIActivityReview
    local controller = GameGlobal.UIStateManager():GetController("UIActivityReview")
    local rt = controller:GetShotImage()
    local cache_rt = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
    cache_rt.format = UnityEngine.RenderTextureFormat.RGB111110Float
    GameGlobal.TaskManager():StartTask(
        function(TT)
            YIELD(TT)
            UnityEngine.Graphics.Blit(rt, cache_rt)
            GameGlobal.UIStateManager():SwitchState(UIStateType.UISakuraEntryController_Review, cache_rt)
        end
    )
end
function UIReviewActivityN2:GetBattleExitParam(comID, missionCreateInfo, isWin, battleresultRt)
    --绯活动没有战斗关
    return nil
end
