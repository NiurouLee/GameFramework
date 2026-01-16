---@class UICampaignShopController : UIController
_class("UICampaignShopController", UIController)
UICampaignShopController = UICampaignShopController

function UICampaignShopController:Constructor()
    self._shopCloseTime = 0
    self._svrTimeModule = self:GetModule(SvrTimeModule)
    self._interactWords = nil
    self._wordStack = nil
    self._spineSke = nil
    self._animInfo = {
        name = "uieff_Activity_Eve_Shop_Out",
        len = 400
    }
end

function UICampaignShopController:_InitCmpt(TT, res)
    ---@type CampaignModule
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_EVERESCUEPLAN,
        ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_EXCHANGE1,
        ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_EXCHANGE2
    )
    -- 错误处理
    if res and not res:GetSucc() then
        campaignModule:CheckErrorCode(res.m_result, self._campaign._id)
        self:CloseDialog()
        return
    end
    self._campaignId = self._campaign._id
    if self._campaignId ~= -1 then
        ---@type ExchangeItemComponent
        self._exchangeCmpts = {}
        local cmptTypes = {
            ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_EXCHANGE1,
            ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_EXCHANGE2
        }
        for index, value in ipairs(cmptTypes) do
            local exchangeCmpt = self._campaign:GetComponent(value)
            if exchangeCmpt then
                ---@type ExchangeItemComponentInfo
                local cmptInfo = exchangeCmpt:GetComponentInfo()
                if cmptInfo then
                    local nowTime = math.floor(self._svrTimeModule:GetServerTime() / 1000)
                    local isClose = ClientCampaignShop.CheckIsGoodsGroupClose(cmptInfo.m_close_time, nowTime)
                    if not isClose then
                        table.insert(self._exchangeCmpts, exchangeCmpt)
                        if self._shopCloseTime == 0 then
                            self._shopCloseTime = cmptInfo.m_close_time
                        --第一个组件的关闭时间作为商店关闭时间
                        end
                    end
                end
            end
        end
        if #self._exchangeCmpts == 0 then
            --没有可用的商品组
            res:SetSucc(false)
            self:CloseDialog()
        end
    end
end

function UICampaignShopController:OnShow(uiParams)
    --兑换商店的返回按钮 指定跳转到活动主界面，避免界面返回逻辑混乱，把其他子界面关掉
    GameGlobal.EventDispatcher():Dispatch(GameEventType.CampaignShopEnter)
    self:AddListener()
    self:InitWidget()
    self:InitPlayerSpine()
end

function UICampaignShopController:InitWidget()
    --generated--
    self._rootAnim = self:GetUIComponent("Animation", "Root")
    ---@type UICustomWidgetPool
    local backBtn = self:GetUIComponent("UISelectObjectPath", "BackBtn")
    ---@type UICommonTopButton
    self._backBtns = backBtn:SpawnObject("UICommonTopButton")
    self._lastBGMResName = AudioHelperController.GetCurrentBgm()
    self._backBtns:SetData(
        function()
            self:BackBtnFunc()
            AudioHelperController.PlayBGM(self._lastBGMResName, AudioConstValue.BGMCrossFadeTime)
        end
    )
    local exchangeRewardBtn = self:GetUIComponent("UISelectObjectPath", "ExchangeRewardBtn")
    self._exchangeRewardBtn = exchangeRewardBtn:SpawnObject("UIActivityEveSinsaShopBtn")
    self._exchangeRewardBtn:SetData(self._campaign, false, true)

    ------------------------------------------------------------------------------------------

    self._npcWordText = self:GetUIComponent("UILocalizationText", "NpcWordText")
    self._npcNameText = self:GetUIComponent("UILocalizationText", "NpcNameText")
    ---@type UILocalizationText
    self._endTimeText = self:GetUIComponent("UILocalizationText", "EndTimeText")
    self._npcImg = self:GetUIComponent("RawImageLoader", "NpcImg")
    self._countDownAreaGo = self:GetGameObject("CountDownArea")
    self._endTimeTextGo = self:GetGameObject("EndTimeText")
    self._uianimCG = self:GetUIComponent("CanvasGroup", "uianim")

    ---@type UIDynamicScrollView
    self._shopItemGroupList = self:GetUIComponent("UIDynamicScrollView", "ShopItemGroupList")
    self._refreshTaskID = nil
    self._event = nil
    self._refreshGroupEvent = nil
    self._restTime = 0
    self:_FillCfgUiRes()
    self:_FillUiData()
    self:_InitShopItemGroupList()
    self:_RefreshUi()
    self:_StartCheckGoodsGroupRefresh()
    --generated end--
end

