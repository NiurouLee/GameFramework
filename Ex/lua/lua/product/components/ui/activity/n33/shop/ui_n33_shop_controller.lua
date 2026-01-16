---@class UIN33ShopController : UIController
_class("UIN33ShopController", UIController)
UIN33ShopController = UIN33ShopController

--region 框架函数
function UIN33ShopController:Constructor()
    self.clientHelper = ClientCampaignDrawShop:New()
    self.multiPrice = 1000
    self.uiData = {}
    self.jackpotCount = 0
    self.unlockBoxs = {}
    self._curPageIndex = 1
    self._petModule = GameGlobal.GetModule(PetModule)
    self._uiModule = GameGlobal.GetModule(RoleModule).uiModule
    self._timeEvents = {}
    self._lotteryState = LotteryState.None

    self._animCfg = 
    {
        uieff_UIN33ShopController_in = 18/30 * 1000,
        uieff_UIN33ShopController_out = 5/30 * 1000,
        uieff_UIN33ShopController_tipsImg_in = 10/30 * 1000,
        uieff_UIN33ShopController_tipsImg_out = 10/30 * 1000,
        uieff_UIN33ShopController_UnLockNew_in = 25/30 * 1000,
        uieff_UIN33ShopController_UnLockNew_out = 5/30 * 1000,
        uieff_UIN33ShopController_switch = 16/30 * 1000,
    }
    self._itemUIRowCount = 2 -- item列表一行数量
end

function UIN33ShopController:LoadDataOnEnter(TT, res, uiParams)
    self._campaignModule = GameGlobal.GetModule(CampaignModule)
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_N33,
        ECampaignN33ComponentID.ECAMPAIGN_N33_LOTTERY
    )
    if res and not res:GetSucc() then
        self._campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
        return
    end
    ---@type LotteryComponent
    self._lotteryComponent = self._campaign:GetComponent(ECampaignN33ComponentID.ECAMPAIGN_N33_LOTTERY)
    ---@type LotteryComponentInfo
    self._lotteryComponentInfo = self._campaign:GetComponentInfo(ECampaignN33ComponentID.ECAMPAIGN_N33_LOTTERY)
end

function UIN33ShopController:OnShow(uiParams)
    self:_GetComponents()
    self:_InitData(true, true)
    self:_ShowJackpotsTabList(false, true, true)
    self:_AttachEvents()
    --入场动画加锁
    self:_ShowAnim(self._uiMainAnim, "uieff_UIN33ShopController_in")
    AudioHelperController.RequestUISoundSync(CriAudioIDConst.N24Lottery)
end

function UIN33ShopController:OnHide()
    self:_DetachEvents()

    if self._drawTask then
        GameGlobal.TaskManager():KillTask(self._drawTask)
        self._drawTask = nil
    end
    for key, value in pairs(self._timeEvents) do
        GameGlobal.Timer():CancelEvent(value)
    end
    if self._spineSkipEvent then
        GameGlobal.Timer():CancelEvent(self._spineSkipEvent)
        self._spineSkipEvent = nil
    end
    if self.lockEvent then
        GameGlobal.Timer():CancelEvent(self.lockEvent)
        self.lockEvent = nil
    end
    if self._playAudioTask then
        GameGlobal.TaskManager():KillTask(self._playAudioTask)
        self._playAudioTask = nil
    end
    AudioHelperController.ReleaseUISoundById(CriAudioIDConst.N24Lottery)
end

--endregion

--region 获取组件
function UIN33ShopController:_GetComponents()
    self:_GetCommonComponents()
    self:_GetLotteryComponents()
    self:_GetJackpotsTabListComponents()
    self:_GetShopTipsComponents()
end

---@private
---获取通用组件
function UIN33ShopController:_GetCommonComponents()
    local s = self:GetUIComponent("UISelectObjectPath", "itemInfo")
    ---@type UISelectInfo
    self._tips = s:SpawnObject("UIN33ShopSelectInfo")
    self._tips:PosOnClick()

    local backBtnGen = self:GetUIComponent("UISelectObjectPath", "TopLeft")
    self.backBtns = backBtnGen:SpawnObject("UICommonTopButton")
    self.backBtns:SetData(
        function()
            self:CloseDialogWithAnim()
        end,
        nil,
        function ()
            self:ShowMainUI()
        end
    )
    
    self._uiMainAnim = self:GetUIComponent("Animation","UIN33ShopController")
    self._awardPool = self:GetUIComponent("UIDynamicScrollView", "AwardListPool")
    self._awardPool:InitListView(0,
        function(scrollView, index)
            return self:_InitAwardListUi(scrollView, index)
        end
    )

    self._drawBtnArea = self:GetGameObject("DrawBtnArea")
    self.drawSingleCostText = self:GetUIComponent("UILocalizationText", "DrawSingleCostText")
    self.drawMultiCostText = self:GetUIComponent("UILocalizationText", "DrawMultiCostText")
    self.sinMask = self:GetGameObject("sinMask")
    self.mulMask = self:GetGameObject("mulMask")

    self.pointNumText2 = self:GetUIComponent("UILocalizationText", "PointNumText2")

    self.TopTips = self:GetGameObject("TopTips")
    self.tipsImg = self:GetGameObject("tipsImg")
    self._tipsImgAnim = self:GetUIComponent("Animation","tipsImg")
    self:_ShowTopTips(false)

    self.curBoxRestText = self:GetUIComponent("UILocalizationText", "CurBoxRestText")
