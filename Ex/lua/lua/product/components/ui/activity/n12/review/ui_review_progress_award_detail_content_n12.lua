---@class UIReviewProgressAwardDetailContent_N12 : UIReviewProgressAwardDetailContent
_class("UIReviewProgressAwardDetailContent_N12", UIReviewProgressAwardDetailContent)
UIReviewProgressAwardDetailContent_N12 = UIReviewProgressAwardDetailContent_N12

-- function UIReviewProgressAwardDetailContent_N12:SetData(uiView, awardCallback, campaignType, itemClassName, itemPrefabName)
-- end

-- function UIReviewProgressAwardDetailContent_N12:CloseOnClick(go)
-- end

-- 如果有关闭动效，重写此方法
function UIReviewProgressAwardDetailContent_N12:_GetCloseAnim()
    return "uieffanim_ReviewProgressAwardDetailContent_N9_out", 200
end