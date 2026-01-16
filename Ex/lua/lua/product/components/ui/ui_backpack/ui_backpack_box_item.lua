---@class UIBackPackBoxItem : UICustomWidget
_class("UIBackPackBoxItem", UICustomWidget)
UIBackPackBoxItem = UIBackPackBoxItem

function UIBackPackBoxItem:OnShow(uiParams)
    ---@type UICustomWidgetPool
    local sop = self:GetUIComponent("UISelectObjectPath", "uiitem")
    ---@type UIItem
    self.uiItem = sop:SpawnObject("UIItem")
    self.uiItem:SetForm(UIItemForm.Base)
    self.uiItem:SetClickCallBack(
        function()
            self:itemOnClick()
        end
    )
end

function UIBackPackBoxItem:OnHide()
end

---@param itemInfo BackPackBoxItem 物品信息
---@param index number 下标
---@param clickCallback function 事件
function UIBackPackBoxItem:Flush(itemInfo, index, count, clickCallback)
    if not itemInfo then
        return
    end
    self._clickCallback = clickCallback
    self.uiItem:SetData(
        {
            icon = itemInfo:GetIcon(),
            quality = itemInfo:GetColor(),
            text1 = HelperProxy:GetInstance():FormatItemCount(itemInfo:GetCount() * count),
            itemId = itemInfo:GetTplId(),
            showNew = false
        }
    )
    self.uiItem:SetBtnImage(true)
end

function UIBackPackBoxItem:FlushEmpty()
    self.uiItem:SetData({text1 = "", icon = "", quality = 0, showNew = false})
    self.uiItem:SetBtnImage(false)
    self._clickCallback = nil
end

--点击
function UIBackPackBoxItem:itemOnClick()
    if self._clickCallback then
        self._clickCallback()
    end
end
