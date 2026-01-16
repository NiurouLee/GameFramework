---@class UIDrawCardPoolItem : UICustomWidget
_class("UIDrawCardPoolItem", UICustomWidget)
UIDrawCardPoolItem = UIDrawCardPoolItem

function UIDrawCardPoolItem:Constructor()
    ---@type GambleModule
    self.gambleModule = self:GetModule(GambleModule)

    --是否是未收录召集池
    self.isNotIncludePetPool = false
    --是否从未收录召集池获得到6星光灵
    self.hasGotSixStarFromNotIncludePetPool = false
end

function UIDrawCardPoolItem:OnShow()
    self.fsm = StateMachineManager:GetInstance():CreateStateMachine("StateDrawCardPool", StateDrawCardPool)
    self.fsmDrawCard = StateMachineManager:GetInstance():CreateStateMachine("StateAssetExchange", StateAssetExchange)

    ---@type UnityEngine.U2D.SpriteAtlas
    self._uiCommonAtlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)

    self._widthView = 1920 --视图宽度
    self._widthLogo = 3000 --Logo蒙版宽度

    self._poolDataList = {}
    ---@type UIDrawCardController
    self._controller = nil

    self:InitWidget()

    self.fsmDrawCard:SetData(self)
    self.fsmDrawCard:Init(StateAssetExchange.Init)

    self._timeModule = GameGlobal.GetModule(SvrTimeModule)

    self:AttachEvent(GameEventType.ItemCountChanged, self.OnItemCountChange)
end
function UIDrawCardPoolItem:OnHide()
    self.fsm:SetData(nil)
    StateMachineManager:GetInstance():DestroyStateMachine(self.fsm.Id)
    self.fsm = nil

    self.fsmDrawCard:SetData(nil)
    StateMachineManager:GetInstance():DestroyStateMachine(self.fsmDrawCard.Id)
    self.fsmDrawCard = nil

    self:DetachEvent(GameEventType.ItemCountChanged, self.OnItemCountChange)

    if self._freeTimeEvent then
        GameGlobal.Timer():CancelEvent(self._freeTimeEvent)
        self._freeTimeEvent = nil
    end
    if self._refreshTimeEvent then
        GameGlobal.Timer():CancelEvent(self._refreshTimeEvent)
        self._refreshTimeEvent = nil
    end
end