function UICampaignShopController:_FillCfgUiRes()
    local shopCfg = Cfg.cfg_activity_shop_common_client[self._campaignId]
    if shopCfg then
        if self._npcImg then
            self._npcImg:LoadImage(shopCfg.NpcImg)
        end
        if self._npcNameText then
            self._npcNameText:SetText(StringTable.Get(shopCfg.NpcName))
        end
        self._interactWords = string.split(StringTable.Get(shopCfg.NpcWord), "|")
        self._wordStack = Stack:New()
        if self._npcWordText then
            local word = self:_GetInteractWord()
            self._npcWordText:SetText(word)
        end
    end
end

function UICampaignShopController:OnActivityShopBuySuccess(goodsId)
    self:_ForceRefresh()
end

function UICampaignShopController:_ForceRefresh()
    self._refreshTaskID =
        self:StartTask(
        function(TT)
            local res = AsyncRequestRes:New()
            res:SetSucc(true)
            self:_InitCmpt(TT, res)
            if res and res:GetSucc() then
                self:_FillUiData()
                self:_RefreshUi()
            end
        end,
        self
    )
end

function UICampaignShopController:BackBtnFunc()
    -- 因为任务组件的红点没有推送，需要主动通知活动主界面刷新红点
    GameGlobal.EventDispatcher():Dispatch(GameEventType.CampaignComponentStepChange, self._campaign._id, nil, nil)

    self:CloseDialogWithAnim()
end

function UICampaignShopController:CloseDialogWithAnim()
    if self._rootAnim then
        self:Lock("UICampaignShopController:CloseDialogWithAnim")
        if self._rootAnim then
            self._rootAnim:Play(self._animInfo.name)
        end
        self:StartTask(
            function(TT)
                YIELD(TT, self._animInfo.len)
                self:UnLock("UICampaignShopController:CloseDialogWithAnim")
                self:CloseDialog()
            end,
            self
        )
    end
end

function UICampaignShopController:_FillUiData()
    local boxItemLimit = 2
    local tmpData = {}
    for index, value in ipairs(self._exchangeCmpts) do
        ---@type ExchangeItemComponentInfo
        local exchangeInfo = value:GetComponentInfo()
        --local componentFullId = value:GetComponetCfgId(self._campaignId,exchangeInfo.m_component_id)
        local itemGroupData = DCampaignShopItemGroup:New()
        local smallBoxData = {}
        local smallItemCountInBox = 0
        for itemIndex, itemInfo in ipairs(exchangeInfo.m_exchange_item_list) do
            ---@type ExchangeItemComponentItemInfo
            ---@type DCampaignShopItemBase
            local uiItemData = DCampaignShopItemBase:New()
            uiItemData:Refresh(itemInfo, value)
            if uiItemData:GetIsSpecial() then
                table.insert(itemGroupData, uiItemData)
            else
                --两个小格子放一组
                smallItemCountInBox = smallItemCountInBox + 1
                table.insert(smallBoxData, uiItemData)
                if smallItemCountInBox == boxItemLimit or itemIndex == #exchangeInfo.m_exchange_item_list then
                    table.insert(itemGroupData, smallBoxData)
                    smallBoxData = {}
                    smallItemCountInBox = 0
                -- elseif itemIndex == #exchangeInfo.m_exchange_item_list then
                --     table.insert(itemGroupData, smallBoxData)
                --     smallBoxData = {}
                --     smallItemCountInBox = 0
                end
            end
        end
        itemGroupData._unlockTime = exchangeInfo.m_unlock_time
        itemGroupData._showTime = exchangeInfo.m_open_time
        itemGroupData._closeTime = exchangeInfo.m_close_time
        local nowTime = math.floor(self._svrTimeModule:GetServerTime() / 1000)
        itemGroupData._isShow = ClientCampaignShop.CheckIsGoodsGroupCanShow(itemGroupData._showTime, nowTime)
        itemGroupData._isUnlock = ClientCampaignShop.CheckIsGoodsGroupUnlock(itemGroupData._unlockTime, nowTime)
        itemGroupData._isClose = ClientCampaignShop.CheckIsGoodsGroupUnlock(itemGroupData._closeTime, nowTime)
        table.insert(tmpData, itemGroupData)
    end
    ---@type DCampaignShopItemBase
    self._shopItemGroupData = tmpData
end

