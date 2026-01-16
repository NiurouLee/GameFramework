---@class UISakuraDrawShopController : UIController
_class("UISakuraDrawShopController", UIController)
UISakuraDrawShopController = UISakuraDrawShopController
function UISakuraDrawShopController:Constructor()
    self.clientHelper = ClientCampaignDrawShop:New()
    self.singleTimes = 1
    self.multiTimes = 10
    self.singlePrice = 100
    self.multiPrice = 1000
    self.uiData = {}
    self.unlockBoxs = {}
    self._curPageIndex = 1 --1~n 奖池序号从1开始 uiData从1开始
    self._petModule = GameGlobal.GetModule(PetModule)
    self._curSpine = ""
    self.atlas = self:GetAsset("UISakura.spriteatlas", LoadType.SpriteAtlas)
    --tmp
    self.animNames = {
        out_anim = {
            bg_out = "uieff_UISakuraDrawShopController_b_out",
            ui_out = "uieff_UISakuraDrawShopController_u_out",
            time_len = 700
        },
        left_out = {
            name = "uieff_UISakuraDrawShopController_u_r_out",
            time_len = 700
        },
        left_in = {
            name = "uieff_UISakuraDrawShopController_u_r_in",
            time_len = 700
        },
        right_out = {
            name = "uieff_UISakuraDrawShopController_u_l_out",
            time_len = 700
        },
        right_in = {
            name = "uieff_UISakuraDrawShopController_u_l_in",
            time_len = 700
        }
    }
    self._timeEvents = {}
    self._lastUpdateSpineHolderAlpha = -1
end
function UISakuraDrawShopController:LoadDataOnEnter(TT, res, uiParams)
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_HIIRO,
        ECampaignHiiroComponentID.ECAMPAIGN_HIIRO_LOTTERY
    )
    -- 错误处理
    if res and not res:GetSucc() then
        campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
        self:CloseDialog()
    end
end
function UISakuraDrawShopController:OnShow(uiParams)
    self:InitWidget()
    self:_InitData(true, true)
    self:_InitBoxCoverSpine()
    self:_InitDrawBtn()
    self:_InitBoxPosPoint()
    self:_InitShopBtn()
    self:_InitAwardListUi()
    self:_SetAwardListToPageIndex(self._initPageIndex)
    self:_AttachEvents()
end
function UISakuraDrawShopController:OnHide()
    if self._spine then
        self._spine:DestroyCurrentSpine()
        self._spine = nil
    end
    if self._drawTask then
        GameGlobal.TaskManager():KillTask(self._drawTask)
        self._drawTask = nil
    end
    for key, value in pairs(self._timeEvents) do
        GameGlobal.Timer():CancelEvent(value)
    end
    self:_DetachEvents()
end
function UISakuraDrawShopController:_AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:AttachEvent(GameEventType.ItemCountChanged, self._OnItemCountChanged)
end
function UISakuraDrawShopController:_DetachEvents()
    self:DetachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:DetachEvent(GameEventType.ItemCountChanged, self._OnItemCountChanged)
end

function UISakuraDrawShopController:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

function UISakuraDrawShopController:_ForceRefresh(isOpenNew)
    self:Lock("UISakuraDrawShopController:_ForceRefresh")
    self:_InitData(isOpenNew)
    self:_InitDrawBtn()
    --self:_InitShopBtn()
    self:_SetAwardListToPageIndex(self._initPageIndex)
    --延迟一帧解锁 否则可能连续点击抽奖按钮时，按钮不亮 具体原因还不清楚
    self._timeEvents._delayUnlockTimeEvent =
        GameGlobal.Timer():AddEvent(
        1,
        function()
            self:UnLock("UISakuraDrawShopController:_ForceRefresh")
        end
    )