function UIDrawCardPoolItem:InitWidget()
    ---@type RawImageLoader
    self.bg = self:GetUIComponent("RawImageLoader", "bg")
    self.poolTip = self:GetGameObject("poolTip")
    self.poolDes = self:GetUIComponent("UILocalizationText", "poolDes")
    self.specailTip = self:GetGameObject("specialTip")
    self.specailText = self:GetUIComponent("RollingText", "spacialText")
    self.singleBtn = self:GetGameObject("SingleDrawButton")
    self.btnsBg = self:GetGameObject("btnsbg")
    self.multibtnBg = self:GetGameObject("mutibtnbg")

    self._revolvingText = self:GetUIComponent("RevolvingTextWithDynamicScroll", "RevolvingText")

    self.tips = self:GetGameObject("tips")
    ---@type UnityEngine.CanvasGroup
    self.tipsCanvasGroup = self:GetUIComponent("CanvasGroup", "tips")
    ---@type UnityEngine.RectTransform
    self.tipsRT = self:GetUIComponent("RectTransform", "tips")
    ---@type UnityEngine.CanvasGroup
    self.btnsCanvasGroup = self:GetUIComponent("CanvasGroup", "btns")
    ---@type UnityEngine.RectTransform
    self.btnsRT = self:GetUIComponent("RectTransform", "btns")
    ---@type UILocalizationText
    self.title = self:GetUIComponent("UILocalizationText", "title")
    ---@type UILocalizationText
    self.txtTitle = self:GetUIComponent("UILocalizationText", "txtTitle")
    self.content = self:GetUIComponent("UILocalizationText", "content")
    ---@type UISelectObjectPath
    self.petList = self:GetUIComponent("UISelectObjectPath", "petList")
    ---@type RollingText
    self.closeCondition = self:GetUIComponent("RollingText", "CloseCondition")
    self.singleIcon = self:GetUIComponent("Image", "singleIcon")
    self.singleCount = self:GetUIComponent("UILocalizationText", "singleCount")
    self.multipleIcon = self:GetUIComponent("Image", "multipleIcon")
    self.multipleCount = self:GetUIComponent("UILocalizationText", "multipleCount")
    self.multipleBtnText = self:GetUIComponent("UILocalizationText", "multipleBtnText")
    self.tendiscount = self:GetUIComponent("Image", "tendiscount")
    self.tendiscountInfo = self:GetUIComponent("UILocalizationText", "tendiscountInfo")
    self.onediscount = self:GetUIComponent("Image", "onediscount")
    self.onediscountInfo = self:GetUIComponent("UILocalizationText", "onediscountInfo")
    self.onePetGo = self:GetGameObject("onePetGo")
    ---@type UnityEngine.CanvasGroup
    self.onePetGoCanvasGroup = self:GetUIComponent("CanvasGroup", "onePetGo")
    ---@type UnityEngine.RectTransform
    self.onePetGoRT = self:GetUIComponent("RectTransform", "onePetGo")
    self.morePetGo = self:GetGameObject("morePetGo")
    ---@type UnityEngine.CanvasGroup
    self.morePetGoCanvasGroup = self:GetUIComponent("CanvasGroup", "morePetGo")
    ---@type UnityEngine.RectTransform
    self.leftDownRt = self:GetUIComponent("RectTransform", "leftDown_ani")
    self.leftDownGoCanvasGroup = self:GetUIComponent("CanvasGroup", "leftDown_ani")
    self.morePetGoRT = self:GetUIComponent("RectTransform", "morePetGo")
    self.onePetIcon = self:GetUIComponent("RawImageLoader", "onePetIcon")
    self.onePetTitle = self:GetUIComponent("UILocalizationText", "onePetTitle")
    self.onePetStars = self:GetUIComponent("UISelectObjectPath", "onePetStars")
    self._oneOpenTime = self:GetUIComponent("RollingText", "oneOpenTime")
    self._moreOpenTime = self:GetUIComponent("RollingText", "moreOpenTime")
    self._contentLayoutBg = self:GetUIComponent("RawImageLoader", "contentLayoutBg")
    self.tenOriPrice = self:GetUIComponent("UILocalizationText", "tenOriPrice")
    self.tenNowPrice = self:GetUIComponent("UILocalizationText", "tenNowPrice")
    self.oneOriPrice = self:GetUIComponent("UILocalizationText", "oneOriPrice")
    self.oneNowPrice = self:GetUIComponent("UILocalizationText", "oneNowPrice")
    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlasProperty = self:GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)
    ---@type UnityEngine.UI.Image
    self.oneElement = self:GetUIComponent("Image", "oneElement")

    self.petsInfoLoader = self:GetUIComponent("UISelectObjectPath", "petInfoLoader")
    self.multipleDrawButton = self:GetUIComponent("Button", "MultipleDrawButton")

    ---@type UnityEngine.RectTransform
    self.selfRect = self:GetUIComponent("RectTransform", "anim")

    ---@type UnityEngine.RectTransform
    self.layer1Rect = self:GetUIComponent("RectTransform", "layer1")
    ---@type UnityEngine.CanvasGroup
    self.layer1Group = self:GetUIComponent("CanvasGroup", "layer1")
    ---@type UnityEngine.RectTransform
    self.layer2Rect = self:GetUIComponent("RectTransform", "layer2")
    ---@type UnityEngine.CanvasGroup
    self.layer2Group = self:GetUIComponent("CanvasGroup", "layer2")
    ---@type UnityEngine.RectTransform
    self.layer3Rect = self:GetUIComponent("RectTransform", "layer3")
    ---@type UnityEngine.CanvasGroup
    self.layer3Group = self:GetUIComponent("CanvasGroup", "layer3")

    self.uieff = self:GetGameObject("uieff")
    self.uieff:SetActive(false)
    self.center = self:GetGameObject("Center")
    ---@type UIEventTriggerListener
    self.etl = UICustomUIEventListener.Get(self:GetGameObject())

    ---@type UnityEngine.Animation
    self._animation = self:GetUIComponent("Animation", "anim")
    ---@type UnityEngine.Animation
    self._animSwitchPool = self:GetUIComponent("Animation", "animSwitchPool")

    ---@type RawImageLoader[]
    self.lr = {}
    ---@type UnityEngine.RectTransform[]
    self.lrRect = {}
    for i = 1, 3 do
        local name = "lr" .. i
        local lr = self:GetUIComponent("RawImageLoader", name)
        table.insert(self.lr, lr)
        local rect = self:GetUIComponent("RectTransform", name)
        table.insert(self.lrRect, rect)
    end
    self.lrSpeed = {} --lr层的速度

    ---@type UnityEngine.RectTransform
    self.bgLogo = self:GetUIComponent("RectTransform", "bgLogo")
    ---@type UnityEngine.UI.Image
    self.imgBGLogo = self:GetUIComponent("Image", "bgLogo")
    ---@type RawImageLoader[]
    self.logos = {}
    ---@type UnityEngine.UI.RawImage[]
    self.imgLogos = {}
    self._lenLogos = 6
    for i = 1, self._lenLogos do
        local name = "logo" .. i
        local logo = self:GetUIComponent("RawImageLoader", name)
        table.insert(self.logos, logo)
        local imgLogo = self:GetUIComponent("RawImage", name)
        table.insert(self.imgLogos, imgLogo)
    end

    self._widthView = self.layer1Rect.rect.width
    self._widthLogo = self.bgLogo.rect.width

    self._animation:Play("UIDrawCardPoolItem_enter")

    self._probTex = self:GetUIComponent("UIRichText", "probTex")
    self._prob = self:GetGameObject("prob")

    self._poolCountTest = self:GetGameObject("poolCountTest")
    self._poolCountText = self:GetUIComponent("UILocalizationText", "poolCountText")

    self._poolLimitWidget = self:GetUIComponent("UISelectObjectPath", "lr1")

    self._freeCountGo = self:GetGameObject("freeCountGo")
    self._freeTimeGo = self:GetGameObject("freeTimeGo")
    self._freeTimeTex = self:GetUIComponent("UILocalizationText", "freeTimeTex")
    self._normalSingleGo = self:GetGameObject("normalSingleGo")
    self._freeTenGo = self:GetGameObject("freeGoTen")
    self._tenCostGo = self:GetGameObject("tenCostMats")

    self.txtExtendBtnUnObtain = self:GetUIComponent("UILocalizationText", "txtExtendBtnUnObtain")
    self.ExtendTextBtnUnObtainGo = self:GetGameObject("ExtendTextBtnUnObtain")
    self.ExtendTextBtnUnObtainRt = self:GetUIComponent("RectTransform", "ExtendTextBtnUnObtain")

    self.txtExtendBtnHasObtain = self:GetUIComponent("UILocalizationText", "txtTxtendBtnHasObtain")
    self.ExtendTextBtnHasObtainGo = self:GetGameObject("ExtendTextBtnHasObtain")
    self.ExtendTextBtnHasObtainRt = self:GetUIComponent("RectTransform", "ExtendTextBtnHasObtain")

    self.imgSixStarGo = self:GetGameObject("imgSixStarGo")
    self.imgSixStarRt = self:GetUIComponent("RectTransform", "imgSixStarGo")
end

function UIDrawCardPoolItem:RegUIEventTriggerListener(onBeginDrag, onDrag, onEndDrag)
    self:AddUICustomEventListener(self.etl, UIEvent.BeginDrag, onBeginDrag)
    self:AddUICustomEventListener(self.etl, UIEvent.Drag, onDrag)
    self:AddUICustomEventListener(self.etl, UIEvent.EndDrag, onEndDrag)
end

function UIDrawCardPoolItem:GetWidthHalf()
    return self._widthView * 0.5
end

