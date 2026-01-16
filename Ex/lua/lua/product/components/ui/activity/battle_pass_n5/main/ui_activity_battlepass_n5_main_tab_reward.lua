---@class UIActivityBattlePassN5MainTabReward:UICustomWidget
_class("UIActivityBattlePassN5MainTabReward", UICustomWidget)
UIActivityBattlePassN5MainTabReward = UIActivityBattlePassN5MainTabReward

--region component help
--- @return LVRewardComponent
function UIActivityBattlePassN5MainTabReward:_GetLVRewardComponent()
    local cmptId = ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_LV_REWARD
    return self._campaign:GetComponent(cmptId)
end

--- @return LVRewardComponentInfo
function UIActivityBattlePassN5MainTabReward:_GetLVRewardComponentInfo()
    local cmptId = ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_LV_REWARD
    return self._campaign:GetComponentInfo(cmptId)
end

--- @return BuyGiftComponent
function UIActivityBattlePassN5MainTabReward:_GetBuyGiftComponent()
    local cmptId = ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_BUY_GIFT
    return self._campaign:GetComponent(cmptId)
end

--- @return BuyGiftComponentInfo
function UIActivityBattlePassN5MainTabReward:_GetBuyGiftComponentInfo()
    local cmptId = ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_BUY_GIFT
    return self._campaign:GetComponentInfo(cmptId)
end

--endregion

function UIActivityBattlePassN5MainTabReward:_GetComponents()
    local backBtns = self:GetUIComponent("UISelectObjectPath", "backBtns")
    ---@type UICommonTopButton
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            if self._callback then
                self._callback()
            end
        end,
        function()
            -- 活动介绍沿用原来版本
            self:ShowDialog("UIHelpController", "UIActivityBattlePassMainController")
        end
    )

    self._anim = self:GetUIComponent("Animation", "root")
    self._red = self:GetGameObject("red")
    self._claimAllBtn = self:GetUIComponent("Button", "claimAllBtn")
end

function UIActivityBattlePassN5MainTabReward:SetData(campaign, callback)
    self._campaign = campaign
    self._callback = callback
    self:_GetComponents()

    self:_SetCG()
    self:_SetSpecialImgTitle()

    -- 设置立绘
    UIActivityBattlePassHelper.SetSpecialImg(
        self._campaign,
        self:GetGameObject("imgRoot"),
        self:GetUIComponent("RawImageLoader", "img"),
        self:GetName(),
        self:GetGameObject("ImgDesc1"),
        self:GetGameObject("ImgDesc2")
    )

    self:_SetRemainingTime()

    self:_Refresh()

    self:_OnScrollMove() --SetRightReward()
end

function UIActivityBattlePassN5MainTabReward:OnShow(uiParams)
    self._isOpen = true
    self._anim_time = 0
    self._scrollRect = self:GetUIComponent("ScrollRect", "dynamicList")

    self._scrollRect.onValueChanged:AddListener(
        function()
            self:_OnScrollMove()
        end
    )
end

function UIActivityBattlePassN5MainTabReward:OnHide()
    self._isOpen = false
    -- self._scrollRect.onValueChanged:RemoveListener(self._OnScrollMove, self)
end

-- upgrade = 0  不更新 expinfo 数据
-- upgrade = 1  更新 expinfo 数据，但不播放 expinfo 动画
-- upgrade = 2  更新 expinfo 数据，并播放 expinfo 动画
function UIActivityBattlePassN5MainTabReward:_Refresh(resetPos, upgrade, anim_PlayIn, anim_ListItem)
    if self._isOpen then
        if upgrade and upgrade ~= 0 then
            self:_SetExpInfo(upgrade == 2)
        end
        self:_SetBuyEliteBtn()
        self:_SetBuyLevelBtn()
        self:_SetClaimAllBtn()

        self:_SetLeftReward()
        self:_SetDynamicList()
        self:_RefreshRightReward()

        self:_CheckRedPointAll()

        if anim_PlayIn then
            self:_PlayAnimIn()
        end
    end
end

