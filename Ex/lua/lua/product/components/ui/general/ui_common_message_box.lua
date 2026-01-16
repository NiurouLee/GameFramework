--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    通用Popup弹框的示例
**********************************************************************************************
]] --------------------------------------------------------------------------------------------
---@class UICommonMessageBox:UIMessageBox
_class("UICommonMessageBox", UIMessageBox)

function UICommonMessageBox:Constructor()
    self._okMsgBox = nil
    self._okCancelMsgBox = nil

    self.okCallback = nil
    self.cancelCallback = nil
    --self.closeCallback = nil
    self._text = nil
end

function UICommonMessageBox:Destructor()
    self._okMsgBox = nil
    self._okCancelMsgBox = nil

    self.okCallback = nil
    self.cancelCallback = nil
    --self.closeCallback = nil
    self._text = nil
end

function UICommonMessageBox:OnShow()
    self._okMsgBox = self:GetGameObject("OKMsgBoxRoot")
    self._okCancelMsgBox = self:GetGameObject("OKCancelMsgBoxRoot")
    self._blurMask = self:GetUIComponent("H3DUIBlurHelper", "BlurMask")
    self._blurMaskObject = self:GetGameObject("BlurMask")
    ---@type UnityEngine.UI.Toggle
    self.tglNotRemind = self:GetUIComponent("Toggle", "tglNotRemind")
    self.tglNotRemind.gameObject:SetActive(false)

    self._blurMaskObject:SetActive(true)
    local camera = GameGlobal.UIStateManager():GetMessageBoxCamera()
    self._blurMask.OwnerCamera = camera
    self._blurMask:RefreshBlurTexture()
end

function UICommonMessageBox:ClearCallback()
    Log.debug("[msgbox] ClearCallback")
    self.okCallback = nil
    self.cancelCallback = nil
    --self.closeCallback = nil
end

function UICommonMessageBox:Alert(popup, params)
    self._blurMask:RefreshBlurTexture()
    local type = params[1]
    if type == PopupMsgBoxType.Ok then
        self:AlertOK(popup, params)
    elseif type == PopupMsgBoxType.OkCancel then
        self:AlertOKCancel(popup, params)
    end
    --[[
    elseif type == PopupMsgBoxType.OkCancelClose then
        self:AlertOKCancelClose(popup, params)
    elseif type == PopupMsgBoxType.OkClose then
        self:AlertOKClose(popup, params)
    end]]
end

---@private
---@param popup Popup
---@param params PopupMsgBoxType popupType strTxt okCallback callbackParam
function UICommonMessageBox:AlertOK(popup, params)
    Log.debug("[msgbox] UICommonMessageBox AlertOK [", params[2], "]", params[3])
    self._okMsgBox:SetActive(true)
    self._okCancelMsgBox:SetActive(false)

    ---@type UIRichText
    self._title = self:GetUIComponent("UIRichText", "OKTitle")
    self._title:SetText(params[2])
    ---@type UIRichText
    self._text = self:GetUIComponent("UIRichText", "OKText")
    self._text:SetText(params[3])

    self.okCallback = self:GetCallBack(popup, params[4], params[5])

    if params[6] then
        self._text.onHrefClick = params[6]
    end
    self._okBtnText = self:GetUIComponent("UILocalizationText", "OkCancelOkBtnText")
    if self._okBtnText then
        if params[7] then
            self._okBtnText:SetText(params[7])
        else
            self._okBtnText:SetText(StringTable.Get("str_common_ok"))
        end
    end
    
    self.tglNotRemind.gameObject:SetActive(false)
end

