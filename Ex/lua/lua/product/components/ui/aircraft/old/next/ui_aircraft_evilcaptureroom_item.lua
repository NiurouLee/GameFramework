--@class UIAircraftEvilCaptureRoomItem : UICustomWidget
_class("UIAircraftEvilCaptureRoomItem", UICustomWidget)
UIAircraftEvilCaptureRoomItem = UIAircraftEvilCaptureRoomItem
function UIAircraftEvilCaptureRoomItem:OnShow(uiParams)
    self:InitWidget()
    self.roomInfoWidget = self.roomInfo:SpawnObject("UIAircraftRoomInfoItem")
end
--genarated
function UIAircraftEvilCaptureRoomItem:InitWidget()
    self.textSpiritCeiling = self:GetUIComponent("Text", "TextStoreCeiling")
    self.textFireflyRecover = self:GetUIComponent("Text", "TextEvilGrade")
    self.roomInfo = self:GetUIComponent("UISelectObjectPath", "RoomInfo")
    self.textName = self:GetUIComponent("UILocalizationText", "TextName")
end

--供主界面调用
function UIAircraftEvilCaptureRoomItem:Refresh(_roomData)
    ---@type AircraftRoomBase
    self.roomData = _roomData
    self:GetGameObject():SetActive(true)
    self.roomInfoWidget:SetData(self.roomData)
    self.textName.text = string.format("%s/%s", self.roomData:Level(), self.roomData:MaxLevel())
end

--供主界面调用
function UIAircraftEvilCaptureRoomItem:Close()
    self:GetGameObject():SetActive(false)
    self.roomInfoWidget:OnClose()
end

function UIAircraftEvilCaptureRoomItem:ButtonSearchOnClick(go)
end
