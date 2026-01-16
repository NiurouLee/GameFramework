
--- @class N34TerminalItemState
N34TerminalItemStatus = {
    NotStart = 0, --派遣未开始
    Going = 1,--派遣进行中
    End = 2--派遣结束
}
_enum("N34TerminalItemStatus", N34TerminalItemStatus)

---@class UIN34DispatchTerminalMainItem : UICustomWidget
_class("UIN34DispatchTerminalMainItem", UICustomWidget)
UIN34DispatchTerminalMainItem = UIN34DispatchTerminalMainItem
--初始化
function UIN34DispatchTerminalMainItem:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIN34DispatchTerminalMainItem:InitWidget()
    --generated--
    ---@type UnityEngine.UI.Image
    self._title = self:GetUIComponent("UILocalizationText", "Title")
    ---@type UnityEngine.UI.Image
    self._award = self:GetUIComponent("Image", "Award")
    ---@type UnityEngine.UI.Image
    self._state = self:GetUIComponent("Image", "state")
    ---@type UnityEngine.UI.Image
    self._select = self:GetUIComponent("Image", "Select")
    --generated end--
end
--设置数据
function UIN34DispatchTerminalMainItem:SetData(Info, ID, name, AwardClick, ItemSelect)
    self.info = Info
    self.id = ID
    self.name = name
    self.awardClick = AwardClick
    self.itemSelect = ItemSelect

    self._title:SetText(self.name)
    self:SetStatus(self.info)
end

function UIN34DispatchTerminalMainItem:SetStatus(Info)
    if not Info then
        self._status = N34TerminalItemStatus.NotStart
        self._state.color = Color.New(0/255, 0/255, 0/ 255, 255/255)
    else
        self._status = Info.status
    end
end

function UIN34DispatchTerminalMainItem:SetSelected(bool)
    self._select.gameObject:SetActive(bool)
end

function UIN34DispatchTerminalMainItem:GetDispatchID()
    return self.id
end

function UIN34DispatchTerminalMainItem:GetStatus()
    return self._status
end


--按钮点击
function UIN34DispatchTerminalMainItem:AwardOnClick(go)
    if self.awardClick then
        self.awardClick(self.id)
    end
    self:SelectBtnOnClick()
end

--按钮点击
function UIN34DispatchTerminalMainItem:SelectBtnOnClick()
    if self.itemSelect then
        self:itemSelect(self)
    end
end



