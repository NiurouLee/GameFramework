---@class UIReviewProgressAwardDetailContent_N9 : UIReviewProgressAwardDetailContent
_class("UIReviewProgressAwardDetailContent_N9", UIReviewProgressAwardDetailContent)
UIReviewProgressAwardDetailContent_N9 = UIReviewProgressAwardDetailContent_N9

-- function UIReviewProgressAwardDetailContent_N9:SetData(uiView, awardCallback, campaignType, itemClassName, itemPrefabName)
-- end

-- function UIReviewProgressAwardDetailContent_N9:CloseOnClick(go)
-- end

-- 如果有关闭动效，重写此方法
function UIReviewProgressAwardDetailContent_N9:_GetCloseAnim()
    return "uieffanim_ReviewProgressAwardDetailContent_N9_out", 200
end