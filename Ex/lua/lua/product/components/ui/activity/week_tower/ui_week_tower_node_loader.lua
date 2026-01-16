---@class UIWeekTowerNodeLoader : UICustomWidget
_class("UIWeekTowerNodeLoader", UICustomWidget)
UIWeekTowerNodeLoader = UIWeekTowerNodeLoader

function UIWeekTowerNodeLoader:OnShow(uiParams)
end

---@param data WeekTowerMissionData
function UIWeekTowerNodeLoader:SetData(index, missionCount, data, callback,width)
    self:DisposeCustomWidgets()
    
    ---@type UISelectObjectPath
    local pool = self:GetUIComponent("UISelectObjectPath","pool")    
    pool.dynamicInfoOfEngine:SetObjectName(data:GetWidgetName()..".prefab")
    ---@type UIWeekTowerNodeItem
    local widget = pool:SpawnObject("UIWeekTowerNodeItem")
    widget:SetData(index, missionCount, data, callback,width)
end
function UIWeekTowerNodeLoader:Active(active)
    self:GetGameObject():SetActive(active)
end