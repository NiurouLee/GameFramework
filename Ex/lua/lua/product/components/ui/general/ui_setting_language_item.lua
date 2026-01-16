---@class UISettingLanguageItem : UICustomWidget
_class("UISettingLanguageItem", UICustomWidget)
UISettingLanguageItem = UISettingLanguageItem
function UISettingLanguageItem:OnShow(uiParams)
    self:InitWidget()
end
function UISettingLanguageItem:InitWidget()
    --generated--
    ---@type UnityEngine.UI.Image
    self.image = self:GetUIComponent("Image", "Image")
    ---@type UnityEngine.UI.Button
    self.btn = self:GetUIComponent("Button", "btn")
    --generated end--
end
function UISettingLanguageItem:SetData(cfg, languageType, sprite)
    self.image.sprite = sprite
    self._type = languageType
    self._cfg = cfg
end

function UISettingLanguageItem:Refresh(curLanguage)
    if self._type == curLanguage then
        self.btn.interactable = false
        self.image.color = Color.black
        self._isCur = true
    else
        self.btn.interactable = true
        self.image.color = Color.white
        self._isCur = false
    end
end
function UISettingLanguageItem:itemOnClick(go)
    if self._isCur then
        return
    end

    PopupManager.Alert(
        "UICommonMessageBox",
        PopupPriority.Normal,
        PopupMsgBoxType.OkCancel,
        "",
        StringTable.Get("str_set_change_language_to", StringTable.Get(self._cfg.Text)),
        function(param)
            --确定
            self:Lock("切换语言后锁定UI,不允许解锁")
            Localization.SetLocalLanguage(self._type)
            Log.debug("切换语言为:", self._cfg.ID)
            if EDITOR then
                ToastManager.ShowToast("编辑器中需要手动重启游戏")
            else
                UnityEngine.Application.Quit()
            end
        end,
        nil,
        function(param)
            --取消
        end,
        nil
    )
end
