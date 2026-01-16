--@class UIAircraftEvilResearchRoomItem : UICustomWidget
_class("UIAircraftEvilResearchRoomItem", UICustomWidget)
UIAircraftEvilResearchRoomItem = UIAircraftEvilResearchRoomItem
function UIAircraftEvilResearchRoomItem:OnShow(uiParams)
    self:InitWidget()
    self.roomInfoWidget = self.roomInfo:SpawnObject("UIAircraftRoomInfoItem")
end
--genarated
function UIAircraftEvilResearchRoomItem:InitWidget()
    self.textResearchTime = self:GetUIComponent("Text", "TextResearchTime")
    self.roomInfo = self:GetUIComponent("UISelectObjectPath", "RoomInfo")
    self.textName = self:GetUIComponent("UILocalizationText", "TextName")
end

--供主界面调用
function UIAircraftEvilResearchRoomItem:Refresh(_roomData)
    ---@type AircraftRoomBase
    self.roomData = _roomData
    self:GetGameObject():SetActive(true)
    self.roomInfoWidget:SetData(self.roomData)
    self.textName.text = string.format("%s/%s", self.roomData:Level(), self.roomData:MaxLevel())
end

--供主界面调用
function UIAircraftEvilResearchRoomItem:Close()
    self:GetGameObject():SetActive(false)
    self.roomInfoWidget:OnClose()
end

function UIAircraftEvilResearchRoomItem:ButtonSearchOnClick(go)
end
