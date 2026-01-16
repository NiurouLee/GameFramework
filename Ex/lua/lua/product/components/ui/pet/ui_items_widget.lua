---@class UIItemsWidget:UICustomWidget
_class("UIItemsWidget", UICustomWidget)
UIItemsWidget = UIItemsWidget
function UIItemsWidget:OnShow()
    local sop = self:GetUIComponent("UISelectObjectPath", "uiitem")
    self._root = self:GetUIComponent("RectTransform", "uiitem")
    self.uiItem = sop:SpawnObject("UIItem")
    self.uiItem:SetForm(UIItemForm.Base)
    self.uiItem:SetClickCallBack(
        function(go)
            self:UIItemsWidgetOnClick(go)
        end
    )

    self:AttachEvent(GameEventType.ItemCountChanged, self.OnItemCountChanged)

    self.clickCallBack = nil
    self.matID = -1

    self.enough = false

    self._waitTime = Cfg.cfg_global["shakeWaitTime"].IntValue or 2000
    self._shakeX = Cfg.cfg_global["shakeOffsetX"].IntValue or 10
    self._shakeY = Cfg.cfg_global["shakeOffsetY"].IntValue or 10
end
function UIItemsWidget:OnHide()
    self:DetachEvent(GameEventType.ItemCountChanged, self.OnItemCountChanged)
    if self.shakeTweener then
        self.shakeTweener:Kill()
        self.shakeTweener = nil
    end
    if self.highLightTimer then
        GameGlobal.Timer():CancelEvent(self.highLightTimer)
        self.highLightTimer = nil
    end
end

---@param _id number 物品ID
---@param _needCount number 需要的数量
---@param _clickCallback function 点击回调
---@param _singleValue boolean 只显示需要的单个值
function UIItemsWidget:SetData(_id, _needCount, _clickCallback, _singleValue)
    self.matID = _id
    self.needCount = _needCount
    self.clickCallBack = _clickCallback
    self.singleValue = _singleValue

    self.cfgData = Cfg.cfg_item[_id]
    ---@type RoleModule
    self.roleModule = GameGlobal.GameLogic():GetModule(RoleModule)

    self.icon = self.cfgData.Icon
    self.quality = self.cfgData.Color

    self:RefreshCount()

    --萤火实时增长
    if self.matID == RoleAssetID.RoleAssetFirefly then
        self:AttachEvent(GameEventType.AircraftOnFireFlyChanged, self.RefreshCount)
    end
end
function UIItemsWidget:RefreshCount()
    local _hadCount = math.floor(self.roleModule:GetAssetCount(self.matID))
    self._text = nil
    if self.singleValue then
        self._text = self.needCount
    else
        local enough = _hadCount >= self.needCount
        self.enough = enough
        local cuStr = self.needCount
        local chStr = _hadCount
        if _hadCount > 9999 then
            chStr = "9999+"
        end
        self.chStr = chStr
        local showStr
        if _hadCount >= self.needCount then
            showStr =
                "<color=#ffd300>" .. chStr .. "</color><color=#ffffff>/</color><color=#ffd300>" .. cuStr .. "</color>"
        else
            showStr =
                "<color=#ff0000>" .. chStr .. "</color><color=#ffffff>/</color><color=#ffffff>" .. cuStr .. "</color>"
        end
        self._text = showStr
    end
    self.uiItem:SetData({icon = self.icon, quality = self.quality, text1 = self._text, itemId = self.matID})
end

function UIItemsWidget:ShakeAndHighlight()
    --材料不足音效
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundUIMaterialNotEnough)

    if self.shakeTweener then
        self.shakeTweener:Kill()
        --停止时复位，避免再次抖动后偏移
        self._root.anchoredPosition = Vector2(0, 0)
    end
    if self.highLightTimer then
        GameGlobal.Timer():CancelEvent(self.highLightTimer)
    end

    local head = self.chStr
    local tail = self.needCount
    local text1 = "<color=#ff0000>" .. head .. "/" .. tail .. "</color>"
    self.uiItem:SetData({text1 = text1})
    self.shakeTweener =
        self._root:DOShakePosition(1, Vector3(self._shakeX, self._shakeY, 0)):OnComplete(
        function()
            self.highLightTimer =
                GameGlobal.Timer():AddEvent(
                self._waitTime,
                function()
                    self.uiItem:SetData({text1 = self._text})
                end
            )
        end
    )
end

function UIItemsWidget:IsMatEnough()
    return self.enough
end

function UIItemsWidget:UIItemsWidgetOnClick(go)
    if self.clickCallBack then
        self.clickCallBack(self.matID, go.transform.position)
    end
end

function UIItemsWidget:OnItemCountChanged()
    self:RefreshCount()
end
