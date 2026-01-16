---@class UILostLandWeekInfoController : UIController
_class("UILostLandWeekInfoController", UIController)
UILostLandWeekInfoController = UILostLandWeekInfoController
--[[
    本周推荐星灵
]]
function UILostLandWeekInfoController:OnShow(uiParams)
    ---@type UILostLandModule
    self._uiModule = GameGlobal.GetUIModule(LostAreaModule)

    self:GetComponents()

    self:OnValue()
end

function UILostLandWeekInfoController:GetComponents()
    self._recommendPools = self:GetUIComponent("UISelectObjectPath", "recommendPools")
end

function UILostLandWeekInfoController:OnValue()
    self:GetFilterData()
end

function UILostLandWeekInfoController:bgOnClick(go)
    self:CloseDialog()
end

function UILostLandWeekInfoController:GetFilterData()
    local recommendList = self._uiModule:GetRecommendConditionList()

    self._recommendPools:SpawnObjects("UILostLandFilterItem", #recommendList)
    ---@type UILostLandFilterItem[]
    local pools = self._recommendPools:GetAllSpawnList()
    for i = 1, #pools do
        local item = pools[i]
        item:SetData(recommendList[i])
    end
end