function UICampaignShopController:_RefreshUi(bResetPos)
    local canShowItemGroupData = {}
    local nowTime = math.floor(self._svrTimeModule:GetServerTime() / 1000)
    for index, value in ipairs(self._shopItemGroupData) do
        if ClientCampaignShop.CheckIsGoodsGroupCanShow(value._showTime, nowTime) then
            table.insert(canShowItemGroupData, value)
        end
    end
    self._showShopItemGroupData = canShowItemGroupData
    self._itemGroupCount = #self._showShopItemGroupData
    self._shopItemGroupList:SetListItemCount(self._itemGroupCount, false)
    self._shopItemGroupList:RefreshAllShownItem()
    if bResetPos then
        self._shopItemGroupList:MovePanelToItemIndex(0, 0)
        self._shopItemGroupList:FinishSnapImmediately()
    end
    self:_OnValueRemainingTime()
end

function UICampaignShopController:LoadDataOnEnter(TT, res, uiParams)
    self.params = uiParams
    self:_InitCmpt(TT, res)
end

function UICampaignShopController:_OnValueRemainingTime()
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

function UICampaignShopController:_StartCheckGoodsGroupRefresh()
    if self._refreshGroupEvent then
        GameGlobal.RealTimer():CancelEvent(self._refreshGroupEvent)
        self._refreshGroupEvent = nil
    end
    self._refreshGroupEvent =
        GameGlobal.RealTimer():AddEventTimes(
        1000,
        TimerTriggerCount.Infinite,
        function()
            self:_CheckGoodsGroupRefresh()
        end
    )
end

function UICampaignShopController:_CheckGoodsGroupRefresh()
    local nowTime = math.floor(self._svrTimeModule:GetServerTime() / 1000)
    local needRefresh = false
    for index, value in ipairs(self._shopItemGroupData) do
        if not value._isShow then
            local newIsShow = ClientCampaignShop.CheckIsGoodsGroupCanShow(value._showTime, nowTime)
            if newIsShow then
                needRefresh = true
                break
            end
        end
        if not value._isUnlock then
            local newIsUnlock = ClientCampaignShop.CheckIsGoodsGroupUnlock(value._unlockTime, nowTime)
            if newIsUnlock then
                needRefresh = true
                break
            end
        end
        if not value._isClose then
            local newIsClose = ClientCampaignShop.CheckIsGoodsGroupClose(value._closeTime, nowTime)
            if newIsClose then
                needRefresh = true
                break
            end
        end
    end
    if needRefresh then
        self:_FillUiData()
        self:_RefreshUi(true)
    end
end

function UICampaignShopController:_ShowRemainingTime()
    local stopTime = self._shopCloseTime
    local nowTime = math.floor(self._svrTimeModule:GetServerTime() / 1000)
    local remainingTime = stopTime - nowTime
    if remainingTime <= 0 then
        if self._event then
            GameGlobal.RealTimer():CancelEvent(self._event)
            self._event = nil
        end
        self._endTimeTextGo:SetActive(false)
        remainingTime = 0
    else
        self._endTimeTextGo:SetActive(true)
    end
    self._endTimeText:SetText(self:_GetFormatString(remainingTime))
end

function UICampaignShopController:_GetFormatString(stamp)
    local formatStr = "%s <color=#%s>%s</color>"
    local descStr = StringTable.Get("str_activity_evesinsa_shop_end_time")
    local colorStr = "FFE42D"

    local timeStr = UIActivityHelper.GetFormatTimerStr(stamp)
    local showStr = string.format(formatStr, descStr, colorStr, timeStr)

    return showStr
end

function UICampaignShopController:OnHide()
    if self._refreshTaskID then
        GameGlobal.TaskManager():KillTask(self._refreshTaskID)
        self._refreshTaskID = nil
    end
    if self._event then
        GameGlobal.RealTimer():CancelEvent(self._event)
        self._event = nil
    end
    if self._refreshGroupEvent then
        GameGlobal.RealTimer():CancelEvent(self._refreshGroupEvent)
        self._refreshGroupEvent = nil
    end
    self:DetachListener()
end

function UICampaignShopController:AddListener()
    self:AttachEvent(GameEventType.ActivityShopBuySuccess, self.OnActivityShopBuySuccess)
    self:AttachEvent(GameEventType.ActivityCloseEvent, self.OnActivityCloseEvent)
    self:AttachEvent(GameEventType.ActivityComponentCloseEvent, self.OnActivityComponentCloseEvent)
    self:AttachEvent(GameEventType.ActivityShopNeedRefresh, self.OnActivityShopNeedRefresh)
end

function UICampaignShopController:DetachListener()
    self:DetachEvent(GameEventType.ActivityShopBuySuccess, self.OnActivityShopBuySuccess)
    self:DetachEvent(GameEventType.ActivityCloseEvent, self.OnActivityCloseEvent)
    self:DetachEvent(GameEventType.ActivityComponentCloseEvent, self.OnActivityComponentCloseEvent)
    self:DetachEvent(GameEventType.ActivityShopNeedRefresh, self.OnActivityShopNeedRefresh)
