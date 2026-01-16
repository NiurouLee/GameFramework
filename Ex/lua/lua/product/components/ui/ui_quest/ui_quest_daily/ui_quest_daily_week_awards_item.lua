---@class UIQuestDailyWeekAwardsItem:UICustomWidget
_class("UIQuestDailyWeekAwardsItem", UICustomWidget)
UIQuestDailyWeekAwardsItem = UIQuestDailyWeekAwardsItem

function UIQuestDailyWeekAwardsItem:OnShow(uiParams)
    -- self._module = GameGlobal.GetModule(ItemModule)
    -- if self._module == nil then
    --     Log.fatal("[quest] error --> itemModule is nil !")
    -- end
end

function UIQuestDailyWeekAwardsItem:SetData(index,reward, callback)
    self:_GetComponents()

    self._index = index
    self._reward = reward
    self._id = reward.assetid
    self._callback = callback

    self:_OnValue()
end

function UIQuestDailyWeekAwardsItem:OnHide()
end

function UIQuestDailyWeekAwardsItem:_GetComponents()
    --self._nameTex = self:GetUIComponent("UILocalizationText", "nameTex")
    self._item = self:GetUIComponent("UISelectObjectPath", "item")
end

function UIQuestDailyWeekAwardsItem:_OnValue()
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
