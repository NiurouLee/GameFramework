--
---@class UIN28HardLevelBtn : UICustomWidget
_class("UIN28HardLevelBtn", UICustomWidget)
UIN28HardLevelBtn = UIN28HardLevelBtn

--初始化
function UIN28HardLevelBtn:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UIN28HardLevelBtn:InitWidget()
    self._bg = self:GetUIComponent("Image", "bg")
    self.select = self:GetUIComponent("Image", "select")
    self.unSelect = self:GetUIComponent("Image", "unSelect")
    self.locker = self:GetUIComponent("Image", "locker")
    self.logName = self:GetUIComponent("UILocalizationText", "logName")
    ---@type UnityEngine.RectTransform
    self.rootRt = self:GetUIComponent("RectTransform","rootRt")

    ---@type UnityEngine.UI.Button
    self.levelBtn = self:GetUIComponent("Button", "rootRt")
end

--设置数据
function UIN28HardLevelBtn:SetData(atlas, logName, clickCallback)
    self.atlas = atlas
    self.clickCallback = clickCallback

    local bgSpriteName = nil
    local btnSpriteName = nil
    local maskSpriteName = nil
    local lockSpriteName = nil
    local multiLangaugeName = nil
    if logName == 1 then
        bgSpriteName = "n28_kng_btn02"
        btnSpriteName = "n28_kng_btn04"
        maskSpriteName = "n28_kng_mask02"
        lockSpriteName = "n28_kng_lock01"
        multiLangaugeName = "str_n28_hard_level_btn01"
    else
        bgSpriteName = "n28_kng_btn03"
        btnSpriteName = "n28_kng_btn05"
        maskSpriteName = "n28_kng_mask02"
        lockSpriteName = "n28_kng_lock01"
        multiLangaugeName = "str_n28_hard_level_btn02"
    end

    self._bg.sprite = atlas:GetSprite(bgSpriteName)
    self.select.sprite = atlas:GetSprite(btnSpriteName)
    self.unSelect.sprite = atlas:GetSprite(maskSpriteName)
    self.locker.sprite = atlas:GetSprite(lockSpriteName)
    self.logName:SetText(StringTable.Get(multiLangaugeName))

    self:SetLockVisible(false)
end

function UIN28HardLevelBtn:SetLockVisible(bVisible)
    if self.locker then
        self.locker.gameObject:SetActive(bVisible)
    end

    self.isLock = bVisible
end

function UIN28HardLevelBtn:SetSelect(bSelect, localPosition)
    self.unSelect.gameObject:SetActive(not bSelect)

    if localPosition then
        self.rootRt.localPosition = localPosition
    end

    self.levelBtn.interactable = not bSelect
end


function UIN28HardLevelBtn:LevelBtnOnClick(go)
    if self.clickCallback then
        self.clickCallback()
    end
end