end

---@private
function UIN33ShopController:_GetLotteryComponents()
    self._goSpine = self:GetGameObject("spine")
    self.spine = self:GetUIComponent("SpineLoader","spine")
    self.spine:LoadSpine("n33_g_lagan_spine_idle")
    ---@type Spine.Unity.SkeletonGraphic
    self._spineSke = self.spine.CurrentSkeleton
    if not self._spineSke then
        ---@type Spine.Unity.Modules.SkeletonGraphicMultiObject
        self._spineSke = self.spine.CurrentMultiSkeleton
    end
    self._spineSke.AnimationState.Data.DefaultMix = 0

    local function func(trackEntry, e)
        self:_AnimationStateEvent(trackEntry, e)
    end
    self._spineSke.AnimationState.Event = self._spineSke.AnimationState.Event + func


    self.spineSkipGo = self:GetGameObject("SpineSkip")
    self.spineSkipGo:SetActive(false)

    self._dollMechine = UIN33ShopDollMechine:New(self:GetUIComponent("UIView", "UIViewMechine"), self)

    self._goUnLockNew = self:GetGameObject("UnLockNew")
    self._goUnLockNew:SetActive(false)
    self._unlockNewAnim = self:GetUIComponent("Animation","UnLockNew")
    self._imgDoll = self:GetUIComponent("RawImageLoader", "ImgDoll")
    
end

---@private
---获取页签列表组件
function UIN33ShopController:_GetJackpotsTabListComponents()
    ---@type UIDynamicScrollView
    self._jackpotsTabListPool = self:GetUIComponent("UIDynamicScrollView", "jackpotsTabListPool")
    self._isFirst = true
end

function UIN33ShopController:_GetShopTipsComponents()
    local objTipsBg = self:GetGameObject("ObjTipsBg")
    local textTips = self:GetUIComponent("UILocalizationText", "TextTips")
    local rawImageLoader = self:GetUIComponent("RawImageLoader", "rawImageFace")
    self._shopTips = UIN33ShopTipsComponent:New(objTipsBg, textTips, rawImageLoader)
end

--endregion

--region 数据逻辑
function UIN33ShopController:_InitData(isOpenNew, isOnShow)
    self.unlockBoxs = {}
    self.uiData = {}
    if self._lotteryComponent and self._lotteryComponentInfo then
        self.currencyId = self._lotteryComponentInfo.m_cost_item_id
        self.multiPrice = self._lotteryComponentInfo.m_cost_count * self._lotteryComponentInfo.m_multi_lottery
        self.unlockBoxs = self._lotteryComponentInfo.m_unlock_jackpots
        for index, value in ipairs(self._lotteryComponentInfo.m_jackpots) do
            local itemBox = DCampaignDrawShopItemBox:New()
            itemBox:Refresh(value, self._lotteryComponent)
            itemBox:SortByRewardType(value)
            table.insert(self.uiData, itemBox)
        end
        self.jackpotCount = #self.uiData
        local unlockBoxNum = #self.unlockBoxs
        if isOnShow then
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
    self._curPageIndex = self._initPageIndex
end

---@private
---是否可以抽奖
---@return bool
function UIN33ShopController:_IsCanDraw()
    -- 已解锁且还有奖励
    return self:_IsBoxUnlock() and not self.notDrawCount
end

--当前奖池的解锁
function UIN33ShopController:_IsBoxUnlock(idx)
    local index = idx or self._curPageIndex
    if self._lotteryComponent then
        return self._lotteryComponent:IsLotteryJackpotUnlock(index)
    end
    return false
end

function UIN33ShopController:_GetPoolAwards()
    local jackpots = self._lotteryComponentInfo.m_jackpots
    local awards = jackpots[self._curPageIndex]
    return awards
end

function UIN33ShopController:_GetLessDrawCount()
    --检查奖池可抽取
    local awards = self:_GetPoolAwards()
    self.notDrawCount = true
    local canDrawCardCount = 0
    for i = 1, #awards do
        local award = awards[i]
        if award.m_lottery_count and award.m_lottery_count > 0 then
            canDrawCardCount = canDrawCardCount + award.m_lottery_count
            self.notDrawCount = false
        end
    end
    if self.notDrawCount or canDrawCardCount > 10 then
        canDrawCardCount = 10
    end
    return canDrawCardCount
