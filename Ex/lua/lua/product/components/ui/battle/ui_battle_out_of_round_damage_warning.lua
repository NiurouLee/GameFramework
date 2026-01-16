_class("UIBattleOutOfRoundDamageWarning", UICustomWidget)
---@class UIBattleOutOfRoundDamageWarning : UICustomWidget
UIBattleOutOfRoundDamageWarning = UIBattleOutOfRoundDamageWarning

function UIBattleOutOfRoundDamageWarning:OnShow()
    ---@type UnityEngine.GameObject
    self._lowHpWarning = self:GetGameObject("LowHpWarning")

    self._lowHpWarning:SetActive(false)

    self:AttachEvent(GameEventType.ShowHideOutOfRoundDamageWarning, self.OnShowHideOutOfRoundDamageWarning)
end

function UIBattleOutOfRoundDamageWarning:OnShowHideOutOfRoundDamageWarning(b)
    self._lowHpWarning:SetActive(b)
end
