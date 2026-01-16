_class("UIBattleAuroraTime", UICustomWidget)
---@class UIBattleAuroraTime : UICustomWidget
UIBattleAuroraTime = UIBattleAuroraTime

function UIBattleAuroraTime:OnShow()
    self._auroraTimeEff = self:GetGameObject("uieff_jgsk")
    self._leftText = self:GetUIComponent("UILocalizationText", "txt_left")
    self._rightText = self:GetUIComponent("UILocalizationText", "txt_right")
    self._leftTextLayoutElement = self:GetUIComponent("LayoutElement", "txt_left")
    self._rightTextLayoutElement = self:GetUIComponent("LayoutElement", "txt_right")

    self._auroraTimeEff:SetActive(false)

    self:AttachEvent(GameEventType.ShowHideAuroraTime, self.ShowHideAuroraTime)
end

function UIBattleAuroraTime:ShowHideAuroraTime(isShow)
    self._auroraTimeEff:SetActive(isShow)
    if isShow then
        --极光时刻文本适配
        self._leftText:SetText(StringTable.Get("str_battle_aurora_time_str_aurora"))
        self._rightText:SetText(StringTable.Get("str_battle_aurora_time_str_time"))
        local leftWidth = self._leftText.preferredWidth
        local rightWidth = self._rightText.preferredWidth
        if leftWidth > rightWidth then
            self._rightTextLayoutElement.minWidth = leftWidth
        else
            self._leftTextLayoutElement.minWidth = rightWidth
        end
    end

    if isShow then
        --bgm混音效果开始
        AudioHelperController.SetBGMMixerGroup(
                AudioConstValue.AuroralTimeMixerGroupName,
                AudioConstValue.AuroralTimeMixerValue
        )
    else
        --bgm混音效果结束
        AudioHelperController.SetBGMMixerGroup(
                AudioConstValue.AuroralTimeMixerGroupName,
                AudioConstValue.DefaultMixerValue
        )
    end
end
