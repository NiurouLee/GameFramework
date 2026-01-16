---@class UIXH1Summer1ProcessItemReview:UICustomWidget
_class("UIXH1Summer1ProcessItemReview", UICustomWidget)
UIXH1Summer1ProcessItemReview = UIXH1Summer1ProcessItemReview

function UIXH1Summer1ProcessItemReview:OnShow()
    self._hasGet = self:GetGameObject("HasGet")
    self._lastCanGet = self:GetGameObject("LastCanGet")
    self._unComplete = self:GetGameObject("UnComplete")
end

function UIXH1Summer1ProcessItemReview:SetData(summer, data)
    ---@type UISummer1Review
    self._summer = summer
    -- data.progress = p
    -- data.status = 0 --1:已领取，2:最近的可领取，3:可领取或未完成
    self._data = data
    self._hasGet:SetActive(false)
    self._lastCanGet:SetActive(false)
    self._unComplete:SetActive(false)
    if self._data.status == 1 then --1:已领取
        self._hasGet:SetActive(true)
    elseif self._data.status == 2 then --2:最近的可领取
        self._lastCanGet:SetActive(true)
    elseif self._data.status == 3 then --3:可领取或未完成
        self._unComplete:SetActive(true)
    end
end

function UIXH1Summer1ProcessItemReview:CanGetOnClick()
    -- self._summer:GetReward(self._data.progress)
end

function UIXH1Summer1ProcessItemReview:LastCanGetOnClick()
    -- self._summer:GetReward(self._data.progress)
end
