---@class UIWeekTowerNodeItem : UICustomWidget
_class("UIWeekTowerNodeItem", UICustomWidget)
UIWeekTowerNodeItem = UIWeekTowerNodeItem

function UIWeekTowerNodeItem:OnShow(uiParams)
    self._type2pos = {[0] = -106, [1] = 106}
    self._type2size = {[1] = {[1] = Vector3(0.9,0.9,0.9),[2] = Vector3(1,1,1)},[2] = {[1] = Vector3(0.85,0.85,0.85),[2] = Vector3(1,1,1)}}

    ---@type UILostLandModule
    self._uiModule = GameGlobal.GetUIModule(LostAreaModule)
    self:GetComponents()

    self:AttachEvent(GameEventType.OnUIWeekTowerNodeItemClick, self.OnUIWeekTowerNodeItemClick)
end

function UIWeekTowerNodeItem:OnUIWeekTowerNodeItemClick(index)
    if self._index == index then
        self:Select(true)
    else
        self:Select(false)
    end
end

function UIWeekTowerNodeItem:Select(select)
    if select then
        self._scale.localScale = self._type2size[self._type][2]
    else
        self._scale.localScale = self._type2size[self._type][1]
    end
end

---@param data WeekTowerMissionData
function UIWeekTowerNodeItem:SetData(index, _missionCount, data, callback,width)
    self._index = index
    self._missionCount = _missionCount
    self._missionData = data
    self._callback = callback
    self._width = width
    self._upOrDown = self._missionData:GetNodeUpOrDown()
    self._showLineY = self._missionData:ShowLineY()

    self:OnValue()
end

function UIWeekTowerNodeItem:GetComponents()
    self._go = self:GetGameObject("rect")

    self._nameTex = self:GetUIComponent("UILocalizationText","name")
    self._nameTex2 = self:GetUIComponent("UILocalizationText","name2")

    self._lock = self:GetGameObject("lock")
    self._clean = self:GetGameObject("clean")

    self._lineY = self:GetGameObject("lineY")

    self._lineX1 = self:GetUIComponent("RectTransform", "lineX1")
    self._lineX2 = self:GetUIComponent("RectTransform", "lineX2")

    self._pos = self:GetUIComponent("RectTransform", "pos")

    --暂时自动加载
    -- self._icon = self:GetUIComponent("RawImageLoader","icon")
    -- self._iconMask = self:GetUIComponent("RawImageLoader","iconMask")
    self._iconMaskGo = self:GetGameObject("iconMask")
    self._scale = self:GetUIComponent("Transform","scale")
end

function UIWeekTowerNodeItem:Active(active)
    self._go:SetActive(active)
end

function UIWeekTowerNodeItem:OnValue()
    self._type = self._missionData:GetType()

    --self._icon,self._iconMask = self._missionData:GetIcon()

    local name = self._missionData:GetMissionName()
    self._nameTex:SetText(name)
    local name2 = self._missionData:GetMissionName2()
    self._nameTex2:SetText(name2)
    -- self._icon:LoadImage(self._icon)
    -- self._iconMask:LoadImage(self._iconMask)

    ---@type UILostLandMissionLockType
    local passState = self._missionData:GetPassTime()
    self._lock:SetActive(passState == UILostLandMissionLockType.LOCK)
    self._clean:SetActive(passState == UILostLandMissionLockType.PASS)
    self._iconMaskGo:SetActive(passState == UILostLandMissionLockType.LOCK or passState == UILostLandMissionLockType.PASS)

    self._lineX1.sizeDelta = Vector2(self._width * 0.5, self._lineX1.sizeDelta.y)
    self._lineX2.sizeDelta = Vector2(self._width * 0.5, self._lineX1.sizeDelta.y)

    local pos = Vector2(0, self._type2pos[self._upOrDown])
    self._pos.anchoredPosition = pos

    if self._index == 1 then
        self._lineX1.gameObject:SetActive(false)
    else
        self._lineX1.gameObject:SetActive(true)
    end
    if self._index == self._missionCount then
        self._lineX2.gameObject:SetActive(false)
    else
        self._lineX2.gameObject:SetActive(true)
    end
    if self._showLineY then
        self._lineY:SetActive(true)
    else
        self._lineY:SetActive(false)
    end
end

function UIWeekTowerNodeItem:bgOnClick(go)
    if self._callback then
        self._callback(self._index)
    end
end
