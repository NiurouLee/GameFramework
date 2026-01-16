---@class UIN7MainAwardItemReview : UICustomWidget
_class("UIN7MainAwardItemReview", UICustomWidget)
UIN7MainAwardItemReview = UIN7MainAwardItemReview

function UIN7MainAwardItemReview:OnShow()
    ---@type UnityEngine.Animation
    self.anim = self:GetUIComponent("Animation", "UIN7MainAwardItemReview")
    self.notReach = self:GetGameObject("notReach")
    self.reach = self:GetGameObject("reach")
    self.next = self:GetGameObject("next")
end

function UIN7MainAwardItemReview:OnHide()
end
---@param isReach boolean 是否已达成
---@param isNext boolean 是否下一个
function UIN7MainAwardItemReview:Flush(isReach, isNext,checkGot)
    self.next:SetActive(false)
    self.notReach:SetActive(false)
    self.reach:SetActive(false)
    if isNext then
        self.next:SetActive(true)
    else
        if isReach and (not checkGot) then
            self.reach:SetActive(true)
        else
            self.notReach:SetActive(true)
        end
    end
end

function UIN7MainAwardItemReview:PlayAnim()
    self.anim:Play("uieff_N7_MainReview1")
end