function UIActivityBattlePassN5MainTabReward:_SetCG()
    --- @type LVRewardComponent
    local component = self:_GetLVRewardComponent()
    local cfg = component:GetSpecialRewardCfg()

    ---@type UnityEngine.GameObject
    local obj = self:GetGameObject("cg")
    obj:SetActive(false)

    if cfg and cfg.SpecialRewardCg then
        obj:SetActive(true)

        local cfg_cg = Cfg.cfg_cg_book[cfg.SpecialRewardCg]

        ---@type UnityEngine.UI.RawImageLoader
        local img = self:GetUIComponent("RawImageLoader", "imgCG")
        img:LoadImage(cfg_cg.Preview)

        ---@type UILocalizationText
        local txt = self:GetUIComponent("UILocalizationText", "txtCG")
        txt:SetText(StringTable.Get(cfg.SpeicalRewardCgDesc))
    end
end

function UIActivityBattlePassN5MainTabReward:_SetSpecialImgTitle()
    -- 文字配置多期
    ---@type UILocalizationText
    local txtCgName1 = self:GetUIComponent("UILocalizationText", "txtCgName1")
    local strId = UIActivityBattlePassHelper.GetStrIdInCampaign(self._campaign, "str_activity_battlepass_n5_cg_name_1")
    txtCgName1:SetText(StringTable.Get(strId))

    -- 文字配置多期
    ---@type UILocalizationText
    local txtCgName2 = self:GetUIComponent("UILocalizationText", "txtCgName2")
    local strId = UIActivityBattlePassHelper.GetStrIdInCampaign(self._campaign, "str_activity_battlepass_n5_cg_name_2")
    txtCgName2:SetText(StringTable.Get(strId))
end

function UIActivityBattlePassN5MainTabReward:_SetRemainingTime()
    --- @type LVRewardComponentInfo
    local componentInfo = self:_GetLVRewardComponentInfo()

    ---@type UICustomWidgetPool
    local remainingTimePool = self:GetUIComponent("UISelectObjectPath", "remainingTimePool")
    ---@type UIActivityCommonRemainingTime
    self._remainingTime = remainingTimePool:SpawnObject("UIActivityCommonRemainingTime")

    local endTime = componentInfo.m_close_time
    -- self._remainingTime:SetExtraText("txtDesc", "", "str_activity_common_remainingtime_2")
    self._remainingTime:SetData(endTime, nil, nil)
end

function UIActivityBattlePassN5MainTabReward:_SetExpInfo(upgrade)
    --- @type LVRewardComponentInfo
    local componentInfo = self:_GetLVRewardComponentInfo()

    ---@type UICustomWidgetPool
    local expInfoPool = self:GetUIComponent("UISelectObjectPath", "expInfoPool")
    ---@type UIActivityBattlePassN5ExpInfo
    self._expInfo = expInfoPool:SpawnObject("UIActivityBattlePassN5ExpInfo")
    self._expInfo:SetData(self._campaign, componentInfo, upgrade)
end

function UIActivityBattlePassN5MainTabReward:_SetLeftReward()
    --- @type LVRewardComponent
    local component = self:_GetLVRewardComponent()

    ---@type UICustomWidgetPool
    local leftItemPool = self:GetUIComponent("UISelectObjectPath", "leftItem")
    ---@type UIActivityBattlePassN5RewardListItem
    self._leftItem = leftItemPool:SpawnObject("UIActivityBattlePassN5RewardListItem")

    self._leftItem:SetData_Fixed(component)
end

function UIActivityBattlePassN5MainTabReward:_SetRightReward(index)
    self._rightRewardIndex = index

    --- @type LVRewardComponent
    local component = self:_GetLVRewardComponent()

    ---@type UICustomWidgetPool
    local rightItemPool = self:GetUIComponent("UISelectObjectPath", "rightItem")
    ---@type UIActivityBattlePassN5RewardListItem
    self._rightItem = rightItemPool:SpawnObject("UIActivityBattlePassN5RewardListItem")

    self._rightItem:SetData(
        index,
        component,
        function(lv, adv)
            self:_Start_HandleReceiveLevelRewardReq(lv, adv)
        end,
        function(matid, pos)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.ActivityQuestAwardItemClick, matid, pos)
        end
    )
end

