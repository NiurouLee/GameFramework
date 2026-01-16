---@class UIQuestBigAwardItem:UICustomWidget
_class("UIQuestBigAwardItem", UICustomWidget)
UIQuestBigAwardItem = UIQuestBigAwardItem

function UIQuestBigAwardItem:OnShow(uiParams)
end

function UIQuestBigAwardItem:SetData(index, data, callback, showName)
    local sop = self:GetUIComponent("UISelectObjectPath", "uiitem")
    ---@type UIItem
    self.uiItem = sop:SpawnObject("UIItem")
    self.uiItem:SetForm(UIItemForm.Base)
    self.uiItem:SetClickCallBack(
        function(go)
            self:bgOnClick(go)
        end
    )
    self._index = index
    self._data = data
    self._callback = callback
    self._itemid = data.assetid
    self._itemCount = data.count
    self._showName = showName
    self:_OnValue()
end

function UIQuestBigAwardItem:_OnValue()
    local cfg = Cfg.cfg_item[self._itemid]
    if cfg == nil then
        Log.fatal("[quest] error --> cfg_item is nil ! id --> " .. self._itemid)
    end
    local icon = cfg.Icon
    local quality = cfg.Color
    local text1 = self._itemCount
    local text2 = self._showName and StringTable.Get(cfg.Name) or ""
    self.uiItem:SetData({icon = icon, quality = quality, text1 = text1, text2 = text2, itemId = self._itemid})
end

function UIQuestBigAwardItem:bgOnClick(go)
    if self._callback then
        self._callback(self._itemid, go.transform.position)
    end
end
