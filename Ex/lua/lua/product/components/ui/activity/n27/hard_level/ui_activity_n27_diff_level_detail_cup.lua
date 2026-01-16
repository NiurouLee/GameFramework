---@class UIActivityN27DiffLevelDetailCup:UICustomWidget
_class("UIActivityN27DiffLevelDetailCup", UICustomWidget)
UIActivityN27DiffLevelDetailCup = UIActivityN27DiffLevelDetailCup
--困难关关卡
function UIActivityN27DiffLevelDetailCup:OnShow(uiParam)
    self._descTex = self:GetUIComponent("UILocalizationText","desc")
    self._awardGo = self:GetGameObject("award")
    self._awardIcon = self:GetUIComponent("RawImageLoader","awardIcon")
    self._awardCount = self:GetUIComponent("UILocalizationText","awardCount")
    self._complete = self:GetGameObject("Complete")
    self._uncomplete = self:GetGameObject("UnComplete")
end

---@param data UIActivityN27DiffLevelCupData
function UIActivityN27DiffLevelDetailCup:SetData(data)
    self._descTex:SetText(data:GetDes())
    local complete = data:IsComplete()
    self._complete:SetActive(complete)
    self._uncomplete:SetActive(not complete)
    if complete then
        self._awardGo:SetActive(false)
    else
        self._awardGo:SetActive(true)
    end
    self._awardIcon:LoadImage(data:GetRewardIcon())
    self._awardCount:SetText(data:GetRewardCount())
end
