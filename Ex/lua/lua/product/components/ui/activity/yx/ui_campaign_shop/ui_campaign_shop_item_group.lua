---@class UICampaignShopItemGroup : UICustomWidget
_class("UICampaignShopItemGroup", UICustomWidget)
UICampaignShopItemGroup = UICampaignShopItemGroup
function UICampaignShopItemGroup:OnShow(uiParams)
    self:InitWidget()
end
function UICampaignShopItemGroup:InitWidget()
    --generated--
    self._svrTimeModule = self:GetModule(SvrTimeModule)
    ---@type UnityEngine.GameObject
    self._lockArea = self:GetGameObject("LockArea")
    self._cellGenGo = self:GetGameObject("ShopItemList")
    ---@type UICustomWidgetPool
    self._shopItemList = self:GetUIComponent("UISelectObjectPath", "ShopItemList")
    self._countDownText = self:GetUIComponent("UILocalizationText", "CountDownText")
    self._setAlphaArea = self:GetUIComponent("CanvasGroup", "ShopItemList")

    self._event = nil

    --self._clearItems = {}
    --generated end--
end

function UICampaignShopItemGroup:OnHide()
    if self._event then
        GameGlobal.RealTimer():CancelEvent(self._event)
        self._event = nil
    end
end

function UICampaignShopItemGroup:SetData()
end

function UICampaignShopItemGroup:GetRealSize()
    local width = 0
    for index, value in ipairs(self._data) do
        if value.GetIsSpecial and value:GetIsSpecial() then
            width = width + 400
        else
            width = width + 350
        end
    end
    return Vector2(width, 800)
    --return Vector2(self._cellSize * 375, 800)
end

---@param data DCampaignShopItemBase
function UICampaignShopItemGroup:InitData(data)
    ---清理掉所有创建的cell
    self:DisposeCustomWidgets()
    self._shopItemList = self:GetUIComponent("UISelectObjectPath", "ShopItemList")
    -- for index, value in ipairs(self._clearItems) do
    --     UnityEngine.GameObject.Destroy(value)
    -- end
    --self._clearItems = {}
    self._data = data
    local cellSize = #data
    self._cellSize = cellSize
    local itemList = self._shopItemList:SpawnObjects("UICampaignShopItemGroupCell", cellSize)
    for index, value in ipairs(itemList) do
        value:InitData(data[index])
    end

    -- {
    -- for index, value in ipairs(data) do
    --     local item = UnityEngine.GameObject.Instantiate(self._cellGenGo, self:GetGameObject().transform)
    --     local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    --     local itemCell = rowPool:SpawnObject("UICampaignShopItemGroupCell")
    --     itemCell:InitData(value)
    --     table.insert(self._clearItems,item)
    --     --UIHelper.RefreshLayout(itemCell:GetComponent("RectTransform"))
    -- end
    -- }
    UIHelper.SetAsLastSibling(self._lockArea)
    local nowTime = math.floor(self._svrTimeModule:GetServerTime() / 1000)
    if ClientCampaignShop.CheckIsGoodsGroupUnlock(self._data._unlockTime, nowTime) then
        self._lockArea:SetActive(false)
        self._setAlphaArea.alpha = 1
        self._setAlphaArea.blocksRaycasts = true
    else
        self._setAlphaArea.alpha = 0.5
        self._setAlphaArea.blocksRaycasts = false
        self._lockArea:SetActive(true)
        self:_OnValueRemainingTime()
    end
    --UIHelper.RefreshLayout(self:GetGameObject("ShopItemList"):GetComponent("RectTransform"))
    --UIHelper.RefreshLayout(self:GetGameObject():GetComponent("RectTransform"))
end

function UICampaignShopItemGroup:_OnValueRemainingTime()
    self:_ShowRemainingTime()

    if self._event then
        GameGlobal.RealTimer():CancelEvent(self._event)
        self._event = nil
    end

    self._event =
        GameGlobal.RealTimer():AddEventTimes(
        1000,
        TimerTriggerCount.Infinite,
        function()
            self:_ShowRemainingTime()
        end
    )
end

function UICampaignShopItemGroup:_ShowRemainingTime()
    local stopTime = self._data._unlockTime
    local nowTime = math.floor(self._svrTimeModule:GetServerTime() / 1000)
    local remainingTime = stopTime - nowTime
    if remainingTime <= 0 then
        if self._event then
            GameGlobal.RealTimer():CancelEvent(self._event)
            self._event = nil
        end
        remainingTime = 0
    --GameGlobal.EventDispatcher():Dispatch(GameEventType.OnCloseGrowthPanel)
    --return
    end
    self._countDownText:SetText(self:_GetFormatString(remainingTime))
end

function UICampaignShopItemGroup:_GetFormatString(stamp)
    local formatStr = "%s <color=#%s>%s</color>"
    local descStr = StringTable.Get("str_activity_evesinsa_shop_group_unlock_time")
    local colorStr = "FFE42D"

    local timeStr = UIActivityHelper.GetFormatTimerStr(stamp)
    local showStr = string.format(formatStr, descStr, colorStr, timeStr)

    return showStr
end
