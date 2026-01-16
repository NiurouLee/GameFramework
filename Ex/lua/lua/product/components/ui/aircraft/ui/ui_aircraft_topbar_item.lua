---@class UIAircraftTopBarItem : UICustomWidget
_class("UIAircraftTopBarItem", UICustomWidget)
UIAircraftTopBarItem = UIAircraftTopBarItem
function UIAircraftTopBarItem:OnShow(uiParams)
    self.active = true
    self:InitWidget()
    self:SetRecoverActive(false)
    ---@type AircraftModule
    self.aircraftModule = GameGlobal.GameLogic():GetModule(AircraftModule)
    --初始化氛围值
    self:OnSetAmbientActive(true)
    self:OnAmbientChanged()
    self.AmbientText_.color = Color(0, 220 / 255, 255 / 255, 1)

    self:AttachEvent(GameEventType.AircraftOnFireFlyChanged, self.OnFireFlyChanged)
    self:AttachEvent(GameEventType.AircraftOnAmbientChanged, self.OnAmbientChanged)
    self:AttachEvent(GameEventType.AircraftAmbientSetActive, self.OnSetAmbientActive)
    self:AttachEvent(GameEventType.AircraftSettledPetChanged, self.OnAmbientChanged)
end

function UIAircraftTopBarItem:OnHide()
    self.active = false
    if self.timerEvent then
        GameGlobal.Timer():CancelEvent(self.timerEvent)
        self.timerEvent = nil
    end
end

function UIAircraftTopBarItem:InitWidget()
    -- self.textFireflyCount = self:GetUIComponent("UILocalizationText", "TextFireflyCount")
    -- self.textEnergyCount = self:GetUIComponent("UILocalizationText", "TextEnergyCount")
    -- self.textMoneyCount = self:GetUIComponent("UILocalizationText", "TextMoneyCount")
    self.imageSlider = self:GetUIComponent("Image", "ImageSlider")
    self.textRecoverTimer = self:GetUIComponent("UILocalizationText", "TextRecoverTimer")
    self.textRecoverSpeedUp = self:GetUIComponent("RollingText", "TextRecoverSpeedUp")
    self.recoverSpeed = self:GetUIComponent("UILocalizationText", "recoverSpeed")
    self.fireflyGo = self:GetGameObject("Firefly")

    --氛围
    self.Ambient_ = self:GetGameObject("Ambient")
    self.AmbientText_ = self:GetUIComponent("UILocalizationText", "ValueText")

    self.pos = self:GetUIComponent("RectTransform", "pos")
end

---@param backCallback function
---@param _showBackButton boolean 是否显示左侧的返回和帮助按钮
function UIAircraftTopBarItem:SetData(_showButtons, _backCallback, _helpCallback, showAmbient, showGold)
    self.Ambient_:SetActive(showAmbient == true)

    local sop = self:GetUIComponent("UISelectObjectPath", "Top")
    ---@type UICurrencyMenu
    self.currencyMenu = sop:SpawnObject("UICurrencyMenu")
    -- 萤火 星能 金币
    if showGold then
        self.currencyMenu:SetData({RoleAssetID.RoleAssetFirefly, CurrenyTypeId.StarPoint, RoleAssetID.RoleAssetGold})
        self.goldItem = self.currencyMenu:GetItemByTypeId(RoleAssetID.RoleAssetGold)
    else
        self.currencyMenu:SetData({RoleAssetID.RoleAssetFirefly, CurrenyTypeId.StarPoint})
    end
    ---@type UICurrencyItem
    self.fireFlyItem = self.currencyMenu:GetItemByTypeId(RoleAssetID.RoleAssetFirefly)
    self.fireFlyItem:SetAddCallBack(
        function(id, go)
            --ToastManager.ShowLockTip()
            local pos = go.transform.position
            self:SetRecoverActive(true, pos)
            self:RefreshFirflyPopupInfo()
        end
    )
    self.energyItem = self.currencyMenu:GetItemByTypeId(CurrenyTypeId.StarPoint)

    self:RefreshGoldInfo()

    if _showButtons ~= nil and _showButtons == false then
        return
    end

    local topButton = self:GetUIComponent("UISelectObjectPath", "TopButtons")
    ---@type UICommonTopButton
    self.topButtonWidget = topButton:SpawnObject("UICommonTopButton")
    -- self.topButtonWidget:SetData(_backCallback, nil)
    self.topButtonWidget:SetData(
        _backCallback,
        _helpCallback,
        function()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftLeaveAircraft)
            GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Aircraft_Exit, "UI")
        end
    )
end

function UIAircraftTopBarItem:OnFireFlyChanged()
    self:RefreshFirefly()
end

function UIAircraftTopBarItem:OnAmbientChanged()
    local ambientValue = self.aircraftModule:GetValidAmbient()
    self.AmbientText_:SetText(ambientValue)
end

function UIAircraftTopBarItem:OnSetAmbientActive(boolValue)
    self.Ambient_:SetActive(boolValue)
end

