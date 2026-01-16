---@class UIHauteCoutureDrawEnterAni:UICustomWidget
_class("UIHauteCoutureDrawEnterAni", UICustomWidget)
UIHauteCoutureDrawEnterAni = UIHauteCoutureDrawEnterAni

function UIHauteCoutureDrawEnterAni:Constructor()
    self._clipLength = -1
end

function UIHauteCoutureDrawEnterAni:OnShow()
    self:InitWidgets()
end

function UIHauteCoutureDrawEnterAni:InitWidgets()
    local aniGo = self:GetGameObject("Animation")
    ---@type UnityEngine.Animation
    local animation = aniGo:GetComponent("Animation")
    local clips = HelperProxy:GetInstance():GetAllAnimationClip(animation)
    if clips and clips.Length > 0 then
        local clip = clips[0]
        self._clipLength = clip.length
    end
end

function UIHauteCoutureDrawEnterAni:GetClipLength()
    return self._clipLength
end