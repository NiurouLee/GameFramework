---@class UIActivityReturnSystemTabBtn:UICustomWidget
_class("UIActivityReturnSystemTabBtn", UICustomWidget)
UIActivityReturnSystemTabBtn = UIActivityReturnSystemTabBtn

function UIActivityReturnSystemTabBtn:OnShow()
    self._isOpen = true
    self._isSelected = false
    -- self:SetSelected(false)
end

function UIActivityReturnSystemTabBtn:OnHide()
    self._isOpen = false
end

function UIActivityReturnSystemTabBtn:SetData(idx, strId, callback)
    self._index = idx
    self._strId = strId
    self._callback = callback

    self:_SetTitle(idx, strId)
end

function UIActivityReturnSystemTabBtn:SetSelected(isSelected)
    -- local normal = {
    --     self:GetGameObject("_bg_normal"),
    --     self:GetGameObject("_text_normal")
    -- }
    -- local selected = {
    --     self:GetGameObject("_bg_selected"),
    --     self:GetGameObject("_text_selected")
    -- }

    -- for _, v in pairs(normal) do
    --     v:SetActive(not isSelected)
    -- end
    -- for _, v in pairs(selected) do
    --     v:SetActive(isSelected)
    -- end
    if self._isSelected ~= isSelected then
        local animName = isSelected and "uieff_TabBtn_in" or "uieff_TabBtn_out"
        UIWidgetHelper.SetAnimationPlay(self, "_anim", animName)
        self._isSelected = isSelected
    end
end

function UIActivityReturnSystemTabBtn:SetRedPoint(red)
    local obj = self:GetGameObject("_red")
    obj:SetActive(red)
end

function UIActivityReturnSystemTabBtn:_SetTitle(idx, strId)
    local title = {
        "_text_normal",
        "_text_selected"
    }

    for _, v in pairs(title) do
        ---@type UILocalizationText
        local _text = self:GetUIComponent("UILocalizationText", v)
        _text:SetText(StringTable.Get(strId[idx]))
    end
end

--region Event Callback
function UIActivityReturnSystemTabBtn:TabBtnOnClick(go)
    Log.info("UIActivityReturnSystemTabBtn:TabBtnOnClick, index = ", self._index)
    if self._callback then
        self._callback(self._index)
    end
end
--endregion

function UIActivityReturnSystemTabBtn:ShowHideRoot(isBoostIntro)
    if isBoostIntro then
        local root = self:GetGameObject("TabBtn")
        root:SetActive(false)
    end
end
