---@class UIReviewProgressAwardDetailContent_N16 : UIReviewProgressAwardDetailContent
_class("UIReviewProgressAwardDetailContent_N16", UIReviewProgressAwardDetailContent)
UIReviewProgressAwardDetailContent_N16 = UIReviewProgressAwardDetailContent_N16

-- function UIReviewProgressAwardDetailContent_N16:SetData(uiView, awardCallback, campaignType, itemClassName, itemPrefabName)
-- end

-- function UIReviewProgressAwardDetailContent_N16:CloseOnClick(go)
-- end

-- 如果有关闭动效，重写此方法
function UIReviewProgressAwardDetailContent_N16:_GetCloseAnim()
    return "uieffanim_ReviewProgressAwardDetailContent_N9_out", 200
end