---@class AircraftRoomExitLoadingHandler:LoadingHandler
_class("AircraftRoomExitLoadingHandler", LoadingHandler)
AircraftRoomExitLoadingHandler = AircraftRoomExitLoadingHandler

function AircraftRoomExitLoadingHandler:PreLoadBeforeLoadLevel(TT)
end

function AircraftRoomExitLoadingHandler:PreLoadAfterLoadLevel(TT, ...)
    LoadingHandler.PreLoadAfterLoadLevel(self, TT, ...)
end

function AircraftRoomExitLoadingHandler:OnLoadingFinish(...)
    local loadingParams = {...}
    local missionType = loadingParams[1]
    local missionId = loadingParams[2]
    if missionType == nil or missionId == nil then
        return
    end
    if missionType == 1 then --1：主线
        TaskManager:GetInstance():StartTask(
            function(TT)
                YIELD(TT, 1000)
                ---@type MissionModule
                local module = GameGlobal.GetModule(MissionModule)
                ---@type DiscoveryData
                local data = module:GetDiscoveryData()
                data:UpdatePosByEnter(3, missionId)
                GameGlobal.UIStateManager():SwitchState(UIStateType.UIDiscovery)
            end,
            self
        )
    elseif missionType == 2 then --2：番外
        -- GameGlobal.UIStateManager():SwitchState(UIStateType.UIExtraMission)
    elseif missionType == 3 then --3：资源本
        local module = GameGlobal.GetModule(ResDungeonModule)
        local clientResInstance = module:GetClientResInstance()
        local instanceId = missionId
        local mainType = clientResInstance:GetMainTypeByInstanceId(instanceId)
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIResDetailController, mainType)
    elseif missionType == 4 then --4: 完成任意主线
        TaskManager:GetInstance():StartTask(
            function(TT)
                YIELD(TT, 1000)
                ---@type MissionModule
                local module = GameGlobal.GetModule(MissionModule)
                ---@type DiscoveryData
                local data = module:GetDiscoveryData()
                data:UpdatePosByEnter(1)
                GameGlobal.UIStateManager():SwitchState(UIStateType.UIDiscovery)
            end,
            self
        )
    elseif missionType == 5 then --5: 完成任意资源本
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIResEntryController)
    end
end

function AircraftRoomExitLoadingHandler:LoadingType()
    return LoadingType.BOTTOM
end
