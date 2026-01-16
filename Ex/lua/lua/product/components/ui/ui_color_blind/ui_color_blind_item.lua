---@class UIColorBlindItem:UICustomWidget
_class("UIColorBlindItem", UICustomWidget)
UIColorBlindItem = UIColorBlindItem

function UIColorBlindItem:OnShow()
    ---@type RawImageLoader
    self.img = self:GetUIComponent("RawImageLoader", "img")
    ---@type UnityEngine.UI.Image
    self.imgSelect = self:GetUIComponent("Image", "imgSelect")
    ---@type UILocalizationText
    self.txtName = self:GetUIComponent("UILocalizationText", "txtName")

    self:AttachEvent(GameEventType.ColorBlindSelect, self.FlushSelect)
end

function UIColorBlindItem:OnHide()
    self:DetachEvent(GameEventType.ColorBlindSelect, self.FlushSelect)
end

function UIColorBlindItem:Flush(idx, clickCallback)
    self.idx = idx
    self.clickCallback = clickCallback
    local picPre = "install_blind_tu"
    self.img:LoadImage(picPre .. idx)
    self.txtName:SetText(StringTable.Get("str_set_color_blind_" .. idx))
    local colorBlindCode = UIPropertyHelper:GetInstance():GetColorBlindStyle()
    self:FlushSelect(colorBlindCode)
end

function UIColorBlindItem:FlushSelect(idx)
    self.imgSelect.gameObject:SetActive(self.idx == idx)
end

function UIColorBlindItem:imgOnClick(go)
    if self.clickCallback then
        self.clickCallback()
    end
end
