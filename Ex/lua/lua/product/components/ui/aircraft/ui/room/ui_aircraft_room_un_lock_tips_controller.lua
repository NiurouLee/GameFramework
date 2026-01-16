---@class UIAircraftRoomUnLockTipsController:UIController
_class("UIAircraftRoomUnLockTipsController", UIController)
UIAircraftRoomUnLockTipsController = UIAircraftRoomUnLockTipsController

function UIAircraftRoomUnLockTipsController:OnShow(uiParams)
    self:_GetComponents()
    local spaceid = uiParams[1]
    self._module = self:GetModule(AircraftModule)
    self._buildArray = self._module:GetBuildTypeSorted(spaceid)
    local buildID = self:BuildType2BuildID(self._buildArray[1].BuildType)
    self._room_cfg = Cfg.cfg_aircraft_room[buildID]
    self:_OnValue()
end
function UIAircraftRoomUnLockTipsController:BuildType2BuildID(type)
    local cfg = Cfg.cfg_aircraft_room {RoomType = type, Level = 1}
    if cfg then
        return cfg[1].ID
    end
end
function UIAircraftRoomUnLockTipsController:_GetComponents()
    self._roomName = self:GetUIComponent("UILocalizationText", "roomName")
    self._roomDesc = self:GetUIComponent("UILocalizationText", "roomDesc")
    self._icon = self:GetUIComponent("RawImageLoader", "icon")
end
function UIAircraftRoomUnLockTipsController:_OnValue()
    local roomName = self._room_cfg.Name

    local roomCount = self._buildArray[1].Count
    local roomCountUpper = self._buildArray[1].MaxNum
    self._roomName:SetText(
        StringTable.Get(roomName) ..
            " " .. roomCount .. "<color=#ff6b0d>/</color><color=#d5d5d5>" .. roomCountUpper .. "</color>"
    )
    local roomIcon = self._room_cfg.RoomTypeIcon2
    self._icon:LoadImage(roomIcon)
    local roomDesc = self._room_cfg.Description
    self._roomDesc:SetText(StringTable.Get(roomDesc))
end

function UIAircraftRoomUnLockTipsController:OnHide()
end
function UIAircraftRoomUnLockTipsController:bgOnClick()
    self:CloseDialog()
end
function UIAircraftRoomUnLockTipsController:infoOnClick()
    local roomType = self._buildArray[1].BuildType
    if roomType == AirRoomType.AisleRoom then --过道
    elseif roomType == AirRoomType.CentralRoom then --主控室
        self:ShowDialog("UIHelpController", "UIAircraftCentralRoom")
    elseif roomType == AirRoomType.PowerRoom then --能源室
        self:ShowDialog("UIHelpController", "UIAircraftPowerRoom")
    elseif roomType == AirRoomType.MazeRoom then --秘境室
        self:ShowDialog("UIHelpController", "UIAircraftMazeRoom")
    elseif roomType == AirRoomType.ResourceRoom then --资源室
        self:ShowDialog("UIHelpController", "UIAircraftResourceRoom")
    elseif roomType == AirRoomType.PrismRoom then --棱镜室
        self:ShowDialog("UIHelpController", "UIAircraftPrismRoom")
    elseif roomType == AirRoomType.TowerRoom then --灯塔室
        self:ShowDialog("UIHelpController", "UIAircraftTowerRoom")
    elseif roomType == AirRoomType.EvilRoom then --恶鬼室
    elseif roomType == AirRoomType.PurifyRoom then --净化室
    elseif roomType == AirRoomType.DispatchRoom then --派遣室
        self:ShowDialog("UIHelpController", "UIDispatchDetailController")
    elseif roomType == AirRoomType.SmeltRoom then
        self:ShowDialog("UIHelpController", "UIAircraftSmeltRoom")
    elseif roomType == AirRoomType.TacticRoom then
        self:ShowDialog("UIHelpController", "UIAircraftTactic")
    end
end