end

function UIN33ShopController:_CheckCurrencyEnable(price)
    local haveCurrency = self.clientHelper.GetMoney(self.currencyId)
    if haveCurrency >= price then
        return true
    else
        return false
    end
end

function UIN33ShopController:_IsNoRestBigReward(idx)
    local value = self.unlockBoxs[idx]
    local isNoRestBigReward = self._lotteryComponent:IsLotteryJeckpotNoRestBigReward(value)
    return isNoRestBigReward
end

---@private
---获取默认显示奖池
function UIN33ShopController:_GetDefaultPageIndexOnShow()
    local pageIndex = 1
    if self._lotteryComponent then
        -- 已解锁且有大奖在
        for index, value in ipairs(self.unlockBoxs) do
            local isNoRestBigReward = self._lotteryComponent:IsLotteryJeckpotNoRestBigReward(value)
            if not isNoRestBigReward then
                return value
            end
        end
        -- 已解锁且非空
        for index, value in ipairs(self.unlockBoxs) do
            local isEmpty = self._lotteryComponent:IsLotteryJeckpotEmpty(value)
            if not isEmpty then
                return value
            end
        end
    end
    return pageIndex
end

function UIN33ShopController:_CheckAwardRestSingle()
    if self._lotteryComponent then
        local isEmpty = self._lotteryComponent:IsLotteryJeckpotEmpty(self._curPageIndex)
        if isEmpty then
            return false
        else
            return true
        end
    end
    return false
end

function UIN33ShopController:_CheckAwardRestMulti()
    if self._lotteryComponent then
        local canDraw = self._lotteryComponent:IsLotteryJeckpotCanMutliLottery(self._curPageIndex)
        if canDraw then
            return true
        else
            return false
        end
    end
    return false
end

function UIN33ShopController:_CheckCanDrawOnceMore(lotteryType)
    if lotteryType == ECampaignLotteryType.E_CLT_SINGLE then
        local bEnable = true
        if not self:_IsBoxUnlock() then
            bEnable = false
        end
        if bEnable then
            bEnable = self:_CheckCurrencyEnable(self._lotteryComponentInfo.m_cost_count)
        end
        if bEnable then
            bEnable = self:_CheckAwardRestSingle()
        end
        return bEnable
    elseif lotteryType == ECampaignLotteryType.E_CLT_MULTI then
        local bEnable = true
        if not self:_IsBoxUnlock() then
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

function UIN33ShopController:_RecordRewardsInfo(getRewards, lotteryType, curBoxHasRest, isOpenNew, canDrawOnceMore)
    if not self.rewardRecord then
        self.rewardRecord = DCampaignDrawShopDrawResultRecord:New()
    end
    self.rewardRecord:Record(getRewards, lotteryType, curBoxHasRest, isOpenNew, canDrawOnceMore)
end

--抽奖 返回结果isOpenNew时 判断是否是重置了循环奖池
function UIN33ShopController:_CheckIsRestRepeatBox()
    if self._lotteryComponentInfo then
        self.unlockBoxs = self._lotteryComponentInfo.m_unlock_jackpots
        local unlockBoxNum = #self.unlockBoxs
        local newIndex = 1
        if unlockBoxNum > 0 then
            newIndex = self.unlockBoxs[unlockBoxNum]
        end
        return self._curPageIndex == newIndex
    end
    return false
end

function UIN33ShopController:_CheckIsCampaignOpen()
    if self._campaign then
        return self._campaign:CheckCampaignOpen()
    end
    return false
end
--endregion

--region 设置UI

function UIN33ShopController:_ShowJackpotsTabList(needTween, onShow, needRefreshAllItem)
    if self._isFirst then
        self:_InitJackpotsTabList()
    end
    self:_RefreshJackpotsTabList(needTween, onShow, needRefreshAllItem)
    self._isFirst = false
end

function UIN33ShopController:_InitJackpotsTabList()
    local count = #self._lotteryComponentInfo.m_jackpots
    local param = UIDynamicScrollViewInitParam:New()
    param.mSmoothDumpRate = 0.1
    self._tabItems = {}
    self._jackpotsTabListPool:InitListView(
        count,
        function(scrollView, index)
            return self:_InitJackpotsTabListInfo(scrollView, index)
        end, param
    )
    self._jackpotsTabListPool.mOnSnapItemFinished = function (uIDynamicScrollView, uIDynamicScrollViewItem)
        -- 挪完了就关掉，不然移动起来会强制规整
        self._jackpotsTabListPool.ItemSnapEnable = false
    end
end

