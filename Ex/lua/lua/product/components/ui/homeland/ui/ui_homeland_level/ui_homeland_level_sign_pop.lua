---@class UIHomelandLevelSignPop : UIController
_class("UIHomelandLevelSignPop", UIController)
UIHomelandLevelSignPop = UIHomelandLevelSignPop

---Constructor
function UIHomelandLevelSignPop:Constructor()
    self.mHomeland = GameGlobal.GetModule(HomelandModule)
    self.data = self.mHomeland:GetHomelandLevelData()
end

---OnShow
function UIHomelandLevelSignPop:OnShow(uiParams)
    ---@type UICustomWidgetPool
    self.Content = self:GetUIComponent("UISelectObjectPath", "Content")
    self:Flush()
end
---OnHide
function UIHomelandLevelSignPop:OnHide()
end
---Flush
function UIHomelandLevelSignPop:Flush()
    local levels = self.data.levels
    self.Content:SpawnObjects("UIHomelandLevelSignPopItem", #levels)
    ---@type UIHomelandLevelSignPopItem[]
    local uis = self.Content:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        local level = levels[i]
        ui:Flush(level)
    end
end

function UIHomelandLevelSignPop:bgOnClick(go)
    self:CloseDialog()
end
