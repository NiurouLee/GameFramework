---@class UIHauteCoutureDrawMainBLH_Review:UIHauteCoutureDrawBase
_class("UIHauteCoutureDrawMainBLH_Review", UIHauteCoutureDrawBase)
UIHauteCoutureDrawMainBLH_Review = UIHauteCoutureDrawMainBLH_Review

function UIHauteCoutureDrawMainBLH_Review:Constructor()
    self._allPrizes = {}
    self._EnterAniKey = nil
end
function UIHauteCoutureDrawMainBLH_Review:CloseSelf()
    if self._rt then
        self._rt:Release()
        self._rt = nil
    end
    self.controller:CloseDialog()
end

function UIHauteCoutureDrawMainBLH_Review:OnShow(uiParams)
    self:InitWidgets()
    self:_OnValue()
    self:AttachEvent(GameEventType.ItemCountChanged, self.ItemCountChanged)
    -- self:_LoadVideo()
    self:_LoadPrize()
    self:CheckAllPrizeCollected()
    -- self:StartTask(self.CheckAndDoEnterAni, self)
    self:_LoadVideo()
end

function UIHauteCoutureDrawMainBLH_Review:OnHide()
    self:DetachEvent(GameEventType.ItemCountChanged, self.ItemCountChanged)
    if self._rt then
        self._rt:Release()
        self._rt = nil
    end
end

function UIHauteCoutureDrawMainBLH_Review:GetEnterAniKey()
    if not self._EnterAniKey then
        ---@type RoleModule
        local roleModule = GameGlobal.GetModule(RoleModule)
        local pstId = roleModule:GetPstId()
        self._EnterAniKey = pstId .. "LashShowCoutureEnter"
    end
    return self._EnterAniKey
end

function UIHauteCoutureDrawMainBLH_Review:InitWidgets()
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
    self._pause = self:GetGameObject("pause")
end

function UIHauteCoutureDrawMainBLH_Review:GetCoinId()
    return self.controller.CtxData:CostItemID()
end

function UIHauteCoutureDrawMainBLH_Review:_OnValue()
    --self._moneyIcon = self._uiCommonAtlas:GetSprite("toptoon_3000266")
    self.drawTitle:RefreshText(StringTable.Get("str_senior_skin_draw_des_gl"))
end

--加载Video
function UIHauteCoutureDrawMainBLH_Review:_LoadVideo()
    local url =
        ResourceManager:GetInstance():GetAssetPath(self.controller._cfg.MiniVideoName .. ".mp4", LoadType.VideoClip)
    self:LoadVideo(url)
    self._playing = true
    self._pause:SetActive(not self._playing)
end
--加载Video
function UIHauteCoutureDrawMainBLH_Review:LoadVideo(url)
    --local url = ResourceManager:GetInstance():GetAssetPath(self.controller._cfg.VideoName .. ".mp4", LoadType.VideoClip)
    Log.debug("[guide movie] move url ", url)
    self._vp = self:GetUIComponent("VideoPlayer", "VideoPlayer")
    ---@type UnityEngine.UI.RawImage
    self._rawImage = self:GetUIComponent("RawImage", "VideoPlayer")
    self._rt = UnityEngine.RenderTexture:New(339, 190, 16)
    self._rawImage.texture = self._rt
    self._vp.targetTexture = self._rt

    self._vp.gameObject:SetActive(true)
    self._vp.url = url
    self._vp.targetCamera = GameGlobal.UIStateManager():GetControllerCamera("UIHauteCoutureDrawV2ReviewController")
    self._vp:Play()
    self._vp.frame = 0

    GameGlobal.UIStateManager():GetControllerCamera("UIHauteCoutureDrawV2ReviewController"):Render()
end

