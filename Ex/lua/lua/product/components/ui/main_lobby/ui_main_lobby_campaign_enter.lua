---@class UIMainLobbyCampaignEnter:UICustomWidget
_class("UIMainLobbyCampaignEnter", UICustomWidget)
UIMainLobbyCampaignEnter = UIMainLobbyCampaignEnter

function UIMainLobbyCampaignEnter:Flush(controller, latestCampObj)
    local oneBtnMode = true

    ---@type UIMainLobbyController
    self._uiMainLobbyController = controller -- 传入 UIMainLobbyController 用来截图

    ---@type CampaignObj
    self._latestCampObj = latestCampObj

    local sampleInfo = self._latestCampObj:GetSampleInfo()
    local campConfig = Cfg.cfg_campaign[sampleInfo.id]

    -----------------------------------------------------------------
    -- 每个活动定义自己的入口，这里只负责spawn
    if campConfig and campConfig.EntranceIcon and table.count(campConfig.EntranceIcon) >= 3 then
        local entryPrefab = campConfig.EntranceIcon[2]
        local entryClass = campConfig.EntranceIcon[3]

        if entryPrefab and entryClass then
            local obj = UIWidgetHelper.SpawnObject(self, "EntryLoader", entryClass, entryPrefab)
            if controller and obj.SetData_uiMainLobbyController then
                obj:SetData_uiMainLobbyController(self._uiMainLobbyController)
            end
            oneBtnMode = false
        end
    end

    return oneBtnMode
end
