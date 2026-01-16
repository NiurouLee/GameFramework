---建造界面建筑item的prefab
---@class UIAircraftBuildPrefab : UICustomWidget
_class("UIAircraftBuildPrefab", UICustomWidget)
UIAircraftBuildPrefab = UIAircraftBuildPrefab

function UIAircraftBuildPrefab:OnShow(uiParams)
    self._icon = self:GetUIComponent("RawImageLoader", "Icon")
    self._buildName = self:GetUIComponent("UILocalizationText", "buildName")
    self._time = self:GetUIComponent("UILocalizationText", "time")
    self._count = self:GetUIComponent("UILocalizationText", "count")
    self._needPower = self:GetUIComponent("UILocalizationText", "needPower")
    self._select = self:GetGameObject("select")
    self._select:SetActive(false)
    self._full = self:GetGameObject("full")
    self._lock = self:GetGameObject("lock")
    self._info = self:GetGameObject("info")
    self._lockText = self:GetUIComponent("UILocalizationText", "lockText")
end

function UIAircraftBuildPrefab:GetTimeStr(timeNum)
    local timeStr
    local hourStr
    local hour = math.modf(timeNum / 60)
    if hour > 0 then
        if hour < 10 then
            hourStr = "0" .. hour
        else
            hourStr = "" .. hour
        end
    end
    local minStr
    local min = timeNum % 60
    if min < 10 then
        minStr = "0" .. min
    else
        minStr = "" .. min
    end

    local secStr = "00"

    if hourStr ~= nil and hourStr ~= "" then
        timeStr = hourStr .. ":" .. minStr .. ":" .. secStr
    else
        timeStr = minStr .. ":" .. secStr
    end

    return timeStr
end

--[[

    --房间类型
    --- @class AirRoomType
    local AirRoomType = {
    AisleRoom = 10, --过道
    CentralRoom = 1, --主控室
    EvilRoom = 2, --恶鬼抓捕室
    EntertainRoom = 3, --娱乐室
    PowerRoom = 4, --能源室
    PurifyRoom = 5, --恶鬼研究所
    }
    _enum("AirRoomType", AirRoomType)
    ]]
---@class AircrafBuildData
---@param build AircrafBuildData 建筑类
function UIAircraftBuildPrefab:SetData(index, build, allBuildCount, callback, centralRoomID)
    self._build = build
    self._centralID = centralRoomID
    self._index = index
    self._allBuildCount = allBuildCount
    self._callback = callback

    self._buildName:SetText(StringTable.Get(self._build._name))
    local timeStr = self:GetTimeStr(self._build._upLvTime)
    self._time:SetText(timeStr)
    self._needPower:SetText(self._build._needPower)

    self._icon:LoadImage(self._build._icon)

    local lock, res = self:CanBuildOfRoomType(self._centralID)
    if lock then
        self._lock:SetActive(false)
    else
        self._lock:SetActive(true)
        self._lockText:SetText(res .. "")
    end

    --该建筑已经建设和上限---TODO
    local module = GameGlobal.GetModule(AircraftModule)
    if module then
        --根据建筑类型获得该建筑已经建设的数量
        local haveCount = self._build._nCount
        local countUpper = self._build._uCount

        self._count:SetText(haveCount .. "/" .. countUpper)

        if haveCount >= countUpper then
            self._isFull = true
        else
            self._isFull = false
        end

        self._full:SetActive(self._isFull)
    else
        ToastManager.ShowToast("aircraft module is nil!")
    end
end

--通过一个主控室的等级，来判断能不能建造某个建筑，能的话返回true，不能的话返回多少级能级
function UIAircraftBuildPrefab:CanBuildOfRoomType(centralID)
    local cfg_central = Cfg.cfg_aircraft_central_room {}
    if cfg_central[centralID] then
        if self._build._roomType == AirRoomType.AisleRoom then
            local temp = cfg_central[centralID].AisleLimit
            if table.count(cfg_central[centralID].AisleLimit) > 0 then
                return true
            else
                for i, v in HelperProxy:GetInstance():pairsByKeys(cfg_central) do
                    if table.count(v.AisleLimit) > 0 then
                        local cfg_aircraft_room = Cfg.cfg_aircraft_room[v.ID]
                        if cfg_aircraft_room then
                            return false, cfg_aircraft_room.Level
                        end
                    end
                end
            end
        elseif self._build._roomType == AirRoomType.PowerRoom then
            if table.count(cfg_central[centralID].PowerRoomLimit) > 0 then
                return true
            else
                for i, v in HelperProxy:GetInstance():pairsByKeys(cfg_central) do
                    if table.count(v.PowerRoomLimit) > 0 then
                        local cfg_aircraft_room = Cfg.cfg_aircraft_room[v.ID]
                        if cfg_aircraft_room then
                            return false, cfg_aircraft_room.Level
                        end
                    end
                end
            end
        elseif self._build._roomType == AirRoomType.EntertainRoom then
            if table.count(cfg_central[centralID].EntertainRoomLimit) > 0 then
                return true
            else
                for i, v in HelperProxy:GetInstance():pairsByKeys(cfg_central) do
                    if table.count(v.EntertainRoomLimit) > 0 then
                        local cfg_aircraft_room = Cfg.cfg_aircraft_room[v.ID]
                        if cfg_aircraft_room then
                            return false, cfg_aircraft_room.Level
                        end
                    end
                end
            end
        elseif self._build._roomType == AirRoomType.EvilRoom then
            if table.count(cfg_central[centralID].EvilRoomLimit) > 0 then
                return true
            else
                for i, v in HelperProxy:GetInstance():pairsByKeys(cfg_central) do
                    if table.count(v.EvilRoomLimit) > 0 then
                        local cfg_aircraft_room = Cfg.cfg_aircraft_room[v.ID]
                        if cfg_aircraft_room then
                            return false, cfg_aircraft_room.Level
                        end
                    end
                end
            end
        elseif self._build._roomType == AirRoomType.PurifyRoom then
            if table.count(cfg_central[centralID].PurifyRoomLimit) > 0 then
                return true
            else
                for i, v in HelperProxy:GetInstance():pairsByKeys(cfg_central) do
                    if table.count(v.PurifyRoomLimit) > 0 then
                        local cfg_aircraft_room = Cfg.cfg_aircraft_room[v.ID]
                        if cfg_aircraft_room then
                            return false, cfg_aircraft_room.Level
                        end
                    end
                end
            end
        end
    end
end

function UIAircraftBuildPrefab:infoOnClick(go)
end
function UIAircraftBuildPrefab:bgOnClick()
    if self._isFull then
    else
        if not self._isFull then
            if self._allBuildCount ~= 1 then
                self:ShowBuildInfo()
            end
        end
    end
end
function UIAircraftBuildPrefab:ShowBuildInfo()
    self:_callback()
    self._select:SetActive(true)
end

--取消激活
function UIAircraftBuildPrefab:CloseSelect()
    self._select:SetActive(false)
end
