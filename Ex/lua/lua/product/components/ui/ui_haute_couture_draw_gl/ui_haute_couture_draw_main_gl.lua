---@class UIHauteCoutureDrawMainGL:UIHauteCoutureDrawBase
_class("UIHauteCoutureDrawMainGL", UIHauteCoutureDrawBase)
UIHauteCoutureDrawMainGL = UIHauteCoutureDrawMainGL

function UIHauteCoutureDrawMainGL:Constructor()
    self._allPrizes = {}
    self._EnterAniKey = nil
end

function UIHauteCoutureDrawMainGL:OnShow(uiParams)
    self:InitWidgets()
    self:_OnValue()
    self:AttachEvent(GameEventType.ItemCountChanged, self.ItemCountChanged)
    -- self:_LoadVideo()
    self:_LoadPrize()
    self:CheckAllPrizeCollected()
    self:StartTask(self.CheckAndDoEnterAni, self)
end

function UIHauteCoutureDrawBgGL:OnHide()
    self:DetachEvent(GameEventType.ItemCountChanged, self.ItemCountChanged)
end

function UIHauteCoutureDrawMainGL:GetEnterAniKey()
    if not self._EnterAniKey then
        ---@type RoleModule
        local roleModule = GameGlobal.GetModule(RoleModule)
        local pstId = roleModule:GetPstId()
        self._EnterAniKey = pstId .. "LashShowCoutureEnter"
    end
    return self._EnterAniKey
end

function UIHauteCoutureDrawMainGL:InitWidgets()
    --通用Widgets初始化
    self:InitWidgetsBase()

    --个性化Widgets初始化
    ---@type UICustomWidgetPool
    self._prizeTop = self:GetUIComponent("UISelectObjectPath", "PrizeListTop")
    ---@type UICustomWidgetPool
    self._prizeBottom = self:GetUIComponent("UISelectObjectPath", "PrizeListBottom")
    self._specialItem = self:GetUIComponent("UISelectObjectPath", "SpecialItem")

    self._rootGo = self:GetGameObject("Root")
    self._rootAni = self:GetUIComponent("Animation", "RootAni")
    ---@type UICustomWidgetPool
    self._enterAniPool = self:GetUIComponent("UISelectObjectPath", "EnterAnimation")
    self._enterAniGo = self:GetGameObject("EnterAnimation")

    self.drawTitle = self:GetUIComponent("RollingText", "drawTitle")
end

function UIHauteCoutureDrawMainGL:GetCoinId()
    return 3000266
end

function UIHauteCoutureDrawMainGL:_OnValue()
    --self._moneyIcon = self._uiCommonAtlas:GetSprite("toptoon_3000266")
    self.drawTitle:RefreshText(StringTable.Get("str_senior_skin_draw_des_gl"))
end

--加载Video
function UIHauteCoutureDrawMainGL:_LoadVideo()
    local url = ResourceManager:GetInstance():GetAssetPath(self.controller._cfg.VideoName .. ".mp4", LoadType.VideoClip)
    self:LoadVideo(url)
end

