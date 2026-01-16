---@class UIDefaultComponent:UIComponent
_class( "UIDefaultComponent",UIComponent)

function UIDefaultComponent:Constructor()
end

---该阶段UI资源已经显示了
function UIDefaultComponent:Show(uiParams)
    --切换界面时默认打断当前播放的语音
    local keepVoice = self.uiController:GetComponentSharedParam(UIComponentParamType.KeepVoice)
    if not keepVoice then
        GameGlobal.GetModule(PetAudioModule):StopAll()
    end
end
function UIDefaultComponent:AfterShow(TT)
end

function UIDefaultComponent:BeforeHide(TT)
end

---该阶段UI资源还没有隐藏
function UIDefaultComponent:Hide()
end