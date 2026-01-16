--区
---@class SeasonMapZone:Object
_class("SeasonMapZone", Object)
SeasonMapZone = SeasonMapZone

function SeasonMapZone:Constructor(id, unlock, loader)
    self._zoneID = id
    self._isUnLock = unlock
    ---@type SeasonMapEventPointLoader
    self._loader = loader
    ---@type SeasonMapEventPoint[] 
    self._eventPoints = {} --该区域所有事件点
end

function SeasonMapZone:ZoneID()
    return self._zoneID
end

function SeasonMapZone:Update(deltaTime)
    for id, eventPoint in pairs(self._eventPoints) do
        eventPoint:Update(deltaTime)
    end
end

function SeasonMapZone:Dispose()
    for _, eventPoint in pairs(self._eventPoints) do
        eventPoint:Dispose()
    end
    table.clear(self._eventPoints)
end

---添加一个zone的事件点
---@param cfgMission cfg_season_mission
function SeasonMapZone:AddEventPoint(cfgMission)
    if not cfgMission then
        return
    end
    local missionID = cfgMission.ID
    if self._eventPoints[missionID] then
        return
    end
    local cfgEventPoint = Cfg.cfg_season_map_eventpoint[missionID]
    if cfgEventPoint then
        ---@type SeasonMapEventPoint
        local eventPoint = SeasonMapEventPoint:New(self, cfgMission, cfgEventPoint)
        if eventPoint:GetResName() then
            self._loader:LoadResource(eventPoint)
        else
            eventPoint:CreateVirtualPoint()
        end
        self._eventPoints[missionID] = eventPoint
    end
end

---@return SeasonMapEventPoint
function SeasonMapZone:GetEventPoint(id)
    return self._eventPoints[id]
end

function SeasonMapZone:GetEventPoints()
    return self._eventPoints
end

function SeasonMapZone:IsUnLock()
    return self._isUnLock
end

function SeasonMapZone:SetUnLock(unlock)
    self._isUnLock = unlock
end

function SeasonMapZone:CheckEventPointCondition(map)
    if self._isUnLock then
        for id, eventPoint in pairs(self._eventPoints) do
            local result, progress = eventPoint:CheckCondition(map)
            if result then
                eventPoint:PlayExpress(progress, SeasonExpressTriggerType.Passive)
            end
        end
    end
end

---@param eventPointType SeasonEventPointType
function SeasonMapZone:GetEventPointsByType(eventPointType, force)
    local result = nil
    for _, eventPoint in pairs(self._eventPoints) do
        if eventPoint:EventPointType() == eventPointType and (eventPoint:DiffAble() or force) then
            if not result then
                result = {}
            end
            table.insert(result, eventPoint)
        end
    end
    return result
end

---@param diff UISeasonLevelDiff
function SeasonMapZone:SwitchDiff(diff)
    for _, eventPoint in pairs(self._eventPoints) do
        if eventPoint:IsUnLock() then
            eventPoint:SwitchDiff(diff)
        end
    end
end

function SeasonMapZone:EventPointPlaying()
    for _, eventPoint in pairs(self._eventPoints) do
        local isPlaying, id = eventPoint:IsPlaying()
        if isPlaying then
            return isPlaying, id
        end
    end
    return false, nil
end