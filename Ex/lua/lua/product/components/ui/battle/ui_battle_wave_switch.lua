---@class UIBattleWaveSwitch : UIController
_class("UIBattleWaveSwitch", UIController)
UIBattleWaveSwitch = UIBattleWaveSwitch

function UIBattleWaveSwitch:OnShow(uiParams)
    local waveIndex = uiParams[1]
    self._num = self:GetUIComponent("UILocalizationText", "wavenum")
    local tex = StringTable.Get("str_battle_wave_switch",waveIndex)
    self._num:SetText(tex)
    -- self._event =
    --     GameGlobal.Timer():AddEvent(
    --     2000,
    --     function()
    --     end
    -- )
end

function UIBattleWaveSwitch:OnHide()
    -- if self._event then
    --     GameGlobal.Timer():CancelEvent(self._event)
    -- end
end
