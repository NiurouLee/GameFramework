--[[
    事件点(EventPoint)是赛季玩法的一个新概念：地图上所有的内容都是一个事件点。一个事件点会随着它的进度(Progress)有不同的表现(Express)，
    一个事件点的进度变化也会影响其它事件点(包括自身)的进度变化。
    地图上有大区(Zone)，每个区管理自己区的所有的事件点。
    地图上有日常关，日常关管理所有的日常关事件点
]]
---@class SeasonMapManager:Object
_class("SeasonMapManager", Object)
SeasonMapManager = SeasonMapManager

function SeasonMapManager:Constructor()
end

function SeasonMapManager:OnInit(seasonID, params)
    self._params = params --记录退出局内的时候一些结算数据
    ---@type SeasonMapEventPointLoader
    self._mapEventPointLoader = SeasonMapEventPointLoader:New(SeasonEventPointLoadType.Sync)
    ---@type SeasonMapZone[]
    self._zones = {} --当前赛季的每个区
    ---@type SeasonMapDaily
    self._daily = {} --当前赛季的日常关
    self._unlockZones = {1} --已经解锁的区域ID, 1区默认解锁
    self._mapIDs = {1, 2} --默认显示的地块
    self._loginModule = GameGlobal.GetModule(LoginModule)
    self._svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    ---@type SeasonModule
    self._seasonModule = GameGlobal.GetModule(SeasonModule)
    ---@type UISeasonModule
    self._uiSeasonModule = GameGlobal.GetUIModule(SeasonModule)
    self._sceneManager = self._uiSeasonModule:SeasonManager():SeasonSceneManager()
    local obj = self._seasonModule:GetCurSeasonObj()
    ---@type SeasonMissionComponent
    self._component = obj:GetComponent(ECCampaignSeasonComponentID.SEASON_MISSION)
    ---@type SeasonMissionComponentInfo
    self._componentInfo = self._component:GetComponentInfo()
    self._componentID = self._component:GetComponentCfgId()
    self:_CreateZones(self:_CalcUnLockZonesAndMapIDs())
    self:_CreateDaily()
end

function SeasonMapManager:Update(deltaTime)
    self._mapEventPointLoader:Update()
    for id, zone in ipairs(self._zones) do
        zone:Update(deltaTime)
    end
    self._daily:Update(deltaTime)
end

function SeasonMapManager:Dispose()
    for zoneID, zone in pairs(self._zones) do
        zone:Dispose()
    end
    self._daily:Dispose()
    table.clear(self._zones)
    table.clear(self._unlockZones)
    self._mapEventPointLoader:Dispose()
    self._mapEventPointLoader = nil
end

---局内结算信息
function SeasonMapManager:GetParams()
    return self._params
end

---@return SeasonMapDaily
function SeasonMapManager:Daily()
    return self._daily
end

function SeasonMapManager:_CalcUnLockZonesAndMapIDs()
    local closeID = nil
    local map = self._componentInfo.m_stage_info
    if map then
        for eventPointID, curProgress in pairs(map) do
            Log.info("SeasonMapManager eventPointID, progress", eventPointID, curProgress)
            local cfgMission = Cfg.cfg_season_mission[eventPointID]
            if cfgMission then
                if cfgMission.ZoneUnLock then
                    local count = #cfgMission.ZoneUnLock
                    local zoneID = cfgMission.ZoneUnLock[count]
                    for i = 1, count - 1 do
                        local progress = cfgMission.ZoneUnLock[i]
                        if curProgress == progress then
                            if not table.icontains(self._unlockZones, zoneID) then
                                table.insert(self._unlockZones, zoneID)
                            end
                        end
                    end
                end
                if cfgMission.MapID then
                    local openingID = cfgMission.MapID[1]
                    closeID = cfgMission.MapID[2]
                    table.insert(self._mapIDs, openingID)
                end
            end
        end
    end
    return closeID
end

