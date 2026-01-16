---@class UIReviewProgressAward : UICustomWidget
_class("UIReviewProgressAward", UICustomWidget)
UIReviewProgressAward = UIReviewProgressAward

--设置数据
---@param idx number
---@param curIndex number
---@param progress number
function UIReviewProgressAward:SetData(idx, curIndex, progress, curProgress,hadReceive)
    ---@type UnityEngine.RectTransform
    self.root = self:GetUIComponent("RectTransform", "root")

    ---@type UnityEngine.RectTransform
    local parent = self.root.parent:GetComponent(typeof(UnityEngine.RectTransform))
    local width = parent.rect.width
    self.root.anchoredPosition = Vector2(width * progress / 100, 0)
    local state = 1
    if curIndex == -1 then
        --全部领取完了
        state = 3
    -- elseif idx > curIndex then
    --     state = 1
    -- elseif idx < curIndex then
    --     state = 3
    else
        if curProgress >= progress then
            if hadReceive then
                state = 3
            else  
                state = 2
            end  
        else 
            state = 1
        end
    end
    self:_SetState(state)
end

function UIReviewProgressAward:_SetState(state)
    local widgetNameGroup = { { "icon_cantCollected" }, { "icon_canCollected" }, { "icon_collected" } }
    local objs = UIWidgetHelper.GetObjGroupByWidgetName(self, widgetNameGroup)
    UIWidgetHelper.SetObjGroupShow(objs, state)
end

function UIReviewProgressAward:PlayEnterAni(index)
    local delay = 400 + (index - 1) * 50
    UIWidgetHelper.PlayAnimationInSequence(self, "_anim", nil, "uieffanim_UIReviewProgressAward_in", delay)
end