--加载Prize
function UIHauteCoutureDrawMainBLH_Review:_LoadPrize()
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    local ctx = campaignModule:GetCurHauteCouture_Review()

    self._componentId = self.controller._componentId
    self._componentInfo = self.controller._componentInfo
    self._prizes = Cfg.cfg_component_senior_skin_weight {ComponentID = self._componentId}
    table.sort(
        self._prizes,
        function(a, b)
            return a.RewardSortOrder > b.RewardSortOrder
        end
    )
    --需要替换的奖励索引id列表
    self._replaceIdxs = campaignModule:GetSeniorSkinDuplicateRewardIndexs(self._prizes, self._componentInfo)
    -- self._replaceIdxs = {1, 2, 3, 4}
    local specialIndex = 1 --排序之后特殊奖励是第1个

    local prizes = self.controller._prizes
    local idList = {} -- RewardSortOrder
    for i = 1, table.count(prizes) do
        local prize = prizes[i]
        --特殊奖励排在第1个,但是RewardSortOrder字段是10
        local specailPrizeOrder = 10
        if specailPrizeOrder ~= prize.RewardSortOrder then
            table.insert(idList, prize.RewardSortOrder)
        end
    end

    --top row,3 item
    local topItemNum = 3
    self._prizeTop:SpawnObjects("UIHauteCoutureDrawPrizeItemBLH", topItemNum)
    --bottom row
    self._prizeBottom:SpawnObjects("UIHauteCoutureDrawPrizeItemBLH", #idList - topItemNum)

    ---@type UIHauteCoutureDrawPrizeItemBLH[]
    local topPools = self._prizeTop:GetAllSpawnList()
    for i = 1, #topPools do
        local item = topPools[i]
        local sortOrder = idList[i]
        local idx = 10 - sortOrder + 1
        item:SetData(sortOrder, self.controller._componentId, false, ctx, table.icontains(self._replaceIdxs, idx))
        table.insert(self._allPrizes, item)
    end

    ---@type UIHauteCoutureDrawPrizeItemBLH[]
    local bottomPoos = self._prizeBottom:GetAllSpawnList()
    for i = 1, #bottomPoos do
        local item = bottomPoos[i]
        local sortOrder = idList[i + topItemNum]
        local idx = 10 - sortOrder + 1
        item:SetData(sortOrder, self.controller._componentId, false, ctx, table.icontains(self._replaceIdxs, idx))
        table.insert(self._allPrizes, item)
    end

    if specialIndex then
        ---@type UIHauteCoutureDrawPrizeItemBLH
        local item = self._specialItem:SpawnObject("UIHauteCoutureDrawPrizeItemBLH")
        local sortOrder = 10
        item:SetData(
            sortOrder,
            self.controller._componentId,
            true,
            ctx,
            table.icontains(self._replaceIdxs, specialIndex)
        )
        table.insert(self._allPrizes, item)
    end

    self:_RefreshReward()

    self:GetGameObject("duplicateTip"):SetActive(#self._replaceIdxs > 0)
end

--刷新奖励
function UIHauteCoutureDrawMainBLH_Review:_RefreshReward()
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

function UIHauteCoutureDrawMainBLH_Review:ItemCountChanged()
    self:_RefreshReward()
end

function UIHauteCoutureDrawMainBLH_Review:IsAllAwardCollected()
    return #self.controller._componentInfo.shake_win_ids == #self._allPrizes
end

--处理许愿点击事件
function UIHauteCoutureDrawMainBLH_Review:HandleDrawBtnClick()
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
        local cfg_item = Cfg.cfg_item[id]
        local costName = ""
        if cfg_item then
            costName = StringTable.Get(cfg_item.Name)
        end
        --物品不足
        ToastManager.ShowToast(StringTable.Get("str_senior_skin_draw_cost_not_enough", costName))
        GameGlobal.UIStateManager():ShowDialog(
            "UIHauteCoutureDrawChargeV2Controller",
            self.controller.hcType,
            self.controller._buyComponet,
            self.controller.CtxData
        )
        return
    end

    self:StartTask(self.DrawAnim, self)
end

--当前是否可抽到最终奖励
function UIHauteCoutureDrawMainBLH_Review:CanDrawSpecialAward()
    return self.controller._componentInfo.shake_num >= 5
end

function UIHauteCoutureDrawMainBLH_Review:DrawAnim(TT)
    self:Lock("UIHauteCoutureDrawMainBLH_Review:drawBtnOnClick")
    local res = AsyncRequestRes:New()
    local result, rewards = self.controller._component:HandleApplySeniorSkin(TT, res)

    if not result or not result:GetSucc() then
        self:UnLock("UIHauteCoutureDrawMainBLH_Review:drawBtnOnClick")
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
        ECampaignType.CAMPAIGN_TYPE_SENIOR_SKIN_COPY,
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
    local reawrdList = self._allPrizes[targetidx]._assetList

    if self._allPrizes[targetidx]:IsHauteCouture() then
        --开出时装
        local skin = RoleAsset:New()
        --卡莲皮肤物品Id是4090064，物品id与皮肤id对应关系为去掉40
        skin.assetid = weightCfg.RewardID - RoleAssetID.RoleAssetPetSkinBegin
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
    self:UnLock("UIHauteCoutureDrawMainBLH_Review:drawBtnOnClick")
end

function UIHauteCoutureDrawMainBLH_Review:CheckAllPrizeCollected()
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

function UIHauteCoutureDrawMainBLH_Review:VideoMaskOnClick(go)
    self:HandleFgBtnClick()
end
--小视频暂停功能 先屏蔽
function UIHauteCoutureDrawMainBLH_Review:VideoMaskOnClick1(go)
    if self._playing then
        self._playing = false
    else
        self._playing = true
    end
    if self._playing then
        -- if self._Bgm then
        --     AudioHelperController.UnpauseBGM()
        -- end
        self._vp:Play()
    else
        -- if self._Bgm then
        --     AudioHelperController.PauseBGM()
        -- end
        self._vp:Pause()
    end
    self._pause:SetActive(not self._playing)
end

--检查是否到结束时间
---@return boolean true代表已结束
function UIHauteCoutureDrawMainBLH_Review:CheckEndTime()
    local time = self.controller._componentInfo.m_close_time
    local now = math.floor(self:GetModule(SvrTimeModule):GetServerTime() / 1000)
    if now > time then
        local timeStr = StringTable.Get("str_activity_finished")
        self:SetEndTime(timeStr)
        self._timeStr = timeStr
        return true
    else
        local timeStr = HelperProxy:GetInstance():FormatTime_3(time - now, "#f1de3a")
        if self._timeStr ~= timeStr then
            self:SetEndTime(StringTable.Get("str_senior_skin_draw_end_time", timeStr))
            self._timeStr = timeStr
        end
        return false
    end
    return true
end


function UIHauteCoutureDrawMainBLH_Review:DuplicateTipOnClick()
    self:ShowDialog("UIHauteCoutureDuplicateReward", self._prizes, self._replaceIdxs)
end