---@param isRight boolean 是否放在右边
function UIDrawCardPoolItem:InitLogoPos(isRight)
    local anchoredPosition = Vector2.zero
    anchoredPosition.x = self:GetWidthHalf()
    self.bgLogo.anchoredPosition = anchoredPosition
    local localRotation = Quaternion.identity
    if isRight then
        localRotation = Quaternion.Euler(Vector3.zero)
        self.imgBGLogo.color = Color(41 / 255, 59 / 255, 119 / 255)
    else
        localRotation = Quaternion.Euler(Vector3(0, 180, 0))
        self.imgBGLogo.color = Color(1, 103 / 255, 0)
    end
    self.layer1Rect.localRotation = localRotation
    self.bg.transform.localRotation = localRotation
    for i, img in ipairs(self.lr) do
        img.transform.localRotation = localRotation
    end
    self.uieff.transform.localRotation = localRotation
    self.center.transform.localRotation = localRotation
    for i, imgLogo in ipairs(self.imgLogos) do
        if isRight then
            imgLogo.color = Color.white
        else
            imgLogo.color = Color.black
        end
    end
    self:ResetLRPos()
end

function UIDrawCardPoolItem:ResetLRPos()
    for i, tran in ipairs(self.lrRect) do
        tran.anchoredPosition = Vector2.zero
    end
end

---@param poolDataList UIDrawCardPoolInfo[] 卡池信息列表
function UIDrawCardPoolItem:Init(poolDataList, controller, openID)
    self._controller = controller
    ---@type UIDrawCardPoolInfo[]
    self._poolDataList = poolDataList

    if openID then
        for i = 1, #self._poolDataList do
            if self._poolDataList[i].poolData.performance_id == openID then
                self:GetModule(GambleModule):Context():SetDefaultPoolIndex(i)
                break
            end
        end
    end

    local idx = self:GetModule(GambleModule):Context():GetDefaultPoolIndex()
    if idx == -1 then
        idx = 1
    end
    self:Refresh(idx, true)

    self.fsm:SetData(self) --将本脚本暂存到状态机中，state逻辑要用到UI上的数据可以从其对应的状态机�??
    self.fsm:Init(StateDrawCardPool.Init)
end

--region Index
function UIDrawCardPoolItem:GetIndex()
    return self._controller.currentIdx
end
--endregion