end
function UISakuraDrawShopController:InitWidget()
    --generated--
    ---@type UIDynamicScrollView
    self.awardList = self:GetUIComponent("UIDynamicScrollView", "AwardList")
    self.drawBtnAreaGo = self:GetGameObject("DrawBtnArea")
    self.lockInfoAreaGo = self:GetGameObject("LockInfoArea")
    self.lockInfoText = self:GetUIComponent("UILocalizationText", "LockInfoText")

    self.noRestItemTipsCoverGo = self:GetGameObject("NoRestItemTipsCover")
    ---@type UnityEngine.UI.Image
    self.drawSingleBtn = self:GetUIComponent("Button", "DrawSingleBtn")
    self.drawSingleBtnGreyCoverGo = self:GetGameObject("DrawSingleBtnGreyCover")
    self.drawSingleBtnCanvas = self:GetUIComponent("CanvasGroup", "DrawSingleBtn")
    ---@type UnityEngine.UI.Image
    self.drawMultiBtn = self:GetUIComponent("Button", "DrawMultiBtn")
    self.drawMultiBtnGreyCoverGo = self:GetGameObject("DrawMultiBtnGreyCover")
    self.drawMultiBtnCanvas = self:GetUIComponent("CanvasGroup", "DrawMultiBtn")
    self.drawMultiCostIcon = self:GetUIComponent("Image", "DrawMultiCostIcon")
    self.drawSingleCostIcon = self:GetUIComponent("Image", "DrawSingleCostIcon")
    ---@type UILocalizationText
    self.drawSingleBtnText = self:GetUIComponent("UILocalizationText", "DrawSingleBtnText")
    ---@type UILocalizationText
    self.drawSingleCostText = self:GetUIComponent("UILocalizationText", "DrawSingleCostText")
    ---@type UILocalizationText
    self.drawMultiCostText = self:GetUIComponent("UILocalizationText", "DrawMultiCostText")
    ---@type UILocalizationText
    self.drawMultiBtnText = self:GetUIComponent("UILocalizationText", "DrawMultiBtnText")
    ---@type UILocalizationText
    self.awardBoxPosText = self:GetUIComponent("UILocalizationText", "AwardBoxPosText")

    self.boxLeftBtnGo = self:GetGameObject("BoxLeftBtn")
    self.boxRightBtnGo = self:GetGameObject("BoxRightBtn")
    ---@type UICustomWidgetPool
    local shopBtnGen = self:GetUIComponent("UISelectObjectPath", "ShopBtnGen")
    ---@type UISakuraDrawShopBtn
    self.shopPointBtn = shopBtnGen:SpawnObject("UISakuraDrawShopBtn")

    self.pointNumText = self:GetUIComponent("UILocalizationText", "PointNumText")
    self.boxPicLoader = self:GetUIComponent("RawImageLoader", "BoxPic")

    ---@type UICustomWidgetPool
    local backBtnGen = self:GetUIComponent("UISelectObjectPath", "TopLeft")
    ---@type UICommonTopButton
    self.backBtns = backBtnGen:SpawnObject("UICommonTopButton")
    self.backBtns:SetData(
        function()
            self:CloseDialogWithAnim()
        end,
        function()
            self:ShowDialog("UIHelpController", "UISakuraDrawShopController")
        end
    )
    self.curBoxRestText = self:GetUIComponent("UILocalizationText", "CurBoxRestText")
    self.awardListTitleText = self:GetUIComponent("UILocalizationText", "AwardListTitleText")
    self.grayColor = Color(100 / 255, 100 / 255, 100 / 255)
    self.clientCfg = Cfg.cfg_activity_draw_shop_client[self._campaign._id]
    self.bgAnim = self:GetUIComponent("Animation", "BGCanvas")
    self.uiAnim = self:GetUIComponent("Animation", "uianim")
    self.spineHolderCG = self:GetUIComponent("CanvasGroup", "SpineHolder")
    self.slideAreaGo = self:GetGameObject("TestSlideArea")
    ---@type UnityEngine.RectTransform
    self.selfRect = self:GetUIComponent("RectTransform", "TestSlideArea")
    ---@type UIEventTriggerListener
    self.etl = UICustomUIEventListener.Get(self.slideAreaGo)

    self:RegUIEventTriggerListener(
        function(ped)
            self:OnBeginDrag(ped)
        end,
        function(ped)
            self:OnDrag(ped)
        end,
        function(ped)
            self:OnEndDrag(ped)
        end
    )
    ---
    self.pointParentGO = self:GetGameObject("BoxImgPosPoint")
    self.points = {}
    for index = 1, 10 do
        local trans = GameObjectHelper.FindChild(self.pointParentGO.transform, "p" .. index)
        trans.gameObject:SetActive(false)
        self.points[index] = {}
        self.points[index].trans = trans
        self.points[index].rect = trans:GetComponent("RectTransform")
        self.points[index].image = trans:GetComponent("Image")
    end
    --generated end--
end
function UISakuraDrawShopController:RegUIEventTriggerListener(onBeginDrag, onDrag, onEndDrag)
    self:AddUICustomEventListener(self.etl, UIEvent.BeginDrag, onBeginDrag)
    self:AddUICustomEventListener(self.etl, UIEvent.Drag, onDrag)
    self:AddUICustomEventListener(self.etl, UIEvent.EndDrag, onEndDrag)
end
--region UIEventTriggerListener
---@param ped UnityEngine.EventSystems.PointerEventData
function UISakuraDrawShopController:OnBeginDrag(ped)
    local deltaX = ped.delta.x
    if self:IsEdge(deltaX) then
        return
    end
    --self:UpdateLogoByDelta(deltaX)
    local pos = UISakuraDrawShopController.ScreenPointToLocalPointInRectangle(self.selfRect, ped)
    self._xBegainDrag = pos.x
end
---@param ped UnityEngine.EventSystems.PointerEventData
function UISakuraDrawShopController:OnDrag(ped)
    local pos = UISakuraDrawShopController.ScreenPointToLocalPointInRectangle(self.selfRect, ped)
    self._xCurDrag = pos.x
end
---@param ped UnityEngine.EventSystems.PointerEventData
function UISakuraDrawShopController:OnEndDrag(ped)
    self:InitDragField()
    -- if self.bgLogo.anchoredPosition.x <= self._flipX then
    --     local idx = 0
    --     local isRight = false
    --     if self._ui:IsFlip() then
    --         idx = self._ui:GetIndex() - 1
    --         isRight = false
    --     else
    --         idx = self._ui:GetIndex() + 1
    --         isRight = true
    --     end
    --     if 0 < idx and idx <= self._len then
    --         local duration = self._ui:GetClickArrowDuration()
    --         self._fsm:ChangeState(StateDrawCardPool.ClickArrow, isRight, idx, duration * self._flipRatio)
    --     end
    -- else
    --     self._fsm:ChangeState(StateDrawCardPool.Return)
    -- end
