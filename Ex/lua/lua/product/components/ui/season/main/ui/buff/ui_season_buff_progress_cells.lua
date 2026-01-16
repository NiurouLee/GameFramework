---@class UISeasonBuffProgressCells:UICustomWidget
_class("UISeasonBuffProgressCells", UICustomWidget)
UISeasonBuffProgressCells = UISeasonBuffProgressCells

function UISeasonBuffProgressCells:OnShow(uiParams)
    ---@type UICustomWidgetPool
    self.progressCellGen = self:GetUIComponent("UISelectObjectPath", "CellGen")
end
--设置数据
function UISeasonBuffProgressCells:SetData(progress,curMaxProgress)
    local count = curMaxProgress or 3
    self.progressCellGen:SpawnObjects("UISeasonBuffProgressCell",count)
    ---@type UISeasonBuffProgressCell[]
    self._cells = self.progressCellGen:GetAllSpawnList()
    for i, v in ipairs(self._cells) do
        v:SetData(i,i <= progress)
    end
end
-- function UISeasonBuffProgressCells:RefreshInfo(progress,curMaxProgress)
--     local count = curMaxProgress or 3
--     self.progressCellGen:SpawnObjects("UISeasonBuffProgressCell",count)
--     if self._cells then
--         for i, v in ipairs(self._cells) do
--             v:SetData(i,i <= progress)
--         end
--     end
-- end