function UIActivityBattlePassN5MainTabReward:_SetBuyEliteBtn()
    ---@type BuyGiftComponentInfo
    local componentInfo = self:_GetBuyGiftComponentInfo()

    ---@type UnityEngine.GameObject
    local obj = self:GetGameObject("buyEliteBtnObj")
    -- obj:SetActive(componentInfo.m_buy_state ~= BuyGiftStateType.EBGST_LUXURY)
end

function UIActivityBattlePassN5MainTabReward:_SetBuyLevelBtn()
    --- @type LVRewardComponentInfo
    local componentInfo = self:_GetLVRewardComponentInfo()

    ---@type UnityEngine.GameObject
    local obj = self:GetGameObject("buyLevelBtnObj")
    local flag = componentInfo.m_current_level < componentInfo.m_max_level
    obj:SetActive(flag)
end

function UIActivityBattlePassN5MainTabReward:_SetClaimAllBtn()
    local bShow =
    UIActivityBattlePassHelper.CheckComponentRedPoint(
        self._campaign,
        ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_LV_REWARD
    )

    self._claimAllBtn.interactable = bShow
end

function UIActivityBattlePassN5MainTabReward:_OnScrollMove()
    --- @type LVRewardComponent
    local component = self:_GetLVRewardComponent()

    local showTab = self._dynamicList:GetVisibleItemIDsInScrollView()

    Log.debug("UIActivityBattlePassN5MainTabReward:_OnScrollMove() showTab.Count = ", showTab.Count)
    if showTab.Count == 0 then
        return
    end
    local id = math.floor(showTab[showTab.Count - 1] + 1) -- item 的 id 刚好与等级相对应
    Log.debug("UIActivityBattlePassN5MainTabReward:_OnScrollMove() id = ", id)

    local next = component:GetNextPreviewLvFromConfig(id)
    if next then
        self:_SetRightReward(next)
    end

    local obj = self:GetGameObject("rightItem")
    obj:SetActive(next ~= nil)
end

function UIActivityBattlePassN5MainTabReward:_RefreshRightReward()
    if not self._rightRewardIndex then
        return
    end
    self:_SetRightReward(self._rightRewardIndex)
end

--region DynamicList
function UIActivityBattlePassN5MainTabReward:_SetDynamicListData()
    --- @type LVRewardComponentInfo
    local componentInfo = self:_GetLVRewardComponentInfo()

    self._dynamicListSize = componentInfo.m_max_level
    self._itemCountPerRow = 1
    self._dynamicListRowSize = math.floor((self._dynamicListSize - 1) / self._itemCountPerRow + 1)
end

function UIActivityBattlePassN5MainTabReward:_SetDynamicList()
    self:_SetDynamicListData()

    if not self._isDynamicInited then
        self._isDynamicInited = true

        ---@type UIDynamicScrollView
        self._dynamicList = self:GetUIComponent("UIDynamicScrollView", "dynamicList")

        self._dynamicList:InitListView(
            self._dynamicListRowSize,
            function(scrollView, index)
                return self:_SpawnListItem(scrollView, index)
            end
        )

        self:_SetDynamicListInitPos(self._dynamicList)
    else
        self:_RefreshList(self._dynamicListRowSize, self._dynamicList)
    end
end

function UIActivityBattlePassN5MainTabReward:_SetDynamicListInitPos(list)
    --- @type LVRewardComponent
    local component = self:_GetLVRewardComponent()

    local pos = component:GetShowLvOnEnter() - 1
    list:MovePanelToItemIndex(pos, 0)
end

function UIActivityBattlePassN5MainTabReward:_RefreshList(count, list)
    local contentPos = list.ScrollRect.content.localPosition
    list:SetListItemCount(count)
    list:MovePanelToItemIndex(0, 0)
    list.ScrollRect.content.localPosition = contentPos
end

function UIActivityBattlePassN5MainTabReward:_SpawnListItem(scrollView, index)
    if index < 0 then
        return nil
    end
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UIActivityBattlePassN5RewardListItem", self._itemCountPerRow)
    end
    ---@type UIActivityBattlePassN5RewardListItem[]
    local rowList = rowPool:GetAllSpawnList()
    for i = 1, self._itemCountPerRow do
        local listItem = rowList[i]
        local itemIndex = index * self._itemCountPerRow + i
        if itemIndex > self._dynamicListSize then
            listItem:GetGameObject():SetActive(false)
        else
            listItem:GetGameObject():SetActive(true)
            self:_SetListItemData(listItem, itemIndex)
        end
    end
    return item
