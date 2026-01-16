---@class UIQuestGrowthQuestBGItem:UICustomWidget
_class("UIQuestGrowthQuestBGItem", UICustomWidget)
UIQuestGrowthQuestBGItem = UIQuestGrowthQuestBGItem

function UIQuestGrowthQuestBGItem:OnShow()
    self._questList = self:GetUIComponent("UISelectObjectPath", "item")
    self._awardsList = self:GetUIComponent("UISelectObjectPath", "itemAward")
end

function UIQuestGrowthQuestBGItem:OnHide()
end

---@param idx number idx∈[1,3]
---@param datas Quest[]
function UIQuestGrowthQuestBGItem:Flush(idx, datas, RefrenshList, anim)
    self._questList:SpawnObjects("UIQuestGrowthQuestItem", 3)
    ---@type UIQuestGrowthQuestItem[]
    local quests = self._questList:GetAllSpawnList()
    for index, quest in ipairs(quests) do
        local i = (idx - 1) * 3 + index --index∈[1,3]
        local data = datas[i]
        if data then
            quest:SetData(i, data, nil, anim)
        else
            Log.fatal("### no data in datas. i=", i)
        end
    end
    --奖励
    local gridCount = 9
    self._awardsList:SpawnObjects("UIQuestGrowthAwardItem", 1)
    ---@type UIQuestGrowthAwardItem
    local award = self._awardsList:GetAllSpawnList()[1]
    local i = idx + gridCount
    ---@type Quest
    local data = datas[i]
    if data then
        award:SetData(
            idx,
            data,
            function()
                RefrenshList()
            end,
            anim
        )
    else
        Log.warn("### datas idx nil", i)
        award:SetDataTaken(idx)
    end
end