---@private
---@param popup Popup
---@param params PopupMsgBoxType popupType strTxt okCallback okCallbackParam cancelCalback cancelCallbackParam
---params
---1.
---2.标题
---3.提示内容
---4.确定按钮回调5.确定按钮回调参数
---6.取消按钮回调7.取消按钮回调参数
---8.提示超链接点击回调
---9.确定按钮文本，nil为str_common_ok
---10.取消按钮文本，nil为str_common_cancel
---11.本次登录不再提示的回调，非nil会显示复选框，nil隐藏复选框
function UICommonMessageBox:AlertOKCancel(popup, params)
    Log.debug("[msgbox] UICommonMessageBox AlertOKCancel [", params[2], "]", params[3])
    self._okMsgBox:SetActive(false)
    self._okCancelMsgBox:SetActive(true)

    ---@type UIRichText
    self._title = self:GetUIComponent("UIRichText", "OKCancelTitle")
    self._title:SetText(params[2])
    ---@type UIRichText
    self._text = self:GetUIComponent("UIRichText", "OKCancelText")
    self._text:SetText(params[3])

    self.okCallback = self:GetCallBack(popup, params[4], params[5])
    self.cancelCallback = self:GetCallBack(popup, params[6], params[7])

    if params[8] then
        self._text.onHrefClick = params[8]
    end
    self._okBtnText = self:GetUIComponent("UILocalizationText", "OkCancelOkBtnText")
    if self._okBtnText then
        if params[9] then
            self._okBtnText:SetText(params[9])
        else
            self._okBtnText:SetText(StringTable.Get("str_common_ok"))
        end
    end
    self._okCancelCancelBtnText = self:GetUIComponent("UILocalizationText", "OkCancelCancelBtnText")
    if self._okCancelCancelBtnText then
        if params[10] then
            self._okCancelCancelBtnText:SetText(params[10])
        else
            self._okCancelCancelBtnText:SetText(StringTable.Get("str_common_cancel"))
        end
    end
    --region 不再提示
    self.toggleTrueCallback = params[11]
    if self.toggleTrueCallback then
        self.tglNotRemind.gameObject:SetActive(true)
    else
        self.tglNotRemind.gameObject:SetActive(false)
    end
    --endregion
end

--[[
---@private
---@param popup Popup
---@param params PopupMsgBoxType strTitle strTxt alignment okText okCallback okCallbackParam
    --cancelText, calcleCallback, cancelCallbackParam
    --closeCalback, closeCallbackParam)
function UICommonMessageBox:AlertOKCancelClose(popup, params)
    self:SetTitleText(params[2])
    local alignment = params[4] or UnityEngine.TextAnchor.MiddleCenter
    self:SetText(params[3], alignment)

    local okText = params[5] or DEFAULT_OK_STRING
    self:SetButtonText(okText, "TextBtnOK")
    local cancelText = params[8] or DEFAULT_CANCEL_STRING
    self:SetButtonText(cancelText, "TextBtncancel")

    self:GetGameObject("ButtonOK").transform.localPosition = self.okOrgPos
    self:GetGameObject("Buttoncancel").transform.localPosition = self.cancelOrgPos

    UIHelper.SetActiveRecursively(true, self:GetGameObject("ButtonOK"), self:GetGameObject("Buttoncancel"), self:GetGameObject("ButtonClose"))

    self.okCallback = self:GetCallBack(popup, params[6], params[7])
    self.cancelCallback = self:GetCallBack(popup, params[9], params[10])
    self.closeCallback = self:GetCallBack(popup, params[11], params[12])
end

---@private
---@param popup Popup
---@param params PopupMsgBoxType strTitle strTxt alignment okText okCallback okCallbackParam
    --closeCalback closeCallbackParam)
function UICommonMessageBox:AlertOKClose(popup, params)
    self:SetTitleText(params[2])   
    local alignment = params[4] or UnityEngine.TextAnchor.MiddleCenter
    self:SetText(params[3], alignment)

    local okText = params[5] or DEFAULT_OK_STRING
    self:SetButtonText(okText, "TextBtnOK")
    self:GetGameObject("ButtonOK").transform.localPosition = (self.okOrgPos + self.cancelOrgPos) / 2

    UIHelper.SetActiveRecursively(true, self:GetGameObject("ButtonOK"), self:GetGameObject("ButtonClose"))
    UIHelper.SetActiveRecursively(false, self:GetGameObject("Buttoncancel"))

    self.okCallback = self:GetCallBack(popup, params[6], params[7])
    self.closeCallback = self:GetCallBack(popup, params[8], params[9])
end
]]
--region 按钮回调
---只有一个按钮的按钮回调
function UICommonMessageBox:ButtonOnClick(go)
    Log.debug("[msgbox] UICommonMessageBox AlertOK click ok")
    if self.okCallback then
        self.okCallback()
    end
end

---有OK Cancel按钮的OK回调
function UICommonMessageBox:ButtonOKOnClick(go)
    Log.debug("[msgbox] UICommonMessageBox AlertOKCancel click ok")
    if self.tglNotRemind.isOn and self.toggleTrueCallback then
        self.toggleTrueCallback()
    end
    if self.okCallback then
        self.okCallback()
    end
end

---有OK Cancel按钮的Cancel回调
function UICommonMessageBox:ButtonCancelOnClick(go)
    Log.debug("[msgbox] UICommonMessageBox AlertOKCancel click cancel")
    if self.cancelCallback then
        self.cancelCallback()
    end
    --播放取消按钮音效
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundCancel)
end

--[[
function UICommonMessageBox:ButtonCloseOnClick(go)
    if self.closeCallback then
        self.closeCallback()
    end
end
]]
--endregion