function UIN33ShopController:_InitJackpotsTabListInfo(scrollView, index)
    if index < 0 then
        return nil
    end
    local item = scrollView:NewListViewItem("RowItem")

    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    item.IsInitHandlerCalled = true
    ---@type UIN33TabItem
    local btn = rowPool:SpawnObject("UIN33TabItem")
    local idx = index + 1
    self._tabItems[idx] = btn
    local boxData = self.uiData[idx]
    local islock = not self:_IsBoxUnlock(idx)
    local isbigEmpty = self:_IsNoRestBigReward(idx)
    local curBoxRest, total = boxData:GetTotalRestItem()
    local artDelayTime = 0.1 * 1000 -- 动效需求：两个一组每组延迟0.1s出现
    local yieldTime = index * artDelayTime
    if not self._tabAnim then
        yieldTime = -1
    end
    btn:InitData(idx, islock, isbigEmpty, curBoxRest,
        function(idx)
            self:_JackpotsTabItemClick(idx)
        end, yieldTime
    )

    return item
end

---@param needTween boolean 强制刷新false，第一次打开/手动切换页签/开启新奖池true
---@param needRefreshAllItem boolean 是否需要刷新所有item
function UIN33ShopController:_JackpotsTabItemChange(idx, needTween, needRefreshAllItem)
    self._curPageIndex = idx 
    if needTween then
        self._jackpotsTabListPool.ItemSnapEnable = true
        self._jackpotsTabListPool:SetSnapTargetItemIndex(self._curPageIndex-1)
    end
    if needRefreshAllItem then
        self._jackpotsTabListPool:MovePanelToItemIndex(self._curPageIndex-1, 0)
    else
        self._jackpotsTabListPool:RefreshItemByItemIndex(self._curPageIndex-1)
    end
    self._tabAnim = false
    local yieldTime = 0
    if self._isFirst then
        yieldTime = self._animCfg.uieff_UIN33ShopController_in
    end
    -- 不管是不是needTween，都刷新页签动画，因为是否选中是用动画做的，页签内部做标志位防止重复刷
    for idx, tabItem in pairs(self._tabItems) do
        tabItem:ChangeSelect(self._curPageIndex == idx, yieldTime)
    end
    self:_PageIndexChange(needTween)
end

function UIN33ShopController:_JackpotsTabItemClick(idx)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)
    if self._lotteryState ~= LotteryState.None then
        return
    end
    self:_JackpotsTabItemChange(idx, true, false)
end

---@private
---刷新界面调用
function UIN33ShopController:_RefreshJackpotsTabList(needTween, onShow, needRefreshAllItem)
    local count = #self._lotteryComponentInfo.m_jackpots
    self._tabItems = {}
    self._tabAnim = onShow
    self._jackpotsTabListPool:SetListItemCount(count)
    self:_JackpotsTabItemChange(self._curPageIndex, needTween, needRefreshAllItem)
end

function UIN33ShopController:_PageIndexChange(needTween)
    self:_RefreshAwardListUi()
    self:_RefreshCurBoxRest()
    self:_RefreshDrawBtn()
    self:_ChangeIdleShopTips()
    self:_RefreshDollMechine()
    if needTween then
        self:_ShowAnim(self._uiMainAnim, "uieff_UIN33ShopController_switch")
    end
end

---@private
---未解锁和抽空用UI，解锁且能抽用spine
function UIN33ShopController:_RefreshDollMechine()
    local unLock = self:_IsBoxUnlock()
    local canDraw = not self.notDrawCount
    self._goSpine:SetActive(unLock and canDraw)
    local dollMechineState = UIN33ShopDollMechineState.CanDraw
    if unLock and canDraw then
        self:_ShowSpineAnimIdle()
    elseif not unLock then
        dollMechineState = UIN33ShopDollMechineState.Lock
    elseif not canDraw then
        dollMechineState = UIN33ShopDollMechineState.Empty
    end
    self._dollMechine:RefreshState(dollMechineState,self._curPageIndex)
end