end
---delta < 0 - 向左滑，下一页；
---delta > 0 - 向右滑，上一页
function UISakuraDrawShopController:_UpdateDragSwitch()
    if not self.etl.IsDragging then --没滑动的时候不更新位置
        return
    end
    if not self._xBegainDrag or not self._xCurDrag then
        return
    end
    --计算delta
    local deltaX = self._xCurDrag - self._xBegainDrag --滑动相对x距离
    if deltaX == 0 then
        return
    end
    if self:IsEdge(deltaX) then
        return
    end
    local absDeltaX = math.abs(deltaX)
    if absDeltaX > 100 then
        self:OnEndDrag()
        if deltaX < 0 then
            self:BoxRightBtnOnClick()
        else
            self:BoxLeftBtnOnClick()
        end
    end
    --根据deltaX判断是否该翻转
    --self:UpdateLogoByDelta(deltaX)
    --设置bgLogo位置
    --self._posBGLogo.x = self:ClampBGLogo(self._half - Mathf.Abs(deltaX) * self._maskSpeedTimes, deltaX) --系数表示bgLogo滑动速度是手滑的N倍
    --self.bgLogo.anchoredPosition = self._posBGLogo
    --随bgLogo位置更新UI元素
    --self._ui:OnBGLogoMoving()
    --当bgLogo位置到达配置位置时，强制退出滑动
    -- if self.bgLogo.anchoredPosition.x <= self._flipX then
    --     self:OnEndDrag()
    -- end
end
---@param ped UnityEngine.EventSystems.PointerEventData
function UISakuraDrawShopController.ScreenPointToLocalPointInRectangle(rect, ped)
    local res, pos =
        UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(
        rect,
        ped.position,
        ped.pressEventCamera,
        nil
    )
    return pos
end
function UISakuraDrawShopController:IsEdge(deltaX)
    if deltaX > 0 and self._curPageIndex == 1 then
        return true
    end
    if deltaX < 0 and self._curPageIndex == #self.uiData then
        return true
    end
    return false
end
function UISakuraDrawShopController:InitDragField()
    self._xBegainDrag = nil --开始滑动点x坐标
    self._xCurDrag = nil --当前滑动点x坐标

    self._posBGLogo = Vector2(-667, 0) --bgLogo当前位置
end
--endregion

function UISakuraDrawShopController:_InitData(isOpenNew, isOnShow)
    self.unlockBoxs = {}
    self.uiData = {}
    if self._campaign then
        local component = self._campaign:GetComponent(ECampaignHiiroComponentID.ECAMPAIGN_HIIRO_LOTTERY)
        if component then
            ---@type LotteryComponentInfo
            local cmptInfo = component:GetComponentInfo()
            if cmptInfo then
                self.currencyId = cmptInfo.m_cost_item_id
                self.singlePrice = cmptInfo.m_cost_count
                self.multiTimes = cmptInfo.m_multi_lottery
                self.multiPrice = cmptInfo.m_cost_count * cmptInfo.m_multi_lottery
                --temp
                self.unlockBoxs = cmptInfo.m_unlock_jackpots
                for index, value in ipairs(cmptInfo.m_jackpots) do
                    local itemBox = DCampaignDrawShopItemBox:New()
                    itemBox:Refresh(value, component)
                    table.insert(self.uiData, itemBox)
                end
                local unlockBoxNum = #self.unlockBoxs
                if isOnShow then
                    --选第一个有大奖的奖池 都没有则 选第一个有奖的奖池 都没有则默认第一个奖池
                    self._initPageIndex = self:_GetDefaultPageIndexOnShow()
                else
                    if isOpenNew then
                        if unlockBoxNum > 0 then
                            self._initPageIndex = self.unlockBoxs[unlockBoxNum]
                        else
                            self._initPageIndex = 1
                        end
                    else
                        self._initPageIndex = self._curPageIndex
                    end
                end
            end
        end
    end
end
function UISakuraDrawShopController:CloseDialogWithAnim()
    if self.bgAnim and self.uiAnim then
        self:Lock("UISakuraDrawShopController:CloseDialogWithAnim")
        if self.bgAnim then
            self.bgAnim:Play(self.animNames.out_anim.bg_out)
        end
        if self.uiAnim then
            self.uiAnim:Play(self.animNames.out_anim.ui_out)
        end
        self:StartTask(
            function(TT)
                YIELD(TT, self.animNames.out_anim.time_len)
                self:UnLock("UISakuraDrawShopController:CloseDialogWithAnim")
                self:CloseDialog()
            end,
            self
        )
    end
end
function UISakuraDrawShopController:_InitShopBtn()
    if self.shopPointBtn then
        self.shopPointBtn:SetData(self._campaign, self.currencyId, false, true)
    end
    local totalNum = ClientCampaignDrawShop.GetMoney(self.currencyId)
    self.pointNumText:SetText(totalNum)
    --self._icon:LoadImage(ClientCampaignDrawShop.GetCurrencyImageName(self.currencyId))
end
function UISakuraDrawShopController:_InitAwardListUi()
    self.awardList:InitListView(
        #self.uiData,
        function(scrollview, index)
            return self:_OnGetAwardBoxCell(scrollview, index)
        end
    )
end
function UISakuraDrawShopController:_InitBoxCoverSpine()
    self._spine = self:GetUIComponent("SpineLoader", "spine")
    self._spineGo = self:GetGameObject("spine")
    local uiCfg = Cfg.cfg_sakura_draw_shop_box_ui_client[1]
    if uiCfg and self._spine then
        self._curSpine = uiCfg.CoverBaseSpine
        self._spine:LoadSpine(self._curSpine)
    end
