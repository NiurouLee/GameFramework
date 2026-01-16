--
---@class UIN25HardLevelBtn : UICustomWidget
_class("UIN25HardLevelBtn", UICustomWidget)
UIN25HardLevelBtn = UIN25HardLevelBtn

--初始化
function UIN25HardLevelBtn:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UIN25HardLevelBtn:InitWidget()
    ---@type UnityEngine.GameObject
    self.select = self:GetGameObject("select")
    ---@type UnityEngine.GameObject
    self.unSelect = self:GetGameObject( "unSelect")
    ---@type UnityEngine.GameObject
    self.locker = self:GetGameObject("locker")

    ---@type UnityEngine.UI.RawImage
    self.logName = self:GetUIComponent("RawImage", "logName")

    self.logNameLoader = self:GetUIComponent("RawImageLoader", "logName")

    ---@type UnityEngine.RectTransform
    self.rootRt = self:GetUIComponent("RectTransform","rootRt")

    ---@type UnityEngine.UI.Button
    self.levelBtn = self:GetUIComponent("Button", "rootRt")
end

--设置数据
function UIN25HardLevelBtn:SetData(logName, clickCallback)
    self.clickCallback = clickCallback
    self:SetLockVisible(false)
    self.logNameLoader:LoadImage(logName)
end

function UIN25HardLevelBtn:SetLockVisible(bVisible)
    if self.locker then
        self.locker:SetActive(bVisible)
    end
    self.isLock = bVisible
end

function UIN25HardLevelBtn:SetSelect(bSelect, localPosition)
    self.select:SetActive(bSelect)
    self.unSelect:SetActive(not bSelect)
    local color = self.logName.color
    if bSelect then
        color.a = 1
    else
        color.a = 0.5
    end
    -- if localPosition then
    --     self.rootRt.localPosition = localPosition
    -- end
    self.levelBtn.interactable = not bSelect
end


function UIN25HardLevelBtn:LevelBtnOnClick(go)
    if self.clickCallback then
        self.clickCallback()
    end
end