function UIN33ShopController:_GetAwardListRow()
    local awards = self:_GetPoolAwards()
    return math.ceil(#awards / self._itemUIRowCount)
end

--奖励列表
function UIN33ShopController:_InitAwardListUi(scrollView, index)
    if index < 0 then
        return nil
    end
    local item = scrollView:NewListViewItem("RowItem")

    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if not item.IsInitHandlerCalled then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UIN33ShopAwardCell", self._itemUIRowCount)
    end
    local rowList = rowPool:GetAllSpawnList()
    local awards = self:_GetPoolAwards()
    local unlock = self:_IsBoxUnlock()
    for i = 1, self._itemUIRowCount do
        ---@type UIN33ShopAwardCell
        local btn = rowList[i]
        local awardIndex = index * self._itemUIRowCount + i
        local artDelayTime = 0.1 * 1000 -- 动效需求：两个一组每组延迟0.1s出现
        local yieldTime = index * artDelayTime
        local data = awards[awardIndex]
        if not self._showAwardCellAnim then
            yieldTime = -1
        end
        btn:InitN33ShopAwardCellData(data,function(data, itemInfoCallback,unlock,yieldTime,isTips)
            self:_ShowItemTips(data, itemInfoCallback,unlock,yieldTime,isTips)
        end,unlock,yieldTime)
    end

    return item
end

function UIN33ShopController:_RefreshAwardListUi()
    local count = self:_GetAwardListRow()
    self._showAwardCellAnim = true -- 防止后续滑动的时候也刷动画
    self._awardPool:SetListItemCount(count)
    self._awardPool:MovePanelToItemIndex(0, 0)
    self._showAwardCellAnim = false
end

--tips
---@param data AwardInfo
function UIN33ShopController:_ShowItemTips(data, itemInfoCallback,unlock,yieldTime,isTips)
    if self._lotteryState ~= LotteryState.None then
        return
    end
    self._tips:SetData(data, itemInfoCallback,unlock,yieldTime,isTips)
end

function UIN33ShopController:_RefreshCurBoxRest()
    local curBoxRest = 0
    local curBoxTotal = 0

    local boxData = self.uiData[self._curPageIndex]
    if boxData then
        curBoxRest, curBoxTotal = boxData:GetTotalRestItem()
    end
    local tmpText = string.format("<color=#ce5645><color=#F2aa00>%d</color>/%d</color>", curBoxRest, curBoxTotal) 
    self.curBoxRestText:SetText(tmpText)
end


function UIN33ShopController:_RefreshDrawBtn()
    self:_SetPointNumber()
    self:_ShowOrHideDrawBtn()
    self:_EnableDrawBtn()
end

function UIN33ShopController:_ShowOrHideDrawBtn()
    local enable = self:_IsCanDraw()
    self._drawBtnArea:SetActive(enable)
end

function UIN33ShopController:_EnableDrawBtn()
    self.sinMask:SetActive(not self.singleCostEnough)
    self.mulMask:SetActive(not self.muliCostEnough)
end

--抽卡需要的材料数量
function UIN33ShopController:_SetPointNumber()
    local totalNum = ClientCampaignDrawShop.GetMoney(self.currencyId)

    local count = self:_GetLessDrawCount()

    self.drawSingleCostText:SetText(self._lotteryComponentInfo.m_cost_count)
    self.drawMultiCostText:SetText(self._lotteryComponentInfo.m_cost_count*count)

    self.singleCostEnough = true
    if totalNum >= self._lotteryComponentInfo.m_cost_count then
        --self.drawSingleCostText.color = Color(255/255,234/255,183/255,1)
        self.singleCostEnough = true
    else
        --self.drawSingleCostText.color = Color.red
        self.singleCostEnough = false
    end
    self.muliCostEnough = true
    if totalNum >= self._lotteryComponentInfo.m_cost_count*count then
        --self.drawMultiCostText.color = Color(255/255,234/255,183/255,1)
        self.muliCostEnough = true
    else
        --self.drawMultiCostText.color = Color.red
        self.muliCostEnough = false
    end
    self:_SetTopNumber()
end

function UIN33ShopController:_SetTopNumber()
    local totalNum = ClientCampaignDrawShop.GetMoney(self.currencyId)
    self.pointNumText2:SetText(totalNum)
end

function UIN33ShopController:_ChangeIdleShopTips()
    local tens = LotteryRewardState.HasBigReward
    if not self:_IsBoxUnlock() then
        tens = LotteryRewardState.NotOpen
    elseif self.notDrawCount then
        tens = LotteryRewardState.NoReward
    elseif self:_IsNoRestBigReward(self._curPageIndex) then
        tens = LotteryRewardState.NoBigReward
    end
    self._shopTips:FillUi(LotteryShopState.Idle, self._curPageIndex, tens, 0)
end

function UIN33ShopController:_ShowTopTips(show)
    self.TopTips:SetActive(show)
    self.tipsImg:SetActive(show)
end

function UIN33ShopController:_ShowAnim(anim, id, callback, t)
    local time = self._animCfg[id]
    self:StartTask(function (TT) 
        self:Lock("UIN33ShopController:_ShowAnim_1")
        anim:Play(id)
        YIELD(TT,time)
        self:UnLock("UIN33ShopController:_ShowAnim_1")
        if callback then  
            callback(t)
        end 
    end)
end
--endregion

--region 事件
function UIN33ShopController:_AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:AttachEvent(GameEventType.ItemCountChanged, self._OnItemCountChanged)
    self:AttachEvent(GameEventType.ShopForceRefresh, self._ForceRefresh)
end

function UIN33ShopController:_DetachEvents()
    self:DetachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:DetachEvent(GameEventType.ItemCountChanged, self._OnItemCountChanged)
    self:DetachEvent(GameEventType.ShopForceRefresh, self._ForceRefresh)
end

function UIN33ShopController:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

function UIN33ShopController:_OnItemCountChanged()
    self:_SetPointNumber()
    self:_EnableDrawBtn()
end

--强制刷新
function UIN33ShopController:_ForceRefresh(isOpenNew)
    self:Lock("UIN33ShopController:_ForceRefresh")
    self:_InitData(isOpenNew)
    self:_ShowJackpotsTabList(false, false, isOpenNew)
    self._timeEvents._delayUnlockTimeEvent =
        GameGlobal.Timer():AddEvent(
        1,
        function()
            self:UnLock("UIN33ShopController:_ForceRefresh")
        end
    )
end

--endregion

--region 点击函数

--关闭
function UIN33ShopController:CloseDialogWithAnim()
    if self._lotteryState ~= LotteryState.None then
        return
    end
    --local function func()
        local campModule = GameGlobal.GetModule(CampaignModule)
        campModule:CampaignSwitchState(true, UIStateType.UIActivityN33MainController, UIStateType.UIMain, {nil,false}, self._campaign._id)
    --end
    --self:_ShowAnim(self._uiMainAnim, "uieff_UIN33ShopController_out", func)
end

--home
function UIN33ShopController:ShowMainUI()
    if self._lotteryState ~= LotteryState.None then
        return
    end
    if not self:_CheckIsCampaignOpen() then
        ToastManager.ShowToast(StringTable.Get("str_n33_activity_end"))
    end
    self:SwitchState(UIStateType.UIMain)
end

function UIN33ShopController:TopTipsOnClick(go)
    self:_ShowAnim(self._tipsImgAnim, "uieff_UIN33ShopController_tipsImg_out", self._ShowTopTips, self)
end

function UIN33ShopController:ItemBg1OnClick(go)
    self:_ShowTopTips(true)
    self:_ShowAnim(self._tipsImgAnim, "uieff_UIN33ShopController_tipsImg_in")
end

function UIN33ShopController:ItemBg2OnClick(go)
    self:_ShowTopTips(true)
    self:_ShowAnim(self._tipsImgAnim, "uieff_UIN33ShopController_tipsImg_in")
end

function UIN33ShopController:_ClickDrawBtnCheck(costEnough)
    if not self:_CheckIsCampaignOpen() then
        self:ShowMainUI()
        return false
    end
    if not self:_IsCanDraw() then
        return false
    end
    --不足
    if not costEnough then
        ToastManager.ShowToast(StringTable.Get("str_activity_error_9001"))
        return false
    end
    return true
end

function UIN33ShopController:DrawSingleBtnOnClick(go)
    if not self:_ClickDrawBtnCheck(self.singleCostEnough) then
        return 
    end
    self:_DoDraw(ECampaignLotteryType.E_CLT_SINGLE)
end

function UIN33ShopController:DrawMultiBtnOnClick(go)
    if not self:_ClickDrawBtnCheck(self.muliCostEnough) then
        return 
    end
    self:_DoDraw(ECampaignLotteryType.E_CLT_MULTI)
end

function UIN33ShopController:SpineSkipOnClick(go)
    if not self._spineSkipEvent then
        return
    end
    GameGlobal.Timer():CancelEvent(self._spineSkipEvent)
    self._spineSkipEvent = nil
    self:ShowSpineAnim2()
    if self._playerID then
        AudioHelperController.StopUISound(self._playerID)
    end
    if self._playAudioTask then
        GameGlobal.TaskManager():KillTask(self._playAudioTask)
        self._playAudioTask = nil
    end
end

function UIN33ShopController:RuleDescriptionBtnOnClick(go)
    if self._lotteryState ~= LotteryState.None then
        return
    end
    self:ShowDialog("UIIntroLoader", "UIN33ShopIntro", MaskType.MT_BlurMask)
end

function UIN33ShopController:UnlockNewOnClick(go)
    self:_ShowAnim(self._unlockNewAnim, "uieff_UIN33ShopController_UnLockNew_out", self._CloseUnlockNew, self)
end
--endregion

--region 抽奖

function UIN33ShopController:_DoDraw(lotteryType)
    if self._lotteryState ~= LotteryState.None then
        return
    end
    self._uiModule:LockAchievementFinishPanel(true)
    self._lotteryState = LotteryState.WaitRequestResult
    self._drawTask = self:StartTask(self._DrwaTask, self, lotteryType)
end


function UIN33ShopController:_ChangeLotteryShopTips(claw)
    local ones = 0
    if claw == N33LotterySpineState.ClawUp then
        ones = self:_GetAwardLRType()
    end
    self._shopTips:FillUi(LotteryShopState.Lottery, self._lotteryType, claw, ones)
end

function UIN33ShopController:_DrwaTask(TT, lotteryType)
    local res = AsyncRequestRes:New()
    local getRewards, isOpenNew = self:_SendDrawReq(TT, res, self._curPageIndex, lotteryType)
    if res:GetSucc() then
        local canDrawOnceMore = self:_CheckCanDrawOnceMore(lotteryType)
        local curBoxHasRest = self:_CheckAwardRestSingle()
        if getRewards then
            self._drawBtnArea:SetActive(false)
            self:_RecordRewardsInfo(getRewards, lotteryType, curBoxHasRest, isOpenNew, canDrawOnceMore)
            self:_ShowDrawSpineAnim(TT, lotteryType)
        else
            self._lotteryState = LotteryState.None
        end
        --audio
        self._playAudioTask = GameGlobal.TaskManager():StartTask(
            function(TT)
                YIELD(TT, 500)
                self._playerID = AudioHelperController.PlayUISoundResource(CriAudioIDConst.N24Lottery, false)
            end,
            self
        )
    else
        self._lotteryState = LotteryState.None
        self._uiModule:LockAchievementFinishPanel(false)
        self._campaignModule:CheckErrorCode(
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
end

function UIN33ShopController:_SendDrawReq(TT, res, boxIndex, lotteryType)
    if self._lotteryComponent then
        return self._lotteryComponent:HandleLottery(TT, res, boxIndex, lotteryType)
    end
    res:SetSucc(false)
    return nil
end

---@param record DCampaignDrawShopDrawResultRecord
function UIN33ShopController:_ShowGetReward(record)
    self:_ShowSpineAnimIdle()
    self._lotteryState = LotteryState.None
    self._uiModule:LockAchievementFinishPanel(false)
    if not record then
        return
    end
    local rewards = record.m_getRewards
    local isOpenNew = record.m_isOpenNew
    local tempPets, assetAwards, hasBig = self:_MakeAward(rewards)
    local cbFunc = self:_MakeDialogCallBack(isOpenNew, hasBig)
    local getItemCtrl = "UIN33LotteryGetItem"
    if #tempPets > 0 then
        self:ShowDialog(
            "UIPetObtain",
            tempPets,
            function()
                GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
                self:ShowDialog(getItemCtrl, assetAwards, cbFunc, true)
            end
        )
    else
        self:ShowDialog(getItemCtrl, assetAwards, cbFunc, true)
    end
end

function UIN33ShopController:_MakeAward(rewards)
    local tempPets = {}
    local assetAwards = {}
    local bigNum = 0
    if #rewards > 0 then
        for i = 1, #rewards do
            local roleAsset = RoleAsset:New()
            roleAsset.assetid = rewards[i].m_item_id
            roleAsset.count = rewards[i].m_count
            roleAsset.type = rewards[i].m_reward_type
            local ispet = self._petModule:IsPetID(roleAsset.assetid)
            if ispet then
                table.insert(tempPets, roleAsset)
            end
            -- 大奖数量
            if rewards[i].m_is_big_reward then
                bigNum = bigNum + 1
            end
            -- 排序
            if rewards[i].m_reward_type == ECampaignLRType.E_CLRT_rare then
                table.insert(assetAwards, 1, roleAsset)
            elseif rewards[i].m_reward_type == ECampaignLRType.E_CLRT_big then
                local rareIndex = bigNum + 1 -- 在大奖后边，都是小奖顺序则无所谓
                table.insert(assetAwards, rareIndex, roleAsset)
            else
                table.insert(assetAwards, roleAsset)
            end
        end
    end
    return tempPets, assetAwards, bigNum>0
end

function UIN33ShopController:_MakeDialogCallBack(isOpenNew, hasBig)
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
    else
        --检查有没有大奖
        if hasBig then
            cbFunc = function()
                self:_LoopBoxRestTips()
            end
        else
            cbFunc = function()
                GameGlobal.EventDispatcher():Dispatch(GameEventType.ShopForceRefresh,false)
            end
        end    
    end
    return cbFunc
end

function UIN33ShopController:_ConfirmToNextBox()
    self._goUnLockNew:SetActive(true)
    local unlockBoxNum = #self.unlockBoxs
    local newIndex = 1
    if unlockBoxNum > 0 then
        newIndex = self.unlockBoxs[unlockBoxNum]
    end
    local uiCfg = Cfg.cfg_n33_shop_ui[unlockBoxNum]
    if not uiCfg then
        return
    end
    self._imgDoll:LoadImage(uiCfg.OpenNewImage)
    self:_ShowAnim(self._unlockNewAnim, "uieff_UIN33ShopController_UnLockNew_in")
end

function UIN33ShopController:_LoopBoxRestTips()
    local strTitle = ""
    local strText = StringTable.Get("str_n33_shop_loop_box_reset_tips")
    local okCb = function()
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShopForceRefresh,true)
    end
    PopupManager.Alert("UICommonMessageBox", PopupPriority.Normal, PopupMsgBoxType.Ok, strTitle, strText, okCb, nil)
end

function UIN33ShopController:_CloseUnlockNew()
    self._goUnLockNew:SetActive(false)
    self:_ForceRefresh(true)
end
--endregion

--region Spine

local indexToName = 
{
    [1] = "cz",
    [2] = "ly",
    [3] = "f",
    [4] = "qt",
    [5] = "bo",
    [6] = "pl",
}

local spineAnimName =
{
    "_danchou",
    "_danchou_shanguang",
    "_danchou_shibai",
    "_idle",
    "_shilian",
    "_shilian_shanguang",
    "_shilian_shibai",
}

function UIN33ShopController:PlaySpineAnimation(spineAnim,loop)
    if not self._spineSke then
        Log.debug("###[UIMainLobbyController] not self._spineSke")
        return
    end
    local entry
    local func = function()
        self._spineSke:Initialize(true)
        entry = self._spineSke.AnimationState:SetAnimation(0, spineAnim, loop)
    end
    local succ = pcall(func)
    if not succ then
        Log.error("###[UIN33ShopController] set spineanim fail ! anim[",spineAnim,"]")
        return
    end
    if not entry then
        Log.error("###[UIN33ShopController] entry is nil ! anim[",spineAnim,"]")
        return
    end

    local function func(trackEntry, e)
        self:_AnimationStateEvent(trackEntry, e)
    end
    entry.Event = entry.Event - func
    entry.Event = entry.Event + func
    self._doEvent = false

    local anim = entry.Animation
    local duration = anim.Duration
    local yieldTime = math.floor(duration * 1000)
    return yieldTime
end

-- 钩爪下
function UIN33ShopController:_ShowDrawSpineAnim(TT, lotteryType)
    self._lotteryState = LotteryState.ShowRewards
    local spineAnim = nil
    self._lotteryType = lotteryType
    local lRType = self:_GetAwardLRType()
    local lastName
    if lotteryType == ECampaignLotteryType.E_CLT_SINGLE then
        if lRType == ECampaignLRType.E_CLRT_common then
            lastName = spineAnimName[3]
        elseif lRType == ECampaignLRType.E_CLRT_big then
            lastName = spineAnimName[1]
        else
            lastName = spineAnimName[2]
        end
    else
        if lRType == ECampaignLRType.E_CLRT_common then
            lastName = spineAnimName[7]
        elseif lRType == ECampaignLRType.E_CLRT_big then
            lastName = spineAnimName[5]
        else
            lastName = spineAnimName[6]
        end
    end
    spineAnim = indexToName[self._curPageIndex] .. lastName
    self:_ChangeLotteryShopTips(N33LotterySpineState.ClawDown)
    local yieldTime = self:PlaySpineAnimation(spineAnim,false)
    if yieldTime and yieldTime>0 then
        self.spineSkipGo:SetActive(true)
        self._spineSkipEvent = GameGlobal.Timer():AddEvent(yieldTime,function()
            self:_ShowGetReward(self.rewardRecord)
            self.spineSkipGo:SetActive(false)
        end)
    else 
        self:_ShowGetReward(self.rewardRecord)
    end
end

function UIN33ShopController:_AnimationStateEvent(trackEntry, e)
    -- e.Event没导出lua，但是这个需求只需要执行一次事件即可，也没啥必要导出了，拿个标志位判断一下是否执行过
    if self._doEvent then
        return
    end
    self._doEvent = true
    self:_ChangeLotteryShopTips(N33LotterySpineState.ClawUp)
end

-- 钩爪上
function UIN33ShopController:ShowSpineAnim2()
    self.spineSkipGo:SetActive(false)
    self:_ShowGetReward(self.rewardRecord)
    self:_ShowSpineAnimIdle()
end

function UIN33ShopController:_GetAwardLRType()
    local lRType = 0
    lRType = ECampaignLRType.E_CLRT_common 
    local rewards = self.rewardRecord.m_getRewards
    for i = 1, #rewards do
        if rewards[i].m_reward_type == ECampaignLRType.E_CLRT_rare then
            lRType = ECampaignLRType.E_CLRT_rare
            break -- 别继续找了，有大奖
        elseif rewards[i].m_reward_type == ECampaignLRType.E_CLRT_big then
            lRType = ECampaignLRType.E_CLRT_big --改为小奖
        else
            -- 不变
        end
    end
    return lRType
end

function UIN33ShopController:_ShowSpineAnimIdle()
    local spineAnim = indexToName[self._curPageIndex] .. spineAnimName[4]
    self:PlaySpineAnimation(spineAnim,true)
end

--endregion