end

---@param listItem UIActivityBattlePassN5RewardListItem
function UIActivityBattlePassN5MainTabReward:_SetListItemData(listItem, index)
    --- @type LVRewardComponent
    local component = self:_GetLVRewardComponent()

    listItem:GetGameObject():SetActive(true)
    listItem:SetData(
        index,
        component,
        function(lv, adv)
            self:_Start_HandleReceiveLevelRewardReq(lv, adv)
        end,
        function(matid, pos)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.ActivityQuestAwardItemClick, matid, pos)
        end
    )
end

--endregion

--region req
function UIActivityBattlePassN5MainTabReward:_Start_HandleReceiveLevelRewardReq(lv, adv)
    GameGlobal.GetModule(PetModule):GetAllPetsSnapshoot()
    self:Lock("UIActivityBattlePassN5MainTabReward:_HandleReceiveLevelRewardReq")
    self:StartTask(self._HandleReceiveLevelRewardReq, self, lv, adv)
end

function UIActivityBattlePassN5MainTabReward:_HandleReceiveLevelRewardReq(TT, lv, adv)
    --- @type LVRewardComponentInfo
    local component = self:_GetLVRewardComponent()
    if component then
        local res = AsyncRequestRes:New()
        local rewards = {}
        local reward = component:HandleReceiveLevelReward(TT, res, lv, adv)
        table.insert(rewards, reward)
        self:UnLock("UIActivityBattlePassN5MainTabReward:_HandleReceiveLevelRewardReq")

        if (self.view == nil) then
            return
        end
        if res:GetSucc() then
            UIActivityHelper.ShowUIGetRewards(rewards, true)
        else
            ---@type CampaignModule
            local campaignModule = GameGlobal.GetModule(CampaignModule)
            campaignModule:CheckErrorCode(
                res.m_result,
                self._campaign._id,
                function()
                    self:_Refresh()
                end,
                function()
                    self:SwitchState(UIStateType.UIMain)
                end
            )
        end
    end
end

function UIActivityBattlePassN5MainTabReward:_Start_HandleOneKeyReceiveRewardReq()
    GameGlobal.GetModule(PetModule):GetAllPetsSnapshoot()
    self:Lock("UIActivityBattlePassN5MainTabReward:_HandleOneKeyReceiveRewardReq")
    self:StartTask(self._HandleOneKeyReceiveRewardReq, self)
end

function UIActivityBattlePassN5MainTabReward:_HandleOneKeyReceiveRewardReq(TT)
    --- @type LVRewardComponentInfo
    local component = self:_GetLVRewardComponent()
    if component then
        local res = AsyncRequestRes:New()
        local rewards = component:HandleOneKeyReceiveReward(TT, res)
        self:UnLock("UIActivityBattlePassN5MainTabReward:_HandleOneKeyReceiveRewardReq")

        if (self.view == nil) then
            return
        end
        if res:GetSucc() then
            UIActivityHelper.ShowUIGetRewards(rewards, true)
        else
            ---@type CampaignModule
            local campaignModule = GameGlobal.GetModule(CampaignModule)
            campaignModule:CheckErrorCode(
                res.m_result,
                self._campaign._id,
                function()
                    self:_Refresh()
                end,
                function()
                    self:SwitchState(UIStateType.UIMain)
                end
            )
        end
    end
end

--endregion

--region Event Callback
function UIActivityBattlePassN5MainTabReward:BuyEliteBtnOnClick(go)
    Log.info("UIActivityBattlePassN5MainTabReward:BuyEliteBtnOnClick")
    self:ShowDialog(
        "UIActivityBattlePassN5BuyController",
        function(upgrade)
            self:_Refresh(false, 2, false)
        end
    )
end

function UIActivityBattlePassN5MainTabReward:BuyLevelBtnOnClick(go)
    Log.info("UIActivityBattlePassN5MainTabReward:BuyLevelBtnOnClick")
    self:ShowDialog(
        "UIActivityBattlePassN5BuyLevelController",
        function()
            self:_Refresh(false, 2, true)
        end
    )