end

function UICampaignShopController:OnActivityCloseEvent(campaignId)
    if self._campaign and self._campaign._id == campaignId then
        self:SwitchState(UIStateType.UIMain)
    end
end

function UICampaignShopController:OnActivityShopNeedRefresh(campaignId)
    if self._campaign and self._campaign._id == campaignId then
        self:_ForceRefresh()
    end
end

function UICampaignShopController:OnActivityComponentCloseEvent(componentFullId)
    for index, value in ipairs(self._exchangeCmpts) do
        local exchangeInfo = value:GetComponentInfo()
        local cmptFullId = value:GetComponetCfgId(self._campaignId, exchangeInfo.m_component_id)
        if cmptFullId == componentFullId then
            self:_ForceRefresh()
            return
        end
    end
end

function UICampaignShopController:_SetShopItemGroupListCellCount()
    self._shopItemGroupList:SetListItemCount(self._itemGroupCount, false)
end

function UICampaignShopController:_InitShopItemGroupList()
    local canShowItemGroupData = {}
    local nowTime = math.floor(self._svrTimeModule:GetServerTime() / 1000)
    for index, value in ipairs(self._shopItemGroupData) do
        if ClientCampaignShop.CheckIsGoodsGroupCanShow(value._showTime, nowTime) then
            table.insert(canShowItemGroupData, value)
        end
    end
    self._showShopItemGroupData = canShowItemGroupData
    self._itemGroupCount = #self._showShopItemGroupData
    self._shopItemGroupList:InitListView(
        self._itemGroupCount,
        function(scrollview, index)
            return self:_OnGetShopItemGroupCell(scrollview, index)
        end
    )
end

function UICampaignShopController:_OnGetShopItemGroupCell(scrollview, index)
    local item = scrollview:NewListViewItem("CellItem")
    local cellPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        cellPool:SpawnObjects("UICampaignShopItemGroup", 1)
    end
    local rowList = cellPool:GetAllSpawnList()
    local itemWidget = rowList[1]
    ---@type UICampaignShopItemGroup
    if itemWidget then
        local itemIndex = index + 1
        itemWidget:InitData(self._showShopItemGroupData[itemIndex])
        if itemIndex > self._itemGroupCount then
            itemWidget:GetGameObject():SetActive(false)
        end
        ---根据商品数量计算实际宽度
        item:GetComponent("RectTransform").sizeDelta = itemWidget:GetRealSize()
    end
    --scrollview:OnItemSizeChanged(index)
    --UIHelper.RefreshLayout(item:GetComponent("RectTransform"))
    return item
end

function UICampaignShopController:NpcWordInteractBtnOnClick(go)
    if self._npcWordText then
        local word = self:_GetInteractWord()
        self._npcWordText:SetText(word)
    end
end

function UICampaignShopController:_GetInteractWord()
    if self._wordStack:Size() <= 0 then
        local count = 0
        local all = #self._interactWords
        local tmpIndexs = {}
        for i = 1, all do
            table.insert(tmpIndexs, i)
        end
        for j = #tmpIndexs, 1, -1 do
            local index = math.random(1, #tmpIndexs)
            tmpIndexs[j], tmpIndexs[index] = tmpIndexs[index], tmpIndexs[j]
        end
        for _, value in ipairs(tmpIndexs) do
            self._wordStack:Push(value)
        end
    end
    return self._interactWords[self._wordStack:Pop()]
end
----------------------spine---------------------
function UICampaignShopController:InitPlayerSpine()
    -- self.spinePlaying = false
    self._spine = self:GetUIComponent("SpineLoader", "NpcSpine")
    --self._spineGo = self:GetGameObject("NpcSpine")
    self._spine:LoadSpine("1500901_spine_idle")
    if self._spine then
        self._spineSke = self._spine.CurrentSkeleton
        if not self._spineSke then
            self._spineSke = self._spine.CurrentMultiSkeleton
        end
    end
end

----------------------spine end---------------------
function UICampaignShopController:OnUpdate(deltaTimeMS)
    --spine的透明度与ui动效保持一致
    if self._spineSke and self._uianimCG then
        local curAlpha = self._uianimCG.alpha
        if self._lastUpdateSpineHolderAlpha ~= curAlpha then
            self._lastUpdateSpineHolderAlpha = curAlpha
            self._spineSke.color = Color(1, 1, 1, curAlpha)
            self._spineSke.Skeleton.A = curAlpha
        end
    end
end
