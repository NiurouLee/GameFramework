---@class UIQuestAwardsInfoItem:UICustomWidget
_class("UIQuestAwardsInfoItem", UICustomWidget)
UIQuestAwardsInfoItem = UIQuestAwardsInfoItem

function UIQuestAwardsInfoItem:OnShow(uiParams)
    -- self._module = GameGlobal.GetModule(ItemModule)
    -- if self._module == nil then
    --     Log.fatal("[quest] error --> itemModule is nil !")
    -- end
end

function UIQuestAwardsInfoItem:SetData(index, reward, callback)
    self:_GetComponents()

    self._index = index
    self._reward = reward
    self._id = reward.assetid
    self._callback = callback

    self:_OnValue()
end

function UIQuestAwardsInfoItem:OnHide()
end

function UIQuestAwardsInfoItem:_GetComponents()
    --self._nameTex = self:GetUIComponent("UILocalizationText", "nameTex")
    self._item = self:GetUIComponent("UISelectObjectPath", "item")
end

function UIQuestAwardsInfoItem:_OnValue()
    -- local cfg_item = Cfg.cfg_item[self._id]
    -- if cfg_item == nil then
    --     Log.fatal("[quest] error --> cfg_item is nil ! id --> " .. self._id)
    --     return
    -- end
    --self._nameTex:SetText(StringTable.Get(cfg_item.Name))
    ---@type UIQuestBigAwardItem
    local award = self._item:SpawnObject("UIQuestBigAwardItem")
    award:SetData(self._index, self._reward, self._callback, true)
end