---创建分区
function SeasonMapManager:_CreateZones(closeID)
    local cfgs = Cfg.cfg_component_season { ComponentID = self._componentID }
    if cfgs then
        for _, cfg in pairs(cfgs) do
            local cfgMission = Cfg.cfg_season_mission[cfg.MissionID]
            if cfgMission and cfgMission.ZoneID then
                if not self._zones[cfgMission.ZoneID] then
                    self._zones[cfgMission.ZoneID] = SeasonMapZone:New(cfgMission.ZoneID, self:IsUnLock(cfgMission.ZoneID), self._mapEventPointLoader)
                end
                self._zones[cfgMission.ZoneID]:AddEventPoint(cfgMission)
            end
        end
    end
    self:_UnLockZone() --初始化已经解锁的区
    self:_ChangeMap(nil, closeID) --初始化当前地图块
end

--某个区域是否解锁
function SeasonMapManager:IsUnLock(zoneID)
    return table.icontains(self._unlockZones, zoneID)
end

function SeasonMapManager:_UnLockZone(zoneID2Animation)
    local zoneMask = 0
    for _, zoneID in pairs(self._unlockZones) do
        if self._zones[zoneID] then
            self._zones[zoneID]:SetUnLock(true)
        end
        zoneMask = zoneMask | (1 << (zoneID - 1))
    end
    self._sceneManager:UnLockZone(zoneMask, zoneID2Animation)
    Log.info("SeasonMapManager InitUnlockZone zoneMask, zoneID2Animation, ", zoneMask, zoneID2Animation)
end

function SeasonMapManager:_ChangeMap(openingID, closeID)
    self._sceneManager:ChangeMap(self._mapIDs, openingID, closeID)
    Log.info("SeasonMapManager ChangeMap ids ", self._mapIDs)
end

function SeasonMapManager:ContainGroup(groupID)
    for zoneID, zone in pairs(self._zones) do
        local allEventPoints = zone:GetEventPoints()
        for key, eventPoint in pairs(allEventPoints) do
            if eventPoint:GroupID() == groupID then
                return true
            end
        end
    end
    return false
end

---当一个事件的进度发生变化就检测全地图所有事件的状态
function SeasonMapManager:OnEventPointProgressChange(eventPointID)
    local map = self._componentInfo.m_stage_info
    local cfgMission = Cfg.cfg_season_mission[eventPointID]
    if cfgMission then
        if cfgMission.ZoneUnLock then
            local count = #cfgMission.ZoneUnLock
            local zoneID = cfgMission.ZoneUnLock[count]
            for i = 1, count - 1 do
                local progress = cfgMission.ZoneUnLock[i]
                if map[cfgMission.ID] and map[cfgMission.ID] == progress then
                    if not table.icontains(self._unlockZones, zoneID) then
                        table.insert(self._unlockZones, zoneID)
                        self:_UnLockZone(zoneID)
                        Log.info("SeasonMapManager OnEventPointProgressChange zone unlock, ", zoneID)
                    end
                end
            end
        end
        if cfgMission.MapID then
            local openingID = cfgMission.MapID[1]
            local closeID = cfgMission.MapID[2]
            table.insert(self._mapIDs, openingID)
            self:_ChangeMap(openingID, closeID)
            Log.info("SeasonMapManager OnEventPointProgressChange add map, ", openingID)
        end
        self:CalcDailyState()
    end
    for zoneID, zone in pairs(self._zones) do
        zone:CheckEventPointCondition(map)
    end
    self._daily:CheckEventPointCondition(map)
    self._uiSeasonModule:SeasonManager():SeasonUIManager():Refresh()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnEventPointProgressChange, eventPointID)
end

---@return SeasonMapEventPoint
---@return number 区ID
function SeasonMapManager:GetEventPoint(id)
    for zoneID, zone in pairs(self._zones) do
        local eventPoint = zone:GetEventPoint(id)
        if eventPoint then
            return eventPoint, zoneID
        end
    end
    local eventPoint = self._daily:GetEventPoint(id)
    if eventPoint then
        return eventPoint, nil
    end
    return nil, nil