end

function UIActivityBattlePassN5MainTabReward:PreviewBtnOnClick(go)
    Log.info("UIActivityBattlePassN5MainTabReward:PreviewBtnOnClick")
    self:ShowDialog("UIActivityBattlePassN5PreviewController")
end

function UIActivityBattlePassN5MainTabReward:ClaimAllBtnOnClick(go)
    Log.info("UIActivityBattlePassN5MainTabReward:ClaimAllBtnOnClick")
    if self._claimAllBtn.interactable then
        self:_Start_HandleOneKeyReceiveRewardReq()
    end
end

function UIActivityBattlePassN5MainTabReward:Skin1BtnOnClick(go)
    Log.info("UIActivityBattlePassN5MainTabReward:Skin1BtnOnClick")

    --- @type LVRewardComponent
    local component = self:_GetLVRewardComponent()
    local cfg1, cfg2 = component:GetSpecialRewardCfg()

    local matid = cfg1.RewardInfo[1]
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ActivityQuestAwardItemClick, matid, nil)
end

function UIActivityBattlePassN5MainTabReward:Skin2BtnOnClick(go)
    Log.info("UIActivityBattlePassN5MainTabReward:Skin2BtnOnClick")

    --- @type LVRewardComponent
    local component = self:_GetLVRewardComponent()
    local cfg1, cfg2 = component:GetSpecialRewardCfg()

    local matid = cfg2.RewardInfo[1]
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ActivityQuestAwardItemClick, matid, nil)
end

--endregion

--region Event
function UIActivityBattlePassN5MainTabReward:AttachEvents()
    self:AttachEvent(GameEventType.CampaignComponentStepChange, self._OnComponentStepChange)
end

function UIActivityBattlePassN5MainTabReward:RemoveEvents()
    self:DetachEvent(GameEventType.CampaignComponentStepChange, self._OnComponentStepChange)
end

function UIActivityBattlePassN5MainTabReward:_OnComponentStepChange(campaign_id, component_id, component_step)
    if self._campaign and self._campaign._id == campaign_id then
        self:_CheckRedPointAll()
    end
end

function UIActivityBattlePassN5MainTabReward:_CheckRedPointAll()
    self:_CheckRedPoint(self._red, ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_LV_REWARD)
end

function UIActivityBattlePassN5MainTabReward:_CheckRedPoint(obj, ...)
    local bShow = self._campaign and UIActivityBattlePassHelper.CheckComponentRedPoint(self._campaign, ...)
    obj:SetActive(bShow)
end

--endregion

--region animation
function UIActivityBattlePassN5MainTabReward:_PlayAnimIn()
    ---@type UnityEngine.Animation
    self.anim = self:GetUIComponent("Animation", "animation")

    local animName = "UIeff_UIActivityBattlePassN5MainTabReward_in2"
    local animTime = 567

    -- self:_SetData() 中因为初始化需要调用一次
    -- UIActivityBattlePassN5MainController:_SetTabPage() 调用的第二次
    -- 其实是第一次进入时需要播放的动效
    -- 后续从购买界面和任务界面返回都播放第二种特效
    if self._anim_time == 0 then
        self._anim_time = 1
        return
    elseif self._anim_time == 1 then
        self._anim_time = 2
        animName = "UIeff_UIActivityBattlePassN5MainTabReward_in"
        animTime = 667
    end

    self:StartTask(
        function(TT)
            local lockName = self:GetName() .. "_PlayAnimIn()"

            self:Lock(lockName)

            self.anim:Play(animName)
            YIELD(TT, animTime)

            self:UnLock(lockName)
        end,
        self
    )
end

function UIActivityBattlePassN5MainTabReward:_PlayAnimOut(callback)
    ---@type UnityEngine.Animation
    self.anim = self:GetUIComponent("Animation", "animation")

    self:StartTask(
        function(TT)
            local lockName = self:GetName() .. "_PlayAnimOut()"

            self:Lock(lockName)

            self.anim:Play("UIeff_UIActivityBattlePassN5MainTabReward_out")
            YIELD(TT, 433)

            self:UnLock(lockName)

            if callback then
                callback()
            end
        end,
        self
    )
end

--endregion
