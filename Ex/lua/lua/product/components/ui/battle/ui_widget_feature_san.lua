---@class UIWidgetFeatureSan : UICustomWidget
_class("UIWidgetFeatureSan", UICustomWidget)
UIWidgetFeatureSan = UIWidgetFeatureSan
function UIWidgetFeatureSan:OnShow(uiParams)
    self:InitWidget()
end
function UIWidgetFeatureSan:InitWidget()
    --generated--
    self._imageNormalGo = self:GetGameObject( "ImageNormal")
    self._imageWarningGo = self:GetGameObject( "ImageWarning")
    ---@type UnityEngine.UI.Image
    self._imageNormal = self:GetUIComponent("Image", "ImageNormal")
    ---@type UnityEngine.UI.Image
    self._imageWarning = self:GetUIComponent("Image", "ImageWarning")
    ---@type UILocalizationText
    self._sanValue = self:GetUIComponent("UILocalizationText", "SanValue")
    ---@type UnityEngine.Animation
    self._anim = self:GetUIComponent("Animation", "UIWidgetFeatureSan")

    self._imageWarningGo:SetActive(false)

    self._animName = {[1]="uieffanim_N16_UIWidgetFeatureSan_01",[2]="uieffanim_N16_UIWidgetFeatureSan_02"}
    self._curAnimLevel = 0
    self:RegisterEvent()
    --generated end--
end
function UIWidgetFeatureSan:RegisterEvent()
    self:AttachEvent(GameEventType.FeatureSanValueChange, self._OnFeatureSanValueChange)
end
---@param sanInitData FeatureEffectParamSan
function UIWidgetFeatureSan:SetData(sanInitInfo)
    self._sanInitData = sanInitInfo
    local sanityParam = self._sanInitData:GetSanityParam()
    self._sanEffTopVal = BattleConst.SanViewEffDefaultStartVal
    if sanityParam then
        if sanityParam.viewEffStartVal then
            self._sanEffTopVal = sanityParam.viewEffStartVal
        end
    end
    local enterValue = sanInitInfo:GetEnterSanValue()
    self._maxVal = sanInitInfo:GetMaxSanValue()
    self._minVal = sanInitInfo:GetMinSanValue()
    self:SetValue(enterValue)
end
function UIWidgetFeatureSan:UIWidgetFeatureSanOnClick(go)
    self:ShowDialog("UIFeatureSanInfo",self._sanInitData,self._curVal)
end
function UIWidgetFeatureSan:SetValue(sanValue)
    self._curVal = sanValue
    self:_SetUiValue(self._curVal)
end
---设置UI
function UIWidgetFeatureSan:_SetUiValue(sanValue)
    if sanValue > self._maxVal then
        sanValue = self._maxVal
    end
    if sanValue < self._minVal then
        sanValue = self._minVal
    end
    sanValue = math.floor(sanValue + 0.5)
    self._sanValue:SetText(sanValue)
    local sanNormal = (sanValue > 0)
    self._imageNormalGo:SetActive(sanNormal)
    self._imageWarningGo:SetActive(not sanNormal)
    --sjs_todo 飘字
    --特效处理
    if sanValue <= self._sanEffTopVal and sanValue > 0 then
        if self._curAnimLevel ~= 1 then
            self._curAnimLevel = 1
            self._anim:Play(self._animName[1])
        end
    elseif sanValue == 0 then
        if self._curAnimLevel ~= 2 then
            self._curAnimLevel = 2
            self._anim:Play(self._animName[2])
        end
    else
        if self._curAnimLevel ~= 0 then
            self._curAnimLevel = 0
            self._anim:Stop()
        end
    end
end
---San值变化
function UIWidgetFeatureSan:_OnFeatureSanValueChange(curValue,oldValue,modifyValue)
    self._curVal = self._curVal + modifyValue
    self:SetValue(self._curVal)
end