end

---根据事件点类型返回所有事件点
---@param eventPointType SeasonEventPointType
---@param force boolean false该接口只返回已经解锁和当前难度的事件点; true包含未解锁的以及所有难度的事件点
---@return SeasonMapEventPoint[]
function SeasonMapManager:GetEventPointsByType(eventPointType, force)
    local allEventPoints = nil
    if eventPointType == SeasonEventPointType.DailyLevel then
        if self._daily:IsUnLock() or force then
            local eventPoints_daily = self._daily:GetEventPointsByType(eventPointType, force)
            if not allEventPoints then
                allEventPoints = {}
            end
            if eventPoints_daily then
                for i = 1, #eventPoints_daily do
                    table.insert(allEventPoints, eventPoints_daily[i])
                end
            end
        end
    else
        for zoneID, zone in pairs(self._zones) do
            if zone:IsUnLock() or force then
                local eventPoints_zone = zone:GetEventPointsByType(eventPointType, force)
                if not allEventPoints then
                    allEventPoints = {}
                end
                if eventPoints_zone then
                    for i = 1, #eventPoints_zone do
                        table.insert(allEventPoints, eventPoints_zone[i])
                    end
                end
            end
        end
    end
    return allEventPoints
end

--切换关卡难度
---@param diff UISeasonLevelDiff
function SeasonMapManager:SwitchDiff(diff)
    for _, zone in pairs(self._zones) do
        if zone:IsUnLock() then
            zone:SwitchDiff(diff)
        end
    end
end

---是否有事件点正在播放表现
---@return boolean
function SeasonMapManager:EventPointPlaying()
    for zoneID, zone in pairs(self._zones) do
        local isPlaying, id = zone:EventPointPlaying()
        if isPlaying then
            Log.debug("SeasonMapManager Zone EventPointPlaying.", id)
            return true
        end
    end
    local isPlaying, id = self._daily:EventPointPlaying()
    if isPlaying then
        Log.debug("SeasonMapManager Daily EventPointPlaying.", id)
        return true
    end
    return false
end

---创建日常关
function SeasonMapManager:_CreateDaily()
    self._daily = SeasonMapDaily:New(self, self._componentID, self._mapEventPointLoader)
    self:CalcDailyState()
    local cfgs = Cfg.cfg_component_season { ComponentID = self._componentID }
    if cfgs then
        for _, cfg in pairs(cfgs) do
            local cfgMission = Cfg.cfg_season_mission[cfg.MissionID]
            if cfgMission and cfgMission.IsDailylevel then
                self._daily:AddEventPoint(cfgMission)
            end
        end
    end
    self._daily:TrySyncPRIDs(nil)
end

---日常关状态
function SeasonMapManager:CalcDailyState()
    local cfg = self._daily:ComponentCfg()
    if cfg then
        local curTime = self._svrTimeModule:GetServerTime() * 0.001
        local unlockTime = self._loginModule:GetTimeStampByTimeStr(cfg.UnlockTime, Enum_DateTimeZoneType.E_ZoneType_GMT)
        local closeTime = self._loginModule:GetTimeStampByTimeStr(cfg.CloseTime, Enum_DateTimeZoneType.E_ZoneType_GMT)
        --时间
        if curTime < unlockTime or curTime >= closeTime then
            self._daily:SetState(SeasonDailyState.Time)
            return
        end
        --所需关卡
        local passInfo = self._componentInfo.m_pass_mission_info[cfg.NeedMission]
        if not passInfo then
            self._daily:SetState(SeasonDailyState.Mission)
            return
        end
        --最大次数
        local progress = self._componentInfo.m_daily_info.m_progress
        if progress > cfg.MaxReward then
            self._daily:SetState(SeasonDailyState.MaxReward)
            return
        end
        self._daily:SetState(SeasonDailyState.Unlock)
    else
        self._daily:SetState(SeasonDailyState.Lock)
    end
end