_class("UIBackPackBox", UIController)
---@class UIBackPackBox : UIController
UIBackPackBox = UIBackPackBox

function UIBackPackBox:Constructor()
end

function UIBackPackBox:Dispose()
end

function UIBackPackBox:OnShow(uiParams)
    self:AttachEvent(GameEventType.CloseUIBackPackBox, self.bgOnClick)
    ---@type UILocalizationText
    self._txtName = self:GetUIComponent("UILocalizationText", "txtName")
    ---@type UICustomWidgetPool
    local Content = self:GetUIComponent("UISelectObjectPath", "Content")

    ---@type Item
    self._item = uiParams[1] --自选礼包自身
    self._count = uiParams[2] --自选礼包数量
    self._txtName:SetText(StringTable.Get(self._item:GetTemplate().Name))
    local lst = self:GetItemList(self._item:GetTemplateID())
    self._itemList = {}
    for i, item in ipairs(lst) do
        local tplId = item[1]
        local count = item[2]
        self._itemList[i] = BackPackBoxItem:New(tplId, count)
    end
    local len = table.count(self._itemList)
    local lenShow = 0
    if len <= 8 then --最少显示8个
        lenShow = 8
    else
        lenShow = 8 + math.ceil((len - 8) / 4)
    end
    Content:SpawnObjects("UIBackPackBoxItem", lenShow)
    ---@type UIBackPackBoxItem[]
    local uiItems = Content:GetAllSpawnList()
    for i, uiItem in ipairs(uiItems) do
        if i <= len then
            uiItem:Flush(
                self._itemList[i],
                i,
                self._count,
                function()
                    self:ShowUIBackPackBoxGain(i)
                end
            )
        else
            uiItem:FlushEmpty()
        end
    end
end

function UIBackPackBox:OnHide()
    self:DetachEvent(GameEventType.CloseUIBackPackBox, self.bgOnClick)
end

function UIBackPackBox:bgOnClick()
    self:CloseDialog()
end

function UIBackPackBox:ShowUIBackPackBoxGain(idx)
    self:ShowDialog("UIBackPackBoxGain", self._item:GetID(), self._count, self._itemList[idx], idx - 1)
end

function UIBackPackBox:GetItemList(itemGiftID)
    local cfgItemGift = Cfg.cfg_item_gift[itemGiftID]
    if not cfgItemGift then
        return 0
    end
    local lst = cfgItemGift.ItemList
    return lst
end
