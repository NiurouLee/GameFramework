--N25 入口按钮基础功能
---@class UIN25EntryBtnBase : UICustomWidget
_class("UIN25EntryBtnBase", UICustomWidget)
UIN25EntryBtnBase = UIN25EntryBtnBase

--初始化
function UIN25EntryBtnBase:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UIN25EntryBtnBase:InitWidget()
    --generated--
    ---@type UnityEngine.GameObject
    self.lockNode = self:GetGameObject("lockNode")
    ---@type RollingText
    self.txtLeftTime = self:GetUIComponent("RollingText", "txtLeftTime")
    ---@type UnityEngine.GameObject
    self.red = self:GetGameObject("red")
    ---@type UnityEngine.GameObject
    self.new = self:GetGameObject("new")
    
    self.leftTime = self:GetGameObject("leftTime")
    --generated end--
end

--设置数据
function UIN25EntryBtnBase:SetData(clickCall)
    self.clickCallback = clickCall
end

---@return RollingText
function UIN25EntryBtnBase:GetLeftTimeWiget()
    return self.txtLeftTime
end

function UIN25EntryBtnBase:SetLeftTime(strTime)
    self.txtLeftTime:RefreshText(strTime)
end

function UIN25EntryBtnBase:SetLeftTimeShow(show)
    self.leftTime:SetActive(show)
end

function UIN25EntryBtnBase:SetLock(lock)
    self.lockNode:SetActive(lock)
end

function UIN25EntryBtnBase:SetNewAndRed(new, red)
    self.new:SetActive(new)
    self.red:SetActive(not new and red)
end

--按钮点击
function UIN25EntryBtnBase:ItemBtnOnClick(go)
    if self.clickCallback then
        self.clickCallback()
    end
end