--加载Prize
function UIHauteCoutureDrawMainGL:_LoadPrize()
    local specialIndex = 0
    if self.controller._specialIdx then
        specialIndex = self.controller._specialIdx
    end

    local prizes = self.controller._prizes
    local idList = {} -- RewardSortOrder
    for i = 1, table.count(prizes) do
        local prize = prizes[i]
        if specialIndex ~= prize.RewardSortOrder then
            table.insert(idList, prize.RewardSortOrder)
        end
    end

    --top row,3 item
    local topItemNum = 3
    self._prizeTop:SpawnObjects("UIHauteCoutureDrawPrizeItemGL", topItemNum)
    --bottom row
    self._prizeBottom:SpawnObjects("UIHauteCoutureDrawPrizeItemGL", #idList - topItemNum)

    local topPools = self._prizeTop:GetAllSpawnList()
    for i = 1, #topPools do
        local item = topPools[i]
        local idx = idList[i]
        item:SetData(idx, self.controller._componentId)
        table.insert(self._allPrizes, item)
    end

    local bottomPoos = self._prizeBottom:GetAllSpawnList()
    for i = 1, #bottomPoos do
        local item = bottomPoos[i]
        local idx = idList[i + topItemNum]
        item:SetData(idx, self.controller._componentId)
        table.insert(self._allPrizes, item)
    end

    if specialIndex then
        local item = self._specialItem:SpawnObject("UIHauteCoutureDrawPrizeItemGL")
        item:SetData(specialIndex, self.controller._componentId, true)
        table.insert(self._allPrizes, item)
    end

    self:_RefreshReward()
end

--刷新奖励
function UIHauteCoutureDrawMainGL:_RefreshReward()
    if self._allPrizes then
        for k, v in pairs(self._allPrizes) do
            local itemId = v:GetCfgID()
            local state = table.icontains(self.controller._componentInfo.shake_win_ids, itemId)
            v:Flush(state)
            v:SetGray(false)
        end
    end

    if self:IsAllAwardCollected() then
        self._drawBtnOj:SetActive(false)
    else
        local tmp =
            Cfg.cfg_component_senior_skin_cost {
            ComponentID = self.controller._componentId,
            SeqID = self.controller._componentInfo.shake_num + 1
        }

        if not tmp then
            return
        end
        local curDrawCost = tmp[1]

        -- local itemCfg = Cfg.cfg_top_tips[curDrawCost.CostItemID]
        -- if itemCfg then
        --    -- self._moneyIcon.sprite = self._uiCommonAtlas:GetSprite(itemCfg.Icon)
        -- end
        local itemModule = GameGlobal.GetModule(ItemModule)
        local count = itemModule:GetItemCount(curDrawCost.CostItemID)

        if count < curDrawCost.CostItemCount then
            self._moneyNum:SetText("<color=#f83e13>" .. curDrawCost.CostItemCount .. "</color>")
        else
            self._moneyNum:SetText(curDrawCost.CostItemCount)
        end

        self._freeGo:SetActive(curDrawCost.CostItemCount <= 0)
        self._redGo:SetActive(curDrawCost.CostItemCount <= 0)
        self._countParent:SetActive(curDrawCost.CostItemCount > 0)
    end
end

function UIHauteCoutureDrawMainGL:ItemCountChanged()
    self:_RefreshReward()
end

function UIHauteCoutureDrawMainGL:IsAllAwardCollected()
    return #self.controller._componentInfo.shake_win_ids == #self._allPrizes
end

--处理许愿点击事件
function UIHauteCoutureDrawMainGL:HandleDrawBtnClick()
    if self.controller._closed then
        ToastManager.ShowToast(StringTable.Get("str_activity_finished"))
        return
    end

    local nextDraw =
        Cfg.cfg_component_senior_skin_cost {
        ComponentID = self.controller._componentId,
        SeqID = self.controller._componentInfo.shake_num + 1
    }[1]
    local id = nextDraw.CostItemID
    if self:GetModule(RoleModule):GetAssetCount(id) < nextDraw.CostItemCount then
        --物品不足
        ToastManager.ShowToast(StringTable.Get("str_item_not_enough_gl"))
        GameGlobal.UIStateManager():ShowDialog(
            "UIHauteCoutureDrawChargeV2Controller",
            self.controller.hcType,
            self.controller._buyComponet
        )
        return
    end

    self:StartTask(self.DrawAnim, self)
end

--当前是否可抽到最终奖励
function UIHauteCoutureDrawMainGL:CanDrawSpecialAward()
    return self.controller._componentInfo.shake_num >= 5
end

function UIHauteCoutureDrawMainGL:DrawAnim(TT)
    self:Lock("UIHauteCoutureDrawMainGL:drawBtnOnClick")
    local res = AsyncRequestRes:New()
    local result, rewards = self.controller._component:HandleApplySeniorSkin(TT, res)

    if not result or not result:GetSucc() then
        self:UnLock("UIHauteCoutureDrawMainGL:drawBtnOnClick")
        return
    end

    Log.debug("高级时装抽奖结果:", rewards)

    local targetid = rewards
    local collectedAwards = {} --已领取过的奖励
    for _, id in pairs(self.controller._componentInfo.shake_win_ids) do
        collectedAwards[id] = true
    end

    local targetidx

    local idxs = {}
    for idx, item in ipairs(self._allPrizes) do
        local id = item:GetCfgID()
        if not collectedAwards[id] then
            if id == targetid then
                targetidx = idx
            else
                if idx == self.controller._specialIdx then
                    if self:CanDrawSpecialAward() then
                        --最终奖励从第5次之后才参与摇奖
                        table.insert(idxs, idx)
                    end
                else
                    table.insert(idxs, idx)
                end
            end

            if idx == self.controller._specialIdx then
                --特殊奖励可抽到时才压暗
                item:SetGray(self:CanDrawSpecialAward())
            else
                item:SetGray(true)
            end
        else
            item:SetGray(false)
        end
    end

    if #idxs == 0 then
    else
        table.shuffle(idxs)
        table.insert(idxs, 1, targetidx)
        local rdmIdx = {}
        local count = #idxs
        local flashCount = 18
        for i = 1, flashCount do
            table.insert(rdmIdx, idxs[Mathf.Repeat(i - 1, count) + 1])
        end
        local last
        for i = 1, flashCount do
            local idx = rdmIdx[flashCount - i + 1]
            if last then
                self._allPrizes[last]:SetGray(true)
            end
            self._allPrizes[idx]:SetGray(false)
            last = idx
            if i == flashCount then
                YIELD(TT, 100)
            elseif i > flashCount - 2 then
                YIELD(TT, 500)
            elseif i > flashCount - 3 then
                YIELD(TT, 280)
            elseif i == 2 then
                YIELD(TT, 200)
            elseif i == 1 then
                YIELD(TT, 400)
            else
                YIELD(TT, 100)
            end
        end
    end

    self._prizeEff.position = self._allPrizes[targetidx]:GetGameObject().transform.position
    self._prizeEff.gameObject:SetActive(true)
    YIELD(TT, 1000)
    self._prizeEff.gameObject:SetActive(false)

    --刷新数据
    self.controller._campaign = UIActivityCampaign:New()
    local resC = AsyncRequestRes:New()
    self.controller._campaign:LoadCampaignInfo(
        TT,
        resC,
        ECampaignType.CAMPAIGN_TYPE_SENIOR_SKIN,
        ECampaignSeniorSkinComponentID.ECAMPAIGN_BUY_GIFT,
        ECampaignSeniorSkinComponentID.ECAMPAIGN_SENIOR_SKIN
    )
    self.controller._campaign:ReLoadCampaignInfo_Force(TT, resC)
    ---@type BuyGiftComponent
    self.controller._buyComponet = self.controller._campaign:GetLocalProcess()._buyGiftComponent
    self.controller._buyComponetInfo = self.controller._campaign:GetLocalProcess()._buyGiftComponentInfo
    ---@type SeniorSkinComponent
    self.controller._component = self.controller._campaign:GetLocalProcess()._seniorSkinComponent
    ---@type SeniorSkinComponentInfo
    self.controller._componentInfo = self.controller._campaign:GetLocalProcess()._seniorSkinComponentInfo

    if self.controller._componentInfo.shake_num == 1 then
        --刷新完数据发消息通知活动进度改变，目的是通知主界面侧边栏活动入口的红点刷新，这个消息会被很多地方接收
        GameGlobal.EventDispatcher():Dispatch(GameEventType.QuestUpdate)
    end

    local weightCfg = Cfg.cfg_component_senior_skin_weight[rewards]
    if not weightCfg then
        Log.error("###[UIHauteCoutureDrawController] cfg is nil ! id --> ", rewards)
        return
    end
    local reawrdList = {}
    local reward = RoleAsset:New()
    reward.assetid = weightCfg.RewardID
    reward.count = weightCfg.RewardCount
    table.insert(reawrdList, reward)
    if weightCfg.AppendGlow and weightCfg.AppendGlow > 0 then
        local rewardGp = RoleAsset:New()
        rewardGp.assetid = RoleAssetID.RoleAssetGlow
        rewardGp.count = weightCfg.AppendGlow
        table.insert(reawrdList, rewardGp)
    end

    if self.controller._specialIdx == targetidx then
        --开出时装
        local skin = RoleAsset:New()
        --卡莲皮肤物品Id是4090064，物品id与皮肤id对应关系为去掉40
        skin.assetid = weightCfg.RewardID - 4000000
        skin.count = weightCfg.RewardCount
        self:ShowDialog(
            "UIPetSkinObtainController",
            skin,
            function()
                GameGlobal.UIStateManager():CloseDialog("UIPetSkinObtainController")
                self:ShowDialog(
                    "UIHauteCoutureDrawGetItemV2Controller",
                    reawrdList,
                    nil,
                    true,
                    function()
                        self:_RefreshReward()
                        self:CheckAllPrizeCollected()
                    end,
                    self.controller.CtxData
                )
            end
        )
    else
        self:ShowDialog(
            "UIHauteCoutureDrawGetItemV2Controller",
            reawrdList,
            nil,
            true,
            function()
                self:_RefreshReward()
                self:CheckAllPrizeCollected()
            end,
            self.controller.CtxData
        )
    end
    self:UnLock("UIHauteCoutureDrawMainGL:drawBtnOnClick")
end

function UIHauteCoutureDrawMainGL:CheckAllPrizeCollected()
    if self:IsAllAwardCollected() then
        ---@type UICurrencyItem
        local currency = self._topTips:GetItemByTypeId(self:GetCoinId())
        currency:CloseAddBtn()

        self._drawBtnOj:SetActive(false)
        self._probalityBtn:SetActive(false)
        self._buyBtn:SetActive(false)
    -- local desRect = self._imgDes:GetComponent(typeof(UnityEngine.RectTransform))
    -- desRect.anchoredPosition = Vector2(desRect.anchoredPosition.x, 186)
    end
end

--检查并执行转场
function UIHauteCoutureDrawMainGL:CheckAndDoEnterAni(TT)
    local key = self:GetEnterAniKey()
    if UnityEngine.PlayerPrefs.HasKey(key) then
        local lastShow = UnityEngine.PlayerPrefs.GetFloat(key)
        local nextRefresh = GameGlobal.GetModule(LoginModule):GetSignRefreshTime()
        --未跨天
        if nextRefresh - lastShow < 86400 then
            self._enterAniGo:SetActive(false)
            self:_EnterRoot()
            return
        end
    end
    local now = GameGlobal.GetModule(SvrTimeModule):GetServerTime() * 0.001
    UnityEngine.PlayerPrefs.SetFloat(key, now)
    self._rootGo:SetActive(false)

    ---@type UIHauteCoutureDrawEnterAni
    local enterAni = self._enterAniPool:SpawnObject("UIHauteCoutureDrawEnterAni")
    local clipLength = enterAni:GetClipLength()
    YIELD(TT, clipLength * 1000 - 200)
    self._enterAniGo:SetActive(false)
    self:_EnterRoot()
end

function UIHauteCoutureDrawMainGL:_EnterRoot()
    self._rootGo:SetActive(true)
    self._rootAni:Play("UIHauteCoutureDrawMainGL")
    self:_LoadVideo()
end