end
function UISakuraDrawShopController:_OnGetAwardBoxCell(scrollview, index)
    local item = scrollview:NewListViewItem("AwardBoxCell")
    local cellPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        cellPool:SpawnObjects("UISakuraDrawShopAwardBoxCell", 1)
    end
    local rowList = cellPool:GetAllSpawnList()
    local itemWidget = rowList[1]
    ---@type UISakuraDrawShopAwardBoxCell
    if itemWidget then
        local itemIndex = index + 1
        itemWidget:InitData(
            self.uiData[itemIndex],
            function(data)
                self:_ShowItemTips(data)
            end
        )
    -- if itemIndex > self._itemGroupCount then
    --     itemWidget:GetGameObject():SetActive(false)
    -- end
    --item:GetComponent("RectTransform").sizeDelta = itemWidget:GetRealSize()
    end
    --scrollview:OnItemSizeChanged(index)
    --UIHelper.RefreshLayout(item:GetComponent("RectTransform"))
    return item
end
function UISakuraDrawShopController:SetPointSelect(index, select)
    if select then
        if self.points[index] then
            self.points[index].image.sprite = self.atlas:GetSprite("legend_chouka_di10")
            self.points[index].rect.sizeDelta = Vector2(68, 26)
        end
    else
        if self.points[index] then
            self.points[index].image.sprite = self.atlas:GetSprite("legend_chouka_di11")
            self.points[index].rect.sizeDelta = Vector2(26, 26)
        end
    end
end
function UISakuraDrawShopController:BoxLeftBtnOnClick(go)
    local nextIndex = self._curPageIndex - 1
    if nextIndex < 1 then
        return
    end
    --anim
    self:PlayLeftOut()
    -- 开启倒计时
    self._timeEvents._swithLeftTimeEvent =
        GameGlobal.Timer():AddEvent(
        self.animNames.left_out.time_len,
        function()
            self:_SetAwardListToPageIndex(nextIndex)
            self:PlayLeftIn()
        end
    )

    --self:_SetAwardListToPageIndex(nextIndex)
end
function UISakuraDrawShopController:BoxRightBtnOnClick(go)
    local nextIndex = self._curPageIndex + 1
    if nextIndex > #self.uiData then
        return
    end
    --anim
    self:PlayRightOut()
    -- 开启倒计时
    self._timeEvents._swithRightTimeEvent =
        GameGlobal.Timer():AddEvent(
        self.animNames.right_out.time_len,
        function()
            self:_SetAwardListToPageIndex(nextIndex)
            self:PlayRightIn()
        end
    )
    --self:_SetAwardListToPageIndex(nextIndex)
end
function UISakuraDrawShopController:OnUpdate(deltaTimeMS)
    --spine的透明度与ui动效保持一致
    if self._spineSke and self.spineHolderCG then
        local curAlpha = self.spineHolderCG.alpha
        if self._lastUpdateSpineHolderAlpha ~= curAlpha then
            self._lastUpdateSpineHolderAlpha = curAlpha
            self._spineSke.color = Color(1, 1, 1, curAlpha)
            self._spineSke.Skeleton.A = curAlpha
        end
    end
    --滑动切换宝箱处理
    self:_UpdateDragSwitch()
end
function UISakuraDrawShopController:PlayLeftOut()
    self:Lock("UISakuraDrawShopController:PlayLeftOut")
    if self.uiAnim then
        self.uiAnim:Play(self.animNames.left_out.name)
    end
    self._timeEvents._leftOutTimeEvent =
        GameGlobal.Timer():AddEvent(
        self.animNames.left_out.time_len,
        function()
            self:UnLock("UISakuraDrawShopController:PlayLeftOut")
        end
    )
end
function UISakuraDrawShopController:PlayLeftIn()
    self:Lock("UISakuraDrawShopController:PlayLeftIn")
    if self.uiAnim then
        self.uiAnim:Play(self.animNames.left_in.name)
    end
    self._timeEvents._leftInTimeEvent =
        GameGlobal.Timer():AddEvent(
        self.animNames.left_in.time_len,
        function()
            self:UnLock("UISakuraDrawShopController:PlayLeftIn")
        end
    )
end
function UISakuraDrawShopController:PlayRightOut()
    self:Lock("UISakuraDrawShopController:PlayRightOut")
    if self.uiAnim then
        self.uiAnim:Play(self.animNames.right_out.name)
    end
    self._timeEvents._rightOutTimeEvent =
        GameGlobal.Timer():AddEvent(
        self.animNames.right_out.time_len,
        function()
            self:UnLock("UISakuraDrawShopController:PlayRightOut")
        end
    )
end
function UISakuraDrawShopController:PlayRightIn()
    self:Lock("UISakuraDrawShopController:PlayRightIn")
    if self.uiAnim then
        self.uiAnim:Play(self.animNames.right_in.name)
    end
    self._timeEvents._rightInTimeEvent =
        GameGlobal.Timer():AddEvent(
        self.animNames.right_in.time_len,
        function()
            self:UnLock("UISakuraDrawShopController:PlayRightIn")
        end
    )
end

function UISakuraDrawShopController:_ShowItemTips(data)
    self:ShowDialog("UISakuraDrawShopTipsController", data)
end
function UISakuraDrawShopController:NoRestItemTipsCoverOnClick(go)
    ToastManager.ShowToast(StringTable.Get("str_sakura_draw_shop_no_item_tips"))
end
function UISakuraDrawShopController:_IsBoxUnlock(boxIndex)
    if self._campaign then
        ---@type LotteryComponent
        local cmpt = self._campaign:GetComponent(ECampaignHiiroComponentID.ECAMPAIGN_HIIRO_LOTTERY)
        if cmpt then
            return cmpt:IsLotteryJackpotUnlock(boxIndex)
        end
    end
    return false
