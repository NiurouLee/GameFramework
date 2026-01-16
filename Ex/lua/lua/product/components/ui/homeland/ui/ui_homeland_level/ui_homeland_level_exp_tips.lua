---@class UIHomelandLevelExpTips : UIController
_class("UIHomelandLevelExpTips", UIController)
UIHomelandLevelExpTips = UIHomelandLevelExpTips

---Constructor
function UIHomelandLevelExpTips:Constructor()
    --共4条信息
    self.itemCount = 4
end

---OnShow
function UIHomelandLevelExpTips:OnShow(uiParams)
    ---@type UICustomWidgetPool
    self.itemPool = self:GetUIComponent("UISelectObjectPath", "content")

    self:Flush()
end

---Flush
function UIHomelandLevelExpTips:Flush()
    self.itemPool:SpawnObjects("UIHomelandLevelExpTipsItem", self.itemCount)

    ---@type UIHomelandLevelExpTipsItem[]
    local items = self.itemPool:GetAllSpawnList()
    for i = 1, self.itemCount do
        items[i]:Flush(i)
    end
end

---bgOnClick
function UIHomelandLevelExpTips:bgOnClick(go)
    self:CloseDialog()
end
