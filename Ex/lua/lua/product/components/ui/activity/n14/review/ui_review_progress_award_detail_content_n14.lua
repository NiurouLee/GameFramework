---@class UIReviewProgressAwardDetailContent_N14 : UIReviewProgressAwardDetailContent
_class("UIReviewProgressAwardDetailContent_N14", UIReviewProgressAwardDetailContent)
UIReviewProgressAwardDetailContent_N14 = UIReviewProgressAwardDetailContent_N14

-- function UIReviewProgressAwardDetailContent_N14:SetData(uiView, awardCallback, campaignType, itemClassName, itemPrefabName)
-- end

-- function UIReviewProgressAwardDetailContent_N14:CloseOnClick(go)
-- end

-- 如果有关闭动效，重写此方法
function UIReviewProgressAwardDetailContent_N14:_GetCloseAnim()
    return "uieffanim_ReviewProgressAwardDetailContent_N9_out", 200
end