end
function UISakuraDrawShopController:_SetAwardListToPageIndex(index)
    self:SetPointSelect(self._curPageIndex, false)
    self._curPageIndex = index
    self:SetPointSelect(self._curPageIndex, true)

    if self._curPageIndex == 1 then
        self.boxLeftBtnGo:SetActive(false)
        self.boxRightBtnGo:SetActive(true)
    elseif self._curPageIndex >= #self.uiData then
        self.boxLeftBtnGo:SetActive(true)
        self.boxRightBtnGo:SetActive(false)
    else
        self.boxLeftBtnGo:SetActive(true)
        self.boxRightBtnGo:SetActive(true)
    end
    self:_ResetBoxPosText()
    self.awardList:MovePanelToItemIndex(self._curPageIndex - 1, 0)
    self.awardList:RefreshAllShownItem()
    self:_RefreshDrawBtnArea()
    --self:_RefreshSingleDrawBtn()
    --self:_RefreshMultiDrawBtn()
    self:_RefreshBoxTitle()
    self:_RefreshCurBoxRest()
    self:_RefreshCurBoxCover()
end
function UISakuraDrawShopController:_ResetBoxPosText()
    local curIndex = self._curPageIndex
    local str = StringTable.Get("str_sakura_draw_shop_box_title", curIndex)
    --local str = "(" .. curIndex .. "/" .. #self.uiData .. ")"
    self.awardBoxPosText:SetText(str)
end
function UISakuraDrawShopController:_InitDrawBtn()
    self.drawSingleCostText:SetText(self.singlePrice)
    self.drawMultiCostText:SetText(self.multiPrice)

    local singleText = "str_sakura_draw_shop_get_one"
    if self.clientCfg then
        singleText = self.clientCfg.DrawOnceText
    end
    self.drawSingleBtnText:SetText(StringTable.Get(singleText))

    local multiText = "str_sakura_draw_shop_get_multi"
    if self.clientCfg then
        multiText = self.clientCfg.DrawMultiText
    end
    self.drawMultiBtnText:SetText(StringTable.Get(multiText))
    -- self.drawMultiBtnText:SetText(
    --     string.format(
    --         StringTable.Get(multiText),
    --         self:GetNumberCN(self.multiTimes)
    --     )
    -- )
end
function UISakuraDrawShopController:_InitBoxPosPoint()
    local count = #self.uiData
    for index = 1, 10 do
        if index <= count then
            self.points[index].trans.gameObject:SetActive(true)
        else
            self.points[index].trans.gameObject:SetActive(false)
        end
    end
end
function UISakuraDrawShopController:_RefreshDrawBtnArea()
    if not self:_IsBoxUnlock(self._curPageIndex) then
        self.drawBtnAreaGo:SetActive(false)
        self.lockInfoAreaGo:SetActive(true)
        self:_RefreshLockInfoText()
    else
        self.drawBtnAreaGo:SetActive(true)
        self.lockInfoAreaGo:SetActive(false)
        self:_RefreshSingleDrawBtn()
        self:_RefreshMultiDrawBtn()
        self:_RefreshDrawBtnNoItemCover()
    end
end
function UISakuraDrawShopController:_RefreshLockInfoText()
    --todo
    local str = StringTable.Get("str_sakura_draw_shop_box_unlock_intro", self._curPageIndex - 1)
    self.lockInfoText:SetText(str)
end
function UISakuraDrawShopController:_RefreshDrawBtnNoItemCover()
    local hasRestItem = self:_CheckAwardRestSingle()
    self.noRestItemTipsCoverGo:SetActive(not hasRestItem)
end
function UISakuraDrawShopController:_RefreshSingleDrawBtn()
    local bEnableBtn = true
    if not self:_IsBoxUnlock(self._curPageIndex) then
        bEnableBtn = false
    end
    if bEnableBtn then
        bEnableBtn = self:_CheckCurrencyEnable(self.singlePrice)
    end
    if bEnableBtn then
        bEnableBtn = self:_CheckAwardRestSingle()
    end

    self:_EnableSingleDrawBtn(bEnableBtn)
end
function UISakuraDrawShopController:_RefreshMultiDrawBtn()
    local bEnableBtn = true
    if not self:_IsBoxUnlock(self._curPageIndex) then
        bEnableBtn = false
    end
    if bEnableBtn then
        bEnableBtn = self:_CheckCurrencyEnable(self.multiPrice)
    end
    if bEnableBtn then
        bEnableBtn = self:_CheckAwardRestMulti()
    end
    self:_EnableMultiDrawBtn(bEnableBtn)
end
function UISakuraDrawShopController:_RefreshBoxTitle()
    local boxNameText = StringTable.Get("str_sakura_draw_shop_box_title", self._curPageIndex)
    --local tmpText = "<color=#F6A201>" .. boxNameText .. "</color>" .. "- " .. StringTable.Get("str_sakura_draw_shop_award_list_title")
    local tmpText = "<color=#F6A201>" .. boxNameText .. "</color>"
    self.awardListTitleText:SetText(tmpText)
