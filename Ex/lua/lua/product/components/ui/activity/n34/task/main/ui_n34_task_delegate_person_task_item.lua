---@class UIN34TaskDelegatePersonTaskItem : UICustomWidget
_class("UIN34TaskDelegatePersonTaskItem", UICustomWidget)
UIN34TaskDelegatePersonTaskItem = UIN34TaskDelegatePersonTaskItem

function UIN34TaskDelegatePersonTaskItem:OnShow(uiParams)
    self._nameLabel = self:GetUIComponent("UILocalizationText", "Name")
    self._costLabel = self:GetUIComponent("UILocalizationText", "Cost")
    self._desLabel = self:GetUIComponent("UILocalizationText", "Des")
    self._selected = self:GetGameObject("Selected")
    self._iconLoader = self:GetUIComponent("RawImageLoader", "Icon")
    self._rewardLoader = self:GetUIComponent("UISelectObjectPath", "Rewards")
    self._go = self:GetGameObject()
end

---@param data UIActivityN34DelegateTaskData
function UIN34TaskDelegatePersonTaskItem:SetData(data, isSelected, callback, itemClickCallback)
    if not data then
        self._go:SetActive(false)
        return
    end
    self._go:SetActive(true)
    ---@type UIActivityN34DelegateTaskData
    self._data = data
    self._callback = callback
    self._nameLabel:SetText(data:GetName())
    self._iconLoader:LoadImage(data:GetIcon())
    self._costLabel:SetText(data:GetCost())
    self._desLabel:SetText("-" .. data:GetDes())
    self._selected:SetActive(isSelected)
    local rewards = data:GetRewards()
    local trust = data:GetTrustValue()
    self._rewardLoader:SpawnObjects("UIN34TaskDelegatePersonTaskReward", #rewards)
    local items = self._rewardLoader:GetAllSpawnList()
    for i = 1, #items do
        -- if i == 1 then
        --     items[i]:SetData(true, {assetid = 0, count = trust})
        -- else
        --     items[i]:SetData(false, rewards[i - 1])
        -- end
        items[i]:SetData(false, rewards[i], function(id, pos)
            if itemClickCallback then
                itemClickCallback(id, pos)
            end
        end)
    end
end

function UIN34TaskDelegatePersonTaskItem:GetData()
    return self._data
end

function UIN34TaskDelegatePersonTaskItem:Select()
    self._selected:SetActive(true)
end

function UIN34TaskDelegatePersonTaskItem:UnSelect()
    self._selected:SetActive(false)
end

function UIN34TaskDelegatePersonTaskItem:BGOnClick()
    if self._callback then
        self._callback(self._data)
    end
end
