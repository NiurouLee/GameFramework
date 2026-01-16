---@class UISeasonHelperTab:UICustomWidget
_class("UISeasonHelperTab", UICustomWidget)
UISeasonHelperTab = UISeasonHelperTab

function UISeasonHelperTab:OnShow(uiParams)
    self:InitWidget()
end
function UISeasonHelperTab:InitWidget()
    ---@type UILocalizationText
    self._tabNameText = self:GetUIComponent("UILocalizationText", "TabName")
    self._selectedGo = self:GetGameObject("SelectedImg")
    self._selectedGo:SetActive(false)
end
function UISeasonHelperTab:OnHide()
end

function UISeasonHelperTab:TabBtnOnClick()
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)
    if self._callback then
        self._callback(self._tabId)
    end
end
function UISeasonHelperTab:SetData(tabCfg,callback)
    self._tabCfg = tabCfg
    self._tabId = self._tabCfg.ID
    self._callback = callback
    self._tabNameText:SetText(StringTable.Get(self._tabCfg.Title))
end
function UISeasonHelperTab:OnSelectIndex(tabId)
    if self._tabId == tabId then
        self._selectedGo:SetActive(true)
        self._tabNameText.color = Color(255/255,242/255,211/255,1)
    else
        self._selectedGo:SetActive(false)
        self._tabNameText.color = Color(208/255,208/255,206/255,1)
    end
end