end
function UISakuraDrawShopController:_RefreshCurBoxRest()
    local curBoxRest = 0
    local curBoxTotal = 0
    if self._curPageIndex > #self.uiData then
        return
    end
    local boxData = self.uiData[self._curPageIndex]
    if boxData then
        curBoxRest, curBoxTotal = boxData:GetTotalRestItem()
    end
    local tmpText =
        "(" ..
        StringTable.Get("str_sakura_draw_shop_award_rest_num") ..
            " " .. "<color=#F6A201>" .. curBoxRest .. "</color>" .. "/" .. curBoxTotal .. ")"
    self.curBoxRestText:SetText(tmpText)
end
function UISakuraDrawShopController:_RefreshCurBoxCover()
    local uiCfg = Cfg.cfg_sakura_draw_shop_box_ui_client[self._curPageIndex]
    if uiCfg then
        if self._curSpine and uiCfg.CoverBaseSpine and self._curSpine ~= uiCfg.CoverBaseSpine then
            self._curSpine = uiCfg.CoverBaseSpine
            self._spine:LoadSpine(uiCfg.CoverBaseSpine)
        end
        if self._spine then
            self._spineSke = self._spine.CurrentSkeleton
            if not self._spineSke then
                self._spineSke = self._spine.CurrentMultiSkeleton
            end
            if self._spineSke then
                self._spineSke.AnimationState:SetAnimation(0, uiCfg.IdleAnim, true)
            --self._spineSke.AnimationState:Seek(1)
            end
        end
    end
end
function UISakuraDrawShopController:_CheckCurrencyEnable(price)
    local haveCurrency = self.clientHelper.GetMoney(self.currencyId)
    if haveCurrency >= price then
        return true
    else
        return false
    end
end
function UISakuraDrawShopController:_OnItemCountChanged()
    self:_RefreshSingleDrawBtn()
    self:_RefreshMultiDrawBtn()
    self:_RefreshDrawBtnNoItemCover()
    local totalNum = ClientCampaignDrawShop.GetMoney(self.currencyId)
    self.pointNumText:SetText(totalNum)
end
function UISakuraDrawShopController:_GetDefaultPageIndexOnShow()
    local pageIndex = 1
    if self._campaign then
        ---@type LotteryComponent
        local cmpt = self._campaign:GetComponent(ECampaignHiiroComponentID.ECAMPAIGN_HIIRO_LOTTERY)
        if cmpt then
            for index, value in ipairs(self.unlockBoxs) do
                -- body
                local isNoRestBigReward = cmpt:IsLotteryJeckpotNoRestBigReward(value)
                if not isNoRestBigReward then
                    --有大奖
                    return value
                end
            end
            --都没有大奖 找第一个有奖励的
            for index, value in ipairs(self.unlockBoxs) do
                -- body
                local isEmpty = cmpt:IsLotteryJeckpotEmpty(value)
                if not isEmpty then
                    --有奖
                    return value
                end
            end
        end
    end
    return pageIndex
end
function UISakuraDrawShopController:_CheckAwardRestSingle()
    if self._campaign then
        ---@type LotteryComponent
        local cmpt = self._campaign:GetComponent(ECampaignHiiroComponentID.ECAMPAIGN_HIIRO_LOTTERY)
        if cmpt then
            local isEmpty = cmpt:IsLotteryJeckpotEmpty(self._curPageIndex)
            if isEmpty then
                return false
            else
                return true
            end
        end
    end
    return false
end
function UISakuraDrawShopController:_CheckAwardRestMulti()
    if self._campaign then
        ---@type LotteryComponent
        local cmpt = self._campaign:GetComponent(ECampaignHiiroComponentID.ECAMPAIGN_HIIRO_LOTTERY)
        if cmpt then
            local canDraw = cmpt:IsLotteryJeckpotCanMutliLottery(self._curPageIndex)
            if canDraw then
                return true
            else
                return false
            end
        end
    end
    return false
end
function UISakuraDrawShopController:DrawSingleBtnOnClick(go)
    self:_DoDraw(ECampaignLotteryType.E_CLT_SINGLE)
end
function UISakuraDrawShopController:DrawMultiBtnOnClick(go)
    self:_DoDraw(ECampaignLotteryType.E_CLT_MULTI)
end
function UISakuraDrawShopController:_EnableSingleDrawBtn(enable)
    self.drawSingleBtnGreyCoverGo:SetActive(not enable)
    if enable then
        --self.drawSingleBtnText.color = Color(52 / 255, 52 / 255, 52 / 255)
        --self.drawSingleCostText.color = Color(201 / 255, 26 / 255, 6 / 255)
        --self.drawSingleCostIcon.color = Color.white
    else
        -- self.drawSingleBtnText.color = Color(52 / 255, 52 / 255, 52 / 255)
        -- self.drawSingleCostText.color = Color(103 / 255, 103 / 255, 103 / 255)
        -- self.drawSingleCostIcon.color = Color(1, 1, 1, 0.4)
    end
    self.drawSingleBtn.interactable = enable
    self.drawSingleBtnCanvas.blocksRaycasts = enable
end
function UISakuraDrawShopController:_EnableMultiDrawBtn(enable)
    self.drawMultiBtnGreyCoverGo:SetActive(not enable)

    if enable then
        -- self.drawMultiBtnText.color = Color.white
        -- self.drawMultiCostText.color = Color.white
        -- self.drawMultiCostIcon.color = Color.white
    else
        -- self.drawMultiBtnText.color = Color.white
        -- self.drawMultiCostText.color = Color.white
        -- self.drawMultiCostIcon.color = Color(1, 1, 1, 0.4)
    end
    self.drawMultiBtn.interactable = enable
    self.drawMultiBtnCanvas.blocksRaycasts = enable
end

function UISakuraDrawShopController:GetNumberCN(num)
    if num <= 0 then
        return nil
    elseif num < 11 then
        return StringTable.Get("str_sakura_draw_shop_number_" .. num)
    elseif num < 100 then
        local gewei = num % 10
        local shiwei = math.floor(num / 10)

        local str = ""
        if shiwei == 1 then
            str = str .. StringTable.Get("str_sakura_draw_shop_number_10")
        else
            str =
                str ..
                StringTable.Get("str_sakura_draw_shop_number_" .. shiwei) ..
                    StringTable.Get("str_sakura_draw_shop_number_10")
        end
        if gewei == 0 then
            return str
        else
            return str .. StringTable.Get("str_sakura_draw_shop_number_" .. gewei)
        end
    else
        return StringTable.Get("str_sakura_draw_shop_number_99")
    end
end
function UISakuraDrawShopController:_CheckCanDrawOnceMore(lotteryType)
    if lotteryType == ECampaignLotteryType.E_CLT_SINGLE then
        local bEnable = true
        if not self:_IsBoxUnlock(self._curPageIndex) then
            bEnable = false
        end
        if bEnable then
            bEnable = self:_CheckCurrencyEnable(self.singlePrice)
        end
        if bEnable then
            bEnable = self:_CheckAwardRestSingle()
        end
        return bEnable
    elseif lotteryType == ECampaignLotteryType.E_CLT_MULTI then
        local bEnable = true
        if not self:_IsBoxUnlock(self._curPageIndex) then
            bEnable = false
        end
        if bEnable then
            bEnable = self:_CheckCurrencyEnable(self.multiPrice)
        end
        if bEnable then
            bEnable = self:_CheckAwardRestMulti()
        end
        return bEnable
    end
    return false
end
function UISakuraDrawShopController:_DoDraw(lotteryType)
    --锁住成就弹窗先
    ---@type UIFunctionLockModule
    local funcModule = self:GetModule(RoleModule).uiModule
    funcModule:LockAchievementFinishPanel(true)

    self._drawTask =
        self:StartTask(
        function(TT)
            self:Lock("UISakuraDrawShopController:doDraw")
            local res = AsyncRequestRes:New()
            local getRewards, isOpenNew = self:_SendDrawReq(TT, res, self._curPageIndex, lotteryType)
            if res:GetSucc() then
                local canDrawOnceMore = self:_CheckCanDrawOnceMore(lotteryType)
                local curBoxHasRest = self:_CheckAwardRestSingle()
                --self:_ForceRefresh(isOpenNew)
                if getRewards then
                    self:_RecordRewardsInfo(getRewards, lotteryType, curBoxHasRest, isOpenNew, canDrawOnceMore)
                    self:_ShowDrawAnim(lotteryType)
                else
                    self:UnLock("UISakuraDrawShopController:doDraw")
                end
            else
                --锁住成就弹窗先--解锁
                ---@type UIFunctionLockModule
                local funcModule = self:GetModule(RoleModule).uiModule
                funcModule:LockAchievementFinishPanel(false)
                self:UnLock("UISakuraDrawShopController:doDraw")
                local campaignModule = GameGlobal.GetModule(CampaignModule)
                campaignModule:CheckErrorCode(
                    res.m_result,
                    self._campaign._id,
                    function()
                        self:_ForceRefresh(isOpenNew)
                    end,
                    function()
                        self:CloseDialog()
                    end
                )
            end
        end,
        self
    )
end
function UISakuraDrawShopController:_SendDrawReq(TT, res, boxIndex, lotteryType)
    if self._campaign then
        local component = self._campaign:GetComponent(ECampaignHiiroComponentID.ECAMPAIGN_HIIRO_LOTTERY)
        if component then
            return component:HandleLottery(TT, res, boxIndex, lotteryType)
        end
    end
    res:SetSucc(false)
    return nil
end
---@param record DCampaignDrawShopDrawResultRecord
function UISakuraDrawShopController:_ShowGetReward(record)
    --锁住成就弹窗先--解锁
    ---@type UIFunctionLockModule
    local funcModule = self:GetModule(RoleModule).uiModule
    funcModule:LockAchievementFinishPanel(false)
    self:UnLock("UISakuraDrawShopController:doDraw")
    if not record then
        return
    end
    local rewards = record.m_getRewards
    local lotteryType = record.m_lotteryType
    local curBoxHasRest = record.m_curBoxHasRest
    local isOpenNew = record.m_isOpenNew
    local canDrawOnceMore = record.m_canDrawOnceMore
    local assetAwards = {}
    local tempPets = {}
    if #rewards > 0 then
        for i = 1, #rewards do
            local roleAsset = RoleAsset:New()
            roleAsset.assetid = rewards[i].m_item_id
            roleAsset.count = rewards[i].m_count
            local ispet = self._petModule:IsPetID(roleAsset.assetid)
            if ispet then
                table.insert(tempPets, roleAsset)
            end
            table.insert(assetAwards, roleAsset)
        end
    end
    local cbFunc = nil
    if isOpenNew then
        if self:_CheckIsRestRepeatBox() then
            cbFunc = function()
                self:_LoopBoxRestTips()
            end
        else
            cbFunc = function()
                self:_ConfirmToNextBox()
            end
        end
    elseif not curBoxHasRest then
        cbFunc = function()
            self:_ForceRefresh(false)
        end
    elseif canDrawOnceMore then
        --cbFunc = function()
        --self:_ConfirmDrawOnceMore(lotteryType)
        --end
        cbFunc = function()
            self:_ForceRefresh(false)
        end
    else
        cbFunc = function()
            self:_ForceRefresh(false)
        end
    end
    --local itemRowLimit = 5
    local getItemCtrl = "UIGetItemController"
    -- if #assetAwards > itemRowLimit then
    --     getItemCtrl = "UIGetItemDoubleRowController"
    -- end
    if #tempPets > 0 then
        self:ShowDialog(
            "UIPetObtain",
            tempPets,
            function()
                GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
                self:ShowDialog(getItemCtrl, assetAwards, cbFunc)
            end
        )
    else
        self:ShowDialog(getItemCtrl, assetAwards, cbFunc)
    end
