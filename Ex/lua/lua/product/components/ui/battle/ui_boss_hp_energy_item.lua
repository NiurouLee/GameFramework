_class("UIBossHPEnergyItem", UICustomWidget)
---@class UIBossHPEnergyItem : UICustomWidget
UIBossHPEnergyItem = UIBossHPEnergyItem

function UIBossHPEnergyItem:OnShow()
    self._animation = self:GetGameObject():GetComponent(typeof(UnityEngine.Animation))
end

function UIBossHPEnergyItem:DoLight(skipAnim)
    if self._animationLight then
        return
    end

    self:GetGameObject():SetActive(true)

    --这段我不是特别理解，我没找到这么做好使的原因，也没找到不这么做不好使的原因……
    self._animation:Stop()
    self._animation.enabled = false
    self._animation.enabled = true
    if skipAnim then
        self._animation:Play("uieffanim_UIBossHPEnergyItem_1", UnityEngine.PlayMode.StopAll)
    else
        self._animation:Play("uieffanim_UIBossHPEnergyItem_in", UnityEngine.PlayMode.StopAll)
    end

    self._animationLight = true
end

function UIBossHPEnergyItem:DoDark(skipAnim)
    if not self._animationLight then
        return
    end

    self:GetGameObject():SetActive(true)

    --这段我不是特别理解，我没找到这么做好使的原因，也没找到不这么做不好使的原因……
    self._animation:Stop()
    self._animation.enabled = false
    self._animation.enabled = true
    if skipAnim then
        self._animation:Play("uieffanim_UIBossHPEnergyItem_0", UnityEngine.PlayMode.StopAll)
    else
        self._animation:Play("uieffanim_UIBossHPEnergyItem_out", UnityEngine.PlayMode.StopAll)
    end
    self._animationLight = false
end

function UIBossHPEnergyItem:DoHide()
    self:GetGameObject():SetActive(false)
end