---@param idx number 当前卡池索引
---@param isInit boolean 是否初始�??
function UIDrawCardPoolItem:Refresh(idx, isInit)
    if not self._poolDataList[idx] then
        Log.warn("### data nil. idx=", idx)
        idx = 1 --没有数据就取�??1个卡�??
    end
    ---@type UIDrawCardPoolInfo
    self._uiData = self._poolDataList[idx]

    self._countDownTimer = nil

    GameGlobal.UAReportForceGuideEvent("UIDrawCardClick", {"SwitchPool_" .. self._uiData.poolData.prize_pool_id}, true)

    self._controller:ShowAwardPool(idx, isInit)
    local cfg = Cfg.cfg_drawcard_pool_view[self._uiData.poolData.performance_id]
    if cfg == nil then
        Log.fatal(
            "###error -- drawcard - cfg_drawcard_pool_view is nil ! key --> ",
            self._uiData.poolData.performance_id
        )
        return
    end

    --extendBtn
    self:RefreshExtendBtns(idx, cfg)
    local times = self.gambleModule:GetNotIncludePetPoolGambleTimes(idx)
    self.notIncludePetPool = times > -1

    self._contentLayoutBg:LoadImage(cfg.PoolContentBg)
    self.bg:LoadImage(cfg.PoolBG)
    for i, img in ipairs(self.lr) do
        local pic = cfg.PetLayerInfo[i].pic
        img:LoadImage(pic)
    end
    self.lrSpeed = {}
    for i, c in ipairs(cfg.PetLayerInfo) do
        local speed = c.speed
        table.insert(self.lrSpeed, speed)
    end
    local title = StringTable.Get(cfg.PoolTitle)
    self.title:SetText(title)
    self.txtTitle:SetText(title)
    self.content.text = StringTable.Get(cfg.PoolContent)
    self.onePetGo:SetActive(#cfg.PetList == 1)
    self.morePetGo:SetActive(#cfg.PetList > 1)
    if #cfg.PetList > 1 and not self.notIncludePetPool then
        self.petList:SpawnObjects("UIDrawCardPoolPetListItem", #cfg.PetList)
        ---@type table<int,UIDrawCardPoolPetListItem>
        local items = self.petList:GetAllSpawnList()
        for idx, value in ipairs(items) do
            value:SetData(cfg.PetList[idx], cfg.PetIconList[idx])
        end

        -- if cfg.PetWidgetOffset then
        --     self.petsInfoLoader:SpawnObjects("UIDrawCardPetInfoLoader", #cfg.PetWidgetOffset)
        --     ---@type table<number,UIDrawCardPetInfoLoader>
        --     local petInfos = self.petsInfoLoader:GetAllSpawnList()

        --     for idx, offset in ipairs(cfg.PetWidgetOffset) do
        --         local type = 1
        --         if cfg.WidgetType and cfg.WidgetType[idx] then
        --             type = cfg.WidgetType[idx]
        --         end
        --         petInfos[idx]:SetData(
        --             type,
        --             cfg.PetList[idx],
        --             offset,
        --             function(id)
        --                 self:ItemClick(id)
        --             end
        --         )
        --     end
        -- end
        --2022.1.4修改配置格式
        self.petList:SpawnObjects("UIDrawCardPoolPetListItem", #cfg.PetList)
        ---@type table<int,UIDrawCardPoolPetListItem>
        local items = self.petList:GetAllSpawnList()
        for idx, value in ipairs(items) do
            value:SetData(cfg.PetList[idx], cfg.PetIconList[idx])
        end

        if cfg.PetWidget then
            self.petsInfoLoader:SpawnObjects("UIDrawCardPetInfoLoader", #cfg.PetWidget)
            ---@type table<number,UIDrawCardPetInfoLoader>
            local petInfos = self.petsInfoLoader:GetAllSpawnList()
            for idx, offset in ipairs(cfg.PetWidget) do
                petInfos[idx]:SetData(
                    cfg.PetList[idx],
                    cfg.PetWidget[idx],
                    function(id)
                        self:ItemClick(id)
                    end
                )
            end
        end
    elseif #cfg.PetList == 1 then
        self.petsInfoLoader:SpawnObjects("UIDrawCardPetInfoLoader", 0)
        local petID = cfg.PetList[1]
        local cfgPet = Cfg.cfg_pet[petID]
        local nameEndNoEng = cfg.NameEndNoEng
        local activeSkill, chainSkill, captainSkill = self:GetModule(PetModule):GetPetDefaultSkills(petID)
        self.onePetIcon:LoadImage(cfg.PetIconList[1])
        local cfg_element = Cfg.cfg_pet_element[cfgPet.FirstElement]
        self.oneElement.sprite =
            self.atlasProperty:GetSprite(UIPropertyHelper:GetInstance():GetColorBlindSprite(cfg_element.Icon))

        local petNameStr = ""
        local eng = HelperProxy:GetInstance():IsInEnglish()
        if eng or nameEndNoEng then
            petNameStr = StringTable.Get(cfgPet.Name)
        else
            petNameStr = StringTable.Get(cfgPet.Name) .. " (" .. StringTable.Get(cfgPet.EnglishName) .. ")"
        end
        self.onePetTitle:SetText(petNameStr)

        self.onePetStars:SpawnObjects("UICommonEmptyItems", cfgPet.Star)
    else
        self.petList:SpawnObjects("UIDrawCardPoolPetListItem", 0)
        self.petsInfoLoader:SpawnObjects("UIDrawCardPetInfoLoader", 0)
        if not self.notIncludePetPool then
            Log.fatal("[DrawCard] pet count error: ", #cfg.PetList)
        end
    end

    --多抽按钮默认状�?
    self.multipleDrawButton.interactable = true

    local closeType = self._uiData.poolData.close_type
    self.tips:SetActive(closeType == PrizePoolOpenCloseType.PLAY_TIMES_CONDITON)
    self.poolTip:SetActive(true)
    self.specailTip:SetActive(false)
    self.singleBtn:SetActive(true)
    self.multibtnBg:SetActive(false)
    self.btnsBg:SetActive(true)
    if closeType == PrizePoolOpenCloseType.PLAY_TIMES_CONDITON then
        if self._uiData.poolData.close_condition2 and self._uiData.poolData.close_condition2 > 0 then
            --特殊的付费卡池，用单个材料十连，关闭条件是到次数或到时间
            self.poolTip:SetActive(false)
            self.specailTip:SetActive(true)
            self.specailText:RefreshText(StringTable.Get(cfg.PoolDes))
            self.singleBtn:SetActive(false)
            self.closeCondition.gameObject:SetActive(false)
            self._oneOpenTime.gameObject:SetActive(true)
            self._moreOpenTime.gameObject:SetActive(true)
            self.multibtnBg:SetActive(true)
            self.btnsBg:SetActive(false)
            self:countDown()
            self._countDownTimer = 0
        else
            self.poolDes:SetText(StringTable.Get(cfg.PoolDes))
            self._revolvingText:OnRefreshRevolving()

            self._oneOpenTime.gameObject:SetActive(false)
            self._moreOpenTime.gameObject:SetActive(false)

            self.closeCondition.gameObject:SetActive(true)
            local str =
                StringTable.Get(
                "str_draw_card_draw_to_close",
                StringTable.Get(cfg.PoolName),
                self._uiData.poolData.extend_data
            )
            self.closeCondition:RefreshText(str)
            -----------------------------------
            if self._uiData.poolData.extend_data < self._uiData.poolData.multiple_shake_times then --剩余次数不足以多�??
                self.multipleDrawButton.interactable = false
            end
        end
    elseif closeType == PrizePoolOpenCloseType.PERMANENT then
        self._oneOpenTime.gameObject:SetActive(false)
        self._moreOpenTime.gameObject:SetActive(false)

        self.closeCondition.gameObject:SetActive(false)
    elseif closeType == PrizePoolOpenCloseType.TIME_CONDITON then
        if self._uiData.poolData.prize_pool_type == 1 then
            self._oneOpenTime.gameObject:SetActive(false)
            self._moreOpenTime.gameObject:SetActive(false)

            self.closeCondition.gameObject:SetActive(false)
        else
            self._oneOpenTime.gameObject:SetActive(true)
            self._moreOpenTime.gameObject:SetActive(true)

            self.closeCondition.gameObject:SetActive(false)

            -- local openTimeLeft = os.date("%m/%d", self._uiData.poolData.open_time)
            -- local closeTimeLeft = os.date("%m/%d", self._uiData.poolData.extend_data)

            -- local openTimeRight = os.date("%H:%M", self._uiData.poolData.open_time)
            -- local closeTimeRight = os.date("%H:%M", self._uiData.poolData.extend_data)

            -- local timeStr =
            --     StringTable.Get("str_draw_card_pool_end_time") ..
            --     ":" .. openTimeLeft .. " " .. openTimeRight .. "-" .. closeTimeLeft .. " " .. closeTimeRight

            -- self._oneOpenTime:RefreshText(timeStr)
            -- self._moreOpenTime:RefreshText(timeStr)
            self:countDown()
            self._countDownTimer = 0
        end
    end

    local cfgTopTips = Cfg.cfg_top_tips
    local singleIconCfg = cfgTopTips[self._uiData.singleMat]
    if singleIconCfg then
        local singleIcon = cfgTopTips[self._uiData.singleMat].Icon
        if singleIcon then
            self.singleIcon.sprite = self._uiCommonAtlas:GetSprite(singleIcon)
        else
            Log.fatal("###error -- drawcard - cont find the mat ! mat --> ", self._uiData.singleMat)
        end
    else
        Log.fatal("###error -- drawcard - cfg_top_tips is nil ! key --> ", self._uiData.singleMat)
    end

    local multipleIconCfg = cfgTopTips[self._uiData.multipleMat]
    if multipleIconCfg then
        local multipleIcon = cfgTopTips[self._uiData.multipleMat].Icon
        if multipleIcon then
            self.multipleIcon.sprite = self._uiCommonAtlas:GetSprite(multipleIcon)
        else
            Log.fatal("###error -- drawcard - cont find the mat ! mat --> ", self._uiData.multipleMat)
        end
    else
        Log.fatal("###error -- drawcard - cfg_top_tips is nil ! key --> ", self._uiData.multipleMat)
    end

    self:FlushCost()
    if self._uiData:CanSingleDraw() then
        self.singleCount:SetText(self._uiData.singlePrice)
    end
    self.multipleCount:SetText(self._uiData.multiplePrice)
    self.multipleBtnText:SetText(
        string.format(
            StringTable.Get("str_draw_card_multiple_draw"),
            self:GetNumberCN(self._uiData.poolData.multiple_shake_times)
        )
    )

    --region 有折�??
    self.multipleCount.gameObject:SetActive(self._uiData.multipleDiscount == nil)
    self.tendiscount.gameObject:SetActive(self._uiData.multipleDiscount ~= nil)
    if self._uiData.multipleDiscount then
        local discountText = string.format("<size=36>%s</size>", self._uiData.multipleDiscount) .. "%OFF"
        self.tendiscountInfo.text = discountText

        self.tenOriPrice:SetText(self._uiData.multipleOriPrice)
        self.tenNowPrice:SetText(self._uiData.multiplePrice)
    end

    self.singleCount.gameObject:SetActive(self._uiData.singleDiscount == nil)
    self.onediscount.gameObject:SetActive(self._uiData.singleDiscount ~= nil)
    if self._uiData.singleDiscount then
        local discountText = string.format("<size=36>%s</size>", self._uiData.singleDiscount) .. "%OFF"
        self.onediscountInfo:SetText(discountText)

        self.oneOriPrice:SetText(self._uiData.singleOriPrice)
        self.oneNowPrice:SetText(self._uiData.singlePrice)
    end
    --endregion

    self:SetProbTips(idx)

    --卡池计数
    self:_PoolCountCalcTest(idx)

    --卡池限定标志
    if cfg.PoolLimit and #cfg.PoolLimit > 0 then
        self._poolLimitWidget:SpawnObjects("UIDrawcardPoolLimitItem", #cfg.PoolLimit)
        ---@type table<number, UIDrawcardPoolLimitItem>
        local widgets = self._poolLimitWidget:GetAllSpawnList()
        for i = 1, #widgets do
            widgets[i]:SetData(cfg.PoolLimit[i])
        end
    else
        self._poolLimitWidget:SpawnObjects("UIDrawcardPoolLimitItem", 0)
    end

    --免费召集次数
    self:FreeCount()
end

function UIDrawCardPoolItem:RefreshExtendBtns(idx, cfg)
    --未获得按钮
    self.ExtendTextBtnUnObtainGo:SetActive(false)
    --已经获得按钮
    self.ExtendTextBtnHasObtainGo:SetActive(false)
    --sixStarGo
    local cfgSixStar = cfg.extendBtn and cfg.extendBtn[3]
    self.imgSixStarGo:SetActive(cfgSixStar ~= nil)
    if cfgSixStar then
        self.imgSixStarRt.anchoredPosition = Vector2(cfgSixStar.pos[1], cfgSixStar.pos[2])
    end

    local times = self.gambleModule:GetNotIncludePetPoolGambleTimes(idx)
    if times > -1 then
        local cfgUnObtain = cfg.extendBtn and cfg.extendBtn[1]
        local cfgObtain = cfg.extendBtn and cfg.extendBtn[2]

        --未收集招录
        local petList = self.gambleModule:GetNotIncludePetPool(idx)
        if not petList or #petList == 0 then
            --卡池中没有了
            if cfgObtain then
                self.ExtendTextBtnHasObtainGo:SetActive(true)
                self.txtExtendBtnHasObtain:SetText(StringTable.Get("str_draw_card_btn_has_all"))
                self.ExtendTextBtnHasObtainRt.anchoredPosition = Vector2(cfgObtain.pos[1], cfgObtain.pos[2])
            end
        elseif times == 0 then
            --未抽到
            if cfgUnObtain then
                self.ExtendTextBtnUnObtainGo:SetActive(true)
                self.txtExtendBtnUnObtain:SetText(StringTable.Get(cfgUnObtain.text))
                self.ExtendTextBtnUnObtainRt.anchoredPosition = Vector2(cfgUnObtain.pos[1], cfgUnObtain.pos[2])
            end
        else
            --已抽到
            if cfgObtain then
                self.ExtendTextBtnHasObtainGo:SetActive(true)
                self.txtExtendBtnHasObtain:SetText(StringTable.Get("str_draw_card_btn_has_get"))
                self.ExtendTextBtnHasObtainRt.anchoredPosition = Vector2(cfgObtain.pos[1], cfgObtain.pos[2])
            end
        end
    else
        --other pool
    end
end

--免费召集次数
function UIDrawCardPoolItem:FreeCount()
    --免费单抽按钮
    local freeCountSingle = self._uiData:GetFreeCount_Single()
    self._freeCountGo:SetActive(freeCountSingle > 0)
    self._normalSingleGo:SetActive(freeCountSingle <= 0)

    --免费十连按钮
    local freeCountMulti = self._uiData:GetFreeCount_Multi()
    self._freeTenGo:SetActive(freeCountMulti > 0)
    self._tenCostGo:SetActive(freeCountMulti <= 0)

    --免费刷新倒计时，取单抽或十连其中之一
    local showTimer, nextTime
    local showTimer_Sin, nextTime_Sin = self:GetSingleFreeTimer()
    local showTimer_Mul, nextTime_Mul = self:GetMultipleFreeTimer()
    if showTimer_Mul and not showTimer_Sin then
        nextTime = nextTime_Mul
    elseif showTimer_Mul and showTimer_Sin then
        nextTime = math.min(nextTime_Sin, nextTime_Mul)
    elseif not showTimer_Mul and showTimer_Sin then
        nextTime = nextTime_Mul
    end
    --MSG41185	(QA_李松岩)抽卡系统QA_新增免费10连抽次数(客户端)	5	QA-开发制作中	靳策, 1951	05/13/2022
    self._freeTimeGo:SetActive(false) --单抽倒计时ui不再显示
    if nextTime then
        -- self._nextTime = nextTime
        -- if self._freeTimeEvent then
        --     GameGlobal.Timer():CancelEvent(self._freeTimeEvent)
        --     self._freeTimeEvent = nil
        -- end
        -- self:SetFreeTimerTex()
        -- self._freeTimeEvent =
        --     GameGlobal.Timer():AddEventTimes(
        --     1000,
        --     TimerTriggerCount.Infinite,
        --     function()
        --         self:SetFreeTimerTex()
        --     end
        -- )
        -- if self._refreshTimeEvent then
        --     GameGlobal.Timer():CancelEvent(self._refreshTimeEvent)
        --     self._refreshTimeEvent = nil
        -- end
        --倒计时结束了刷新数据
        -- local svrTime = math.ceil(self._timeModule:GetServerTime())
        -- local refreshTime = nextTime * 1000 - svrTime + 1000
        -- self._refreshTimeEvent =
        --     GameGlobal.Timer():AddEvent(
        --     refreshTime,
        --     function()
        --         local poolid = self._uiData.poolData.performance_id
        --         self:SwitchState(UIStateType.UIDrawCard, poolid)
        --     end
        -- )
    end
end

function UIDrawCardPoolItem:SetFreeTimerTex()
    local svrTime = math.floor(self._timeModule:GetServerTime() * 0.001)
    local lessTime = self._nextTime - svrTime
    if lessTime >= 0 then
        local timeStr = HelperProxy:GetInstance():Time2Tex(lessTime)
        self._freeTimeTex:SetText(timeStr)
    end
end
--获取单抽免费倒计时
function UIDrawCardPoolItem:GetSingleFreeTimer()
    --如果在持续时间内
    local closeTimer = self._uiData:CloseTimer_Single()
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local nowTimer = math.ceil(svrTimeModule:GetServerTime() * 0.001)
    if closeTimer < nowTimer then
        return false
    end

    --如果下次间隔时间比结束时间小
    local nextTimer = self._uiData:NextTimer_Single()
    if nextTimer == 0 then --下一次不再刷新的时候，服务器会返回0，有免费单抽未开始和已刷完最后1次两种情况
        return false
    end

    --如果下次间隔时间比卡池关闭时间小
    local poolCloseType = self._uiData.poolData.close_type
    if poolCloseType == PrizePoolOpenCloseType.TIME_CONDITON then
        local poolCloseTimer = self._uiData.poolData.extend_data
        if nextTimer >= poolCloseTimer then
            return false
        end
    end

    return true, nextTimer
end

function UIDrawCardPoolItem:GetMultipleFreeTimer()
    --如果在持续时间内

    local closeTimer = self._uiData:CloseTimer_Multi()
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local nowTimer = math.ceil(svrTimeModule:GetServerTime() * 0.001)
    if closeTimer < nowTimer then
        return false
    end

    --如果下次间隔时间比结束时间小
    local nextTimer = self._uiData:NextTimer_Multi()
    if nextTimer == 0 then --下一次不再刷新的时候，服务器会返回0，有免费十连未开始和已刷完最后1次两种情况
        return false
    end

    --如果下次间隔时间比卡池关闭时间小
    local poolCloseType = self._uiData.poolData.close_type
    if poolCloseType == PrizePoolOpenCloseType.TIME_CONDITON then
        local poolCloseTimer = self._uiData.poolData.extend_data
        if nextTimer >= poolCloseTimer then
            return false
        end
    end

    return true, nextTimer
end

function UIDrawCardPoolItem:_PoolCountCalcTest(idx)
    local _show = self:GetModule(GambleModule):GetShowPoolCountCalc()
    if _show then
        self._poolCountTest:SetActive(true)

        local count = self:GetModule(GambleModule):GetCounterNum(idx)
        Log.debug("###[UIDrawCardPoolItem] GetCounterNum idx --> ", idx, " | count --> ", count)
        self._poolCountText:SetText(count)
    else
        self._poolCountTest:SetActive(false)
    end
end

function UIDrawCardPoolItem:countDown()
    local now = math.floor(self._timeModule:GetServerTime() / 1000)
    local time = 0
    if self._uiData.poolData.close_condition2 and self._uiData.poolData.close_condition2 > 0 then
        time = self._uiData.poolData.close_condition2
    else
        time = self._uiData.poolData.extend_data
    end
    local sec = math.max(time - now, 0)
    local timeStr
    if sec > 86400 then
        local day = math.floor(sec / 86400)
        local hour = math.floor((sec % 86400) / 3600)
        timeStr = StringTable.Get("str_draw_card_time_1", day, hour)
    elseif sec <= 86400 and sec >= 3600 then
        local hour = math.floor(sec / 3600)
        local minu = math.floor((sec % 3600) / 60)
        timeStr = StringTable.Get("str_draw_card_time_2", hour, minu)
    elseif sec < 3600 and sec >= 60 then
        local minu = math.floor((sec % 3600) / 60)
        timeStr = StringTable.Get("str_draw_card_time_2_1", minu)
    else
        timeStr = StringTable.Get("str_draw_card_time_3")
    end
    if self._timeStr ~= timeStr then
        self._timeStr = timeStr
        local str = StringTable.Get("str_draw_card_pool_end_time") .. timeStr
        self._oneOpenTime:RefreshText(str)
        self._moreOpenTime:RefreshText(str)
    end
end

--概率
function UIDrawCardPoolItem:SetProbTips(idx)
    local prob_01, prob_02 = self:GetModule(GambleModule):GetProbs(idx)
    --local prob_01, prob_02 = 0, 0

    --新手池不显示
    if self._uiData.poolData.prize_pool_type == PrizePoolType.BEGINNER_POOL then
        self._prob:SetActive(false)
    else
        self._prob:SetActive(true)
    end

    local probTex
    if prob_02 <= 0 and prob_01 >= 100 then
        probTex = "<color=#fff718>" .. prob_01 .. "%</color>"
    else
        probTex = "<color=#fff718>" .. prob_01 .. "%+" .. prob_02 .. "%</color>"
    end
    local tex = StringTable.Get("str_draw_card_prob_tips") .. probTex

    --local tex = "本次6<sprite=obtain_donghua_xingxing2 />概率�??<color=#fff718>2.0%+2.0%</color>"
    self._probTex:SetText(tex)

    if self._probTex.gameObject.transform.childCount == 0 then
        return
    end
    local img1 = self._probTex.gameObject.transform:GetChild(0).gameObject
    local img2
    if img1.transform.childCount > 1 then
        img2 = img1.transform:GetChild(0).gameObject
    else
        img2 = UnityEngine.GameObject.Instantiate(img1, img1.transform)
    end
    img2:GetComponent("RectTransform").anchoredPosition =
        Vector2(
        img1:GetComponent("RectTransform").anchoredPosition.x,
        -img1:GetComponent("RectTransform").anchoredPosition.y
    )
    img1:GetComponent("Image").color = Color(1, 1, 1, 0)
end

--如果材料不足，显示红�??
function UIDrawCardPoolItem:FlushCost()
    if not self._itemModule then
        self._itemModule = self:GetModule(ItemModule)
    end
    if self._uiData:CanSingleDraw() then --有可能没有单抽材料
        --考虑到充值这里的data不会刷新数据，这里嗯enough每次都算一�?
        local singleMat = self._uiData.singleMat
        local singlePrice = self._uiData.singlePrice
        local haveSingle = self._itemModule:GetItemCount(singleMat)
        local isEnoughSingle = (haveSingle >= singlePrice)

        local color
        if isEnoughSingle then
            color = Color.white
        else
            color = Color(249 / 255, 54 / 255, 54 / 255)
        end
        self.singleCount.color = color
        self.oneNowPrice.color = color
    end

    --多抽
    self.multipleCount.color = Color(49 / 255, 49 / 255, 49 / 255)
    self.multipleBtnText.color = Color(49 / 255, 49 / 255, 49 / 255)
    self.tenNowPrice.color = Color(17 / 255, 127 / 255, 169 / 255)
    self.multipleIcon.color = Color.white
    --剩余多抽次数是否足够
    local timesEnough = true
    local closeType = self._uiData.poolData.close_type
    if closeType == PrizePoolOpenCloseType.PLAY_TIMES_CONDITON then
        if self._uiData.poolData.extend_data < self._uiData.poolData.multiple_shake_times then --剩余次数不足以多�??
            local color = Color(100 / 255, 100 / 255, 100 / 255)
            self.multipleCount.color = color
            self.multipleBtnText.color = color
            self.multipleIcon.color = Color(1, 1, 1, 0.4)
            timesEnough = false
        end
    end

    --_, discountPrice, discount = self._uiData:GetAssetsPrice(false)
    --local isEnoughMulti = false
    -- local isCostXB, xbId = self._uiData:IsCostXB()
    -- if isCostXB then
    --     isEnoughMulti, _ = self._uiData:IsXBEnough(discountPrice)
    -- elseif self._uiData:IsCostGp() then
    --     isEnoughMulti, _ = self._uiData:IsGPEnough(discountPrice)
    -- else
    --     local id1, id2 = self._uiData:Get2AssetId()
    --     local count = GameGlobal.GetModule(ItemModule):GetItemCount(id1)
    --     isEnoughMulti = count >= discountPrice
    -- end
    local mulitMat = self._uiData.multipleMat
    local mulitPrice = self._uiData.multiplePrice
    local haveMulti = self._itemModule:GetItemCount(mulitMat)
    local isEnoughMulti = (haveMulti >= mulitPrice)
    if isEnoughMulti then
    else
        local color = Color(249 / 255, 54 / 255, 54 / 255)
        self.multipleCount.color = color
        self.tenNowPrice.color = color
    end
end

function UIDrawCardPoolItem:OnItemCountChange()
    self:FlushCost()
end

---刷新logo信息
---@param idx number 要刷新的卡池索引
function UIDrawCardPoolItem:FlushLogos(idx)
    local times = self.gambleModule:GetNotIncludePetPoolGambleTimes(idx)
    local notIncludePool = times > -1

    local tPet, len = self:GetPetsByIndex(idx)
    if tPet then
        for i, logo in ipairs(self.logos) do
            if not notIncludePool and i <= len then
                logo.gameObject:SetActive(true)
                logo:LoadImage(tPet[i] .. "_logo")
            else
                logo.gameObject:SetActive(false)
            end
        end
    end
end

---@return number[], number 星灵id列表，长�??
function UIDrawCardPoolItem:GetPetsByIndex(idx)
    local data = self._poolDataList[idx]
    if data then
        local cfg = Cfg.cfg_drawcard_pool_view[data.poolData.performance_id]
        if cfg then
            local tPet = cfg.PetList
            local len = table.count(tPet)
            return tPet, len
        end
    end
    return nil, 0
end

function UIDrawCardPoolItem:OnUpdate(deltaTimeMS)
    if self.fsm then
        self.fsm:OnUpdate()
    end
    if self._countDownTimer then
        self._countDownTimer = self._countDownTimer + deltaTimeMS
        if self._countDownTimer > 1000 then
            self._countDownTimer = 0
            self:countDown()
        end
    end
end

---bgLogo移动
function UIDrawCardPoolItem:OnBGLogoMoving()
    local half = self:GetWidthHalf() --960
    local xBGLogo = half - self.bgLogo.anchoredPosition.x --self.bgLogo.anchoredPosition.x∈[-960,960] => xBGLogo∈[0, 1920]
    local v2 = Vector2.zero
    local speed = xBGLogo * 0.1 --系数控制lr偏移�??
    for i, tran in ipairs(self.lrRect) do
        local lrs = self.lrSpeed[i]
        if lrs then
            v2.x = speed * lrs
            tran.anchoredPosition = -v2
        else
            Log.fatal("### lrs nil. i=", i)
        end
    end
    ---Layer2Layer3位移渐隐
    local v2Layer = Vector2.zero
    v2Layer.x = speed * 2 * (self:IsFlip() and 1 or -1)
    self.layer2Rect.anchoredPosition = v2Layer
    self.tipsRT.anchoredPosition = v2Layer
    self.btnsRT.anchoredPosition = v2Layer
    self.onePetGoRT.anchoredPosition = v2Layer
    self.morePetGoRT.anchoredPosition = v2Layer
    local leftDownRtPos = self.leftDownRt.anchoredPosition
    leftDownRtPos.x = v2Layer.x
    self.leftDownRt.anchoredPosition = leftDownRtPos

    --alpha
    local alpha = Mathf.Clamp01(1 - xBGLogo / self._widthView * 1.2) --乘以一个大�??1的系数是为了让alpha尽快变为0
    self.layer2Group.alpha = alpha
    self.tipsCanvasGroup.alpha = alpha
    self.btnsCanvasGroup.alpha = alpha
    self.onePetGoCanvasGroup.alpha = alpha
    self.morePetGoCanvasGroup.alpha = alpha
    self.leftDownGoCanvasGroup.alpha = alpha
end

---是否翻转
function UIDrawCardPoolItem:IsFlip()
    if self.layer1Rect.localRotation == Quaternion.identity then
        return false
    end
    return true
end

function UIDrawCardPoolItem:ItemClick(id)
    self:ShowDialog("UIShopPetDetailController", id)
end

function UIDrawCardPoolItem:GetNumberCN(num)
    if num <= 0 then
        return nil
    elseif num < 11 then
        return StringTable.Get("str_draw_card_number_" .. num)
    elseif num < 100 then
        local gewei = num % 10
        local shiwei = math.floor(num / 10)

        local str = ""
        if shiwei == 1 then
            str = str .. StringTable.Get("str_draw_card_number_10")
        else
            str =
                str .. StringTable.Get("str_draw_card_number_" .. shiwei) .. StringTable.Get("str_draw_card_number_10")
        end
        if gewei == 0 then
            return str
        else
            return str .. StringTable.Get("str_draw_card_number_" .. gewei)
        end
    else
        return StringTable.Get("str_draw_card_number_99")
    end
end

--region OnClick
function UIDrawCardPoolItem:ButtonLastPoolOnClick()
    self.fsm:ChangeState(StateDrawCardPool.ClickArrow, false, self:GetIndex() - 1, self:GetClickArrowDuration())
end
function UIDrawCardPoolItem:ButtonNextPoolOnClick()
    self.fsm:ChangeState(StateDrawCardPool.ClickArrow, true, self:GetIndex() + 1, self:GetClickArrowDuration())
end
function UIDrawCardPoolItem:GetClickArrowDuration()
    return 0.06
end
function UIDrawCardPoolItem:DetailButtonOnClick(go)
    self:ShowDialog("UIDrawCardAwardPoolDetailController", self._uiData.poolData)
end
function UIDrawCardPoolItem:moreDetailButtonOnClick(go)
    self:ShowDialog("UIDrawCardAwardPoolDetailController", self._uiData.poolData)
end
function UIDrawCardPoolItem:onePetIconOnClick(go)
    local cfg = Cfg.cfg_drawcard_pool_view[self._uiData.poolData.performance_id]
    self:ShowDialog("UIShopPetDetailController", cfg.PetList[1])
end

function UIDrawCardPoolItem:ExtendTextBtnOnClick(go)
    local times = self.gambleModule:GetNotIncludePetPoolGambleTimes(self._uiData.index)
    if times > -1 then
        local petList = self.gambleModule:GetNotIncludePetPool(self._uiData.index)
        if not petList or #petList == 0 then
            --卡池中没有了
        elseif times == 0 then
            --未抽到
            self:ShowDialog("UIUnObtainSixPetController", petList)
        else
            --已抽到
        end
    else
        --other pool
    end
end
--endregion

--region DrawButton
function UIDrawCardPoolItem:SingleDrawButtonOnClick(go)
    self:SetIsSingle(true)
    self.fsmDrawCard:ChangeState(StateAssetExchange.DrawCard)
end
function UIDrawCardPoolItem:MultipleDrawButtonOnClick(go)
    if self._uiData.poolData.close_type == PrizePoolOpenCloseType.PLAY_TIMES_CONDITON then
        if self._uiData.poolData.extend_data < self._uiData.poolData.multiple_shake_times then --剩余次数不足以多�??
            return
        end
    end
    self:SetIsSingle(false)
    self.fsmDrawCard:ChangeState(StateAssetExchange.DrawCard)
end

function UIDrawCardPoolItem:GetIsSingle() --是否单抽
    return self._isSingle
end
function UIDrawCardPoolItem:SetIsSingle(isSingle)
    self._isSingle = isSingle
end
--endregion

---@return UIDrawCardPoolInfo
function UIDrawCardPoolItem:GetUIData()
    return self._uiData
end

---@return UnityEngine.Animation, string
function UIDrawCardPoolItem:GetAnimNameSwitch()
    return self._animation, "uieff_DrawCard_Switch"
end
function UIDrawCardPoolItem:GetAnimNameSwitchPool(idx)
    return self._animSwitchPool, "uieff_DrawCard_SwitchPool_" .. idx
end
function UIDrawCardPoolItem:GetLenLogos()
    return self._lenLogos
end

function UIDrawCardPoolItem:DOLock(isLock)
    local lockKey = "UIDrawCardPoolItem"
    if isLock then
        self:Lock(lockKey)
    else
        self:UnLock(lockKey)
    end
end

function UIDrawCardPoolItem:DoIndexerTween(nextIdx)
    self._controller:IndexerTweenWidth(nextIdx)
end

--region StateDrawCardPool
StateDrawCardPool = {
    Init = 0, --进入抽卡界面
    ClickArrow = 1, --点击箭头，mask移动�??0阶段
    Turn = 2, --翻页阶段1
    Return = 3, --返回
    TurnNext = 4 --翻页阶段2
}
--endregion

--region StateAssetExchange
StateAssetExchange = {
    Init = 0,
    DrawCard = 1, --抽卡
    Gp2Xb = 2, --光珀-星标
    Yj2Gp = 3, --耀�??-光珀
    Recharge = 4 --货币-耀�??
}
--endregion