--刷新顶条货币信息
function UIAircraftTopBarItem:RefreshGoldInfo()
    self:RefreshFirefly()

    local powerAvai = self.aircraftModule:GetPower()
    local powerMax = self.aircraftModule:GetMaxPower()
    --qa 7619
    self.energyItem:SetText((powerAvai) .. "/" .. powerMax)
    -- self.textEnergyCount.text = (powerMax - powerAvai) .. "/" .. powerMax

    local gold = GameGlobal.GameLogic():GetModule(RoleModule):GetGold()
    if self.goldItem then
        self.goldItem:SetText(HelperProxy:GetInstance():FormatGold(gold))
    end
    -- self.textMoneyCount.text = HelperProxy:GetInstance():FormatGold(gold)
end

function UIAircraftTopBarItem:RefreshFirefly()
    local hadf = math.floor(self.aircraftModule:GetFirefly())
    local maxf = math.floor(self.aircraftModule:GetMaxFirefly())
    self.fireFlyItem:SetText(hadf .. "/" .. maxf)
end

--刷新萤火弹窗信息
function UIAircraftTopBarItem:RefreshFirflyPopupInfo()
    local hadf = math.floor(self.aircraftModule:GetFirefly())
    local maxf = math.floor(self.aircraftModule:GetMaxFirefly())
    local fireflyAmount = 0
    if maxf == 0 then
        fireflyAmount = 1
    else
        fireflyAmount = hadf / maxf
    end
    self.imageSlider.fillAmount = fireflyAmount

    local speed = self.aircraftModule:GetFireflyRecoverSpeed() * 3600
    local title = StringTable.Get("str_aircraft_func_firefly_recover_speed_sum")
    self.textRecoverSpeedUp:RefreshText(title)
    self.recoverSpeed:SetText(string.format("%.2f", speed))
    local countDownTime = math.ceil(self.aircraftModule:GetFireFlyRemainderTime())
    if countDownTime > 0 then
        self.textRecoverTimer.text = HelperProxy:GetInstance():FormatTime_2(countDownTime)
        self:StartCountDown()
    else
        self.textRecoverTimer.text = "--:--:--"
    end
end

function UIAircraftTopBarItem:StartCountDown()
    self.timerEvent =
        GameGlobal.Timer():AddEventTimes(
        1000,
        TimerTriggerCount.Infinite,
        function()
            local hadf = math.floor(self.aircraftModule:GetFirefly())
            local maxf = math.floor(self.aircraftModule:GetMaxFirefly())
            local fireflyAmount = 0
            if maxf == 0 then
                fireflyAmount = 1
            else
                fireflyAmount = hadf / maxf
            end
            self.fireFlyItem:SetText(hadf .. "/" .. maxf)
            -- self.textFireflyCount.text = hadf .. "/" .. maxf
            self.imageSlider.fillAmount = fireflyAmount

            local countDownTime = math.ceil(self.aircraftModule:GetFireFlyRemainderTime())
            if countDownTime <= 0 then
                self.textRecoverTimer.text = "--:--:--"
                self:CountdownEnd()
            else
                self.textRecoverTimer.text = HelperProxy:GetInstance():FormatTime_2(countDownTime)
            end
        end
    )
end

function UIAircraftTopBarItem:CountdownEnd()
    self.countDownTime = 0
    GameGlobal.Timer():CancelEvent(self.timerEvent)
    self.timerEvent = nil
    GameGlobal.TaskManager():StartTask(self.ReqData, self)
end

function UIAircraftTopBarItem:ReqData(TT)
    self:Lock(self:GetName())
    local ack = self.aircraftModule:AircraftUpdate(TT)
    self:UnLock(self:GetName())
    if ack:GetSucc() then
        if self.active then
            self:RefreshAllMsg()
        end
    else
        ToastManager.ShowToast(self.aircraftModule:GetErrorMsg(ack:GetResult()))
    end
end

function UIAircraftTopBarItem:RefreshAllMsg()
    self:RefreshGoldInfo()
    -- GameGlobal.EventDispatcher():Dispatch(GameEventType.ItemCountChanged)
    if self.fireflyGo.activeSelf then
        if self.timerEvent then
            GameGlobal.Timer():CancelEvent(self.timerEvent)
            self.timerEvent = nil
        end
        self:RefreshFirflyPopupInfo()
    end
end

function UIAircraftTopBarItem:SetRecoverActive(active, position)
    self.fireflyGo:SetActive(active)
    if active then
        if position then
            self.pos.position = position
        end
    end
end

function UIAircraftTopBarItem:ButtonFireflyPopupOnClick(go)
    -- ToastManager.ShowToast(StringTable.Get("str_aircraft_function_not_open"))
    self:SetRecoverActive(true)
    self:RefreshFirflyPopupInfo()
end
function UIAircraftTopBarItem:ButtonSpeedUpOnClick(go)
    ToastManager.ShowLockTip()
    --ToastManager.ShowToast(StringTable.Get("str_aircraft_function_not_open"))
    -- self:ShowDialog("UIPowerExchangeController")
end

function UIAircraftTopBarItem:FireflyRecoverPopupOnClick(go)
    if self.timerEvent then
        GameGlobal.Timer():CancelEvent(self.timerEvent)
        self.timerEvent = nil
    end
    self:SetRecoverActive(false)
end

function UIAircraftTopBarItem:AmbientPanelOnClick(go)
    GameGlobal.UIStateManager():ShowDialog("UIAmbientPanel")
end

function UIAircraftTopBarItem:AmbientButton1OnClick(go)
    -- GameGlobal.UIStateManager():ShowDialog("UIAmbientPanel")
end