end
function UISakuraDrawShopController:_ConfirmToNextBox()
    local strTitle = StringTable.Get("str_sakura_draw_shop_new_box_unlock_title")
    local strText = StringTable.Get("str_sakura_draw_shop_open_next_text", self._curPageIndex, (self._curPageIndex + 1))
    local curCost = 10
    local okCb = function()
        self:_ForceRefresh(true)
    end
    -- local cancelCb = function()
    --     self:_ForceRefresh(false)
    -- end
    PopupManager.Alert("UICommonMessageBox", PopupPriority.Normal, PopupMsgBoxType.Ok, strTitle, strText, okCb, nil)
end

function UISakuraDrawShopController:_LoopBoxRestTips()
    local strTitle = ""
    --StringTable.Get("str_sakura_draw_shop_new_box_unlock_title")
    local strText = StringTable.Get("str_sakura_draw_shop_loop_box_reset_tips")
    local curCost = 10
    local okCb = function()
        self:_ForceRefresh(true)
    end
    -- local cancelCb = function()
    --     self:_ForceRefresh(false)
    -- end
    PopupManager.Alert("UICommonMessageBox", PopupPriority.Normal, PopupMsgBoxType.Ok, strTitle, strText, okCb, nil)
end
function UISakuraDrawShopController:_ConfirmDrawOnceMore(lotteryType)
    local price = self.singlePrice
    if lotteryType == ECampaignLotteryType.E_CLT_MULTI then
        price = self.multiPrice
    end
    local strText = StringTable.Get("str_sakura_draw_shop_draw_once_more_text", price)
    local okCb = function()
        self:_ForceRefresh(false)
        self:_DoDraw(lotteryType)
    end
    local cancelCb = function()
        self:_ForceRefresh(false)
    end
    PopupManager.Alert(
        "UICommonMessageBox",
        PopupPriority.Normal,
        PopupMsgBoxType.OkCancel,
        "",
        strText,
        okCb,
        nil,
        cancelCb
    )
end
function UISakuraDrawShopController:_RecordRewardsInfo(
    getRewards,
    lotteryType,
    curBoxHasRest,
    isOpenNew,
    canDrawOnceMore)
    if not self.rewardRecord then
        self.rewardRecord = DCampaignDrawShopDrawResultRecord:New()
    end
    self.rewardRecord:Record(getRewards, lotteryType, curBoxHasRest, isOpenNew, canDrawOnceMore)
end
function UISakuraDrawShopController:_ShowDrawAnim(lotteryType)
    --ToastManager.ShowToast("假装有动画")
    local delayTime = 2000
    local criAudioID = CriAudioIDConst.SakuraTenLottery
    local uiCfg = Cfg.cfg_sakura_draw_shop_box_ui_client[self._curPageIndex]
    if uiCfg then
        if self._spine then
            self._spineSke = self._spine.CurrentSkeleton
            if not self._spineSke then
                self._spineSke = self._spine.CurrentMultiSkeleton
            end
            local anim = uiCfg.DrawOnceAnim
            if lotteryType == ECampaignLotteryType.E_CLT_SINGLE then
                anim = uiCfg.DrawOnceAnim
                delayTime = uiCfg.DrawOnceAnimTime
                criAudioID = CriAudioIDConst.SakuraOneLottery
            elseif lotteryType == ECampaignLotteryType.E_CLT_MULTI then
                anim = uiCfg.DrawMultiAnim
                delayTime = uiCfg.DrawMultiAnimTime
                criAudioID = CriAudioIDConst.SakuraTenLottery
            end
            if self._spineSke then
                self._spineSke.AnimationState:SetAnimation(0, anim, false)
                AudioHelperController.PlayUISoundAutoRelease(criAudioID)
            end
        end
    end
    self._timeEvents._delayShowRewardTimeEvent =
        GameGlobal.Timer():AddEvent(delayTime, UISakuraDrawShopController._ShowGetReward, self, self.rewardRecord)

    --after anim end
    -- if self.rewardRecord then
    --     self:_ShowGetReward(self.rewardRecord)
    -- end
end
--抽奖 返回结果isOpenNew时 判断是否是重置了循环奖池
function UISakuraDrawShopController:_CheckIsRestRepeatBox()
    if self._campaign then
        local component = self._campaign:GetComponent(ECampaignHiiroComponentID.ECAMPAIGN_HIIRO_LOTTERY)
        if component then
            ---@type LotteryComponentInfo
            local cmptInfo = component:GetComponentInfo()
            if cmptInfo then
                self.unlockBoxs = cmptInfo.m_unlock_jackpots
                local unlockBoxNum = #self.unlockBoxs
                local newIndex = 1
                if unlockBoxNum > 0 then
                    newIndex = self.unlockBoxs[unlockBoxNum]
                end
                return (self._curPageIndex == newIndex)
            end
        end
    end
    return false
end
