---@class UIActivityN21CCLevelHardItem:UICustomWidget
_class("UIActivityN21CCLevelHardItem", UICustomWidget)
UIActivityN21CCLevelHardItem = UIActivityN21CCLevelHardItem

function UIActivityN21CCLevelHardItem:OnShow()
    self._scoreGo = self:GetGameObject("Score")
    self._nameLabel = self:GetUIComponent("UILocalizationText", "Name")
    self._scoreLabel = self:GetUIComponent("UILocalizationText", "Score")
    self._lock = self:GetGameObject("Lock")
end

function UIActivityN21CCLevelHardItem:OnHide()
end

---@param levelData UIActivityN21CCLevelData
function UIActivityN21CCLevelHardItem:Refresh(levelData, isSelected, callback)
    ---@type UIActivityN21CCLevelData
    self._levelData = levelData
    self._callback = callback
    if levelData:IsLevelOpen() then
        self._lock:SetActive(false)
        self._scoreGo:SetActive(true)
        self._scoreLabel.color = Color(254 / 255, 252 / 255, 250 / 255, 1)
        self._nameLabel.color = Color(254 / 255, 252 / 255, 250 / 255, 1)
    else
        self._lock:SetActive(true)
        self._scoreGo:SetActive(false)
        self._scoreLabel.color =  Color(170 / 255, 170 / 255, 170 / 255, 1)
        self._nameLabel.color = Color(170 / 255, 170 / 255, 170 / 255, 1)
    end
    if isSelected then
        self._scoreLabel.color = Color(255 / 255, 181 / 255, 41 / 255, 1)
        self._nameLabel.color = Color(255 / 255, 181 / 255, 41 / 255, 1)
    end
    self._nameLabel:SetText(StringTable.Get("str_n20_crisis_contract_hard_title" .. levelData:GetHardId()))
    self._scoreLabel:SetText(levelData:GetBaseScore())
end

function UIActivityN21CCLevelHardItem:BtnOnClick()
    if not self._levelData:IsLevelOpen() then
        if self._callback then
            self._callback(false, self._levelData:GetHardId())
        end
        ToastManager.ShowToast(StringTable.Get("str_n20_crisis_contract_hard_lock_tips", self._levelData:GetUnLockScore()))
        return
    end
    if self._callback then
        self._callback(true, self._levelData:GetHardId())
    end
end
