---@class UIAircraftSendGiftController:UIController
_class("UIAircraftSendGiftController", UIController)
UIAircraftSendGiftController = UIAircraftSendGiftController

function UIAircraftSendGiftController:OnShow(uiParam)
    self._petModule = self:GetModule(PetModule)
    ---@type MatchPet
    self._petData = uiParam[1]
    --初始化数据
    self._hasFavorableGift = false
    self._itemCountPerRow = 4

    self:_LoadVoiceRes()
    self:GetComponents()
    self:OnValue()
    self:AttachEvent(GameEventType.ClosePetAudio, self._StopPlayVoicePlayAnim)

    --GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftChangeGiftSending, true)
end

function UIAircraftSendGiftController:OnValue()
    self:Refresh()
end

function UIAircraftSendGiftController:GetComponents()
    --获取组件
    self._scrollView = self:GetUIComponent("UIDynamicScrollView", "GiftListScrollView")
    self._affinityLevelLabel = self:GetUIComponent("UILocalizationText", "AffinityLevel")
    self._curExpLabel = self:GetUIComponent("UILocalizationText", "CurrExp")
    self._maxExpLabel = self:GetUIComponent("UILocalizationText", "MaxExp")
    self._addExpLabel = self:GetUIComponent("UILocalizationText", "AddExp")
    self._affinityRelationNameLabel = self:GetUIComponent("UILocalizationText", "AffinityRelationName")
    self._affinityTr = self:GetUIComponent("Transform", "RelationShipRoot")

    self._affinityLevelMaxGo = self:GetGameObject("AffinityLevelMax")
    self._addExpGo = self:GetGameObject("AddExp")
    self._giveAwayGiftButtonPanelGo = self:GetGameObject("GiveAwayGiftButtonPanel")
    self._affinityMaxPanelGo = self:GetGameObject("AffinityMaxPanel")
    self._affinityExpBar1 = self:GetUIComponent("Image", "AffinityBar1")
    self._affinityExpBar2 = self:GetUIComponent("Slider", "AffinityBar2")
    self._attackValueLabel = self:GetUIComponent("UILocalizationText", "AttackValue")
    self._defendValueLabel = self:GetUIComponent("UILocalizationText", "DefendValue")
    self._hpValueLabel = self:GetUIComponent("UILocalizationText", "HpValue")
    self._playVoicePanel = self:GetGameObject("PlayVoice")
    self._normalVoiceIconGo = self:GetGameObject("NormalIcon")
    self._inteimacyVoiceIconGo = self:GetGameObject("IntimacyIcon")
    self._voiceContent = self:GetUIComponent("UILocalizationText", "VoiceContent")

    local s = self:GetUIComponent("UISelectObjectPath", "ItemTips")
    ---@type UISelectInfo
    self._tips = s:SpawnObject("UISelectInfo")

    self:AttachEvent(GameEventType.ItemCountChanged, self.OnItemCountChanged)
    --[[

    --返回按钮
    local backBtn = self:GetUIComponent("UISelectObjectPath", "BackBtns")
    ---@type UICommonTopButton
    local backBtns = backBtn:SpawnObject("UICommonTopButton")
    backBtns:SetData(
        function()
            self:CloseDialog()
        end,
        nil,
        nil,
        true
        )
        ]]
end

--攻击力
function UIAircraftSendGiftController:ShowAttackValue()
    local propertyConfig = Cfg.cfg_pet_affinity {PetID = self._petData:GetTemplateID()}
    local attack = 0
    local defend = 0
    local hp = 0
    if propertyConfig then
        local petAffinityConfig = nil
        for k, v in pairs(propertyConfig) do
            if v.AffinityLevel == self._curLevel then
                petAffinityConfig = v
                break
            end
        end
        if petAffinityConfig then
            attack = petAffinityConfig["Attack"]
            defend = petAffinityConfig["Defence"]
            hp = petAffinityConfig["Health"]
        end
    end
    self._attackValueLabel:SetText("+" .. attack)
    self._defendValueLabel:SetText("+" .. defend)
    self._hpValueLabel:SetText("+" .. hp)
end

--经验
function UIAircraftSendGiftController:ShowExp()
    local curExp = self._curExp - Cfg.cfg_pet_affinity_exp[self._curLevel].NeedAffintyExp
    local percent = curExp / self._curMaxExp
    if self._maxAffinityMaxLevel <= self._curLevel then --等级达到最大
        -- self._affinityLevelMaxGo:SetActive(true)
        self._affinityLevelMaxGo:SetActive(false)
        self._curExpLabel:SetText(self._curMaxExp)
        self._maxExpLabel:SetText(self._curMaxExp)
        percent = 1
    else
        self._affinityLevelMaxGo:SetActive(false)
        self._curExpLabel:SetText(curExp)
        self._maxExpLabel:SetText(self._curMaxExp)
    end

    if self._realLevel >= self._maxAffinityMaxLevel then
        self._addExpGo:SetActive(false)
    else
        if self._addExp ~= 0 then
            self._addExpGo:SetActive(true)
            self._addExpLabel:SetText("+" .. self._addExp)
        else
            self._addExpGo:SetActive(false)
        end
    end

    self._affinityLevelLabel:SetText(self._curLevel)
    self._affinityExpBar1.fillAmount = percent
    self._affinityExpBar2.value = percent

    local cfg = Cfg.cfg_pet_affinity_exp[self._curLevel] --实际的等级
    --self._affinityRelationNameLabel:SetText(StringTable.Get(cfg.Desc))

    if self._affinityTr.childCount > 0 then
        for i = 1, self._affinityTr.childCount do
            local cloneText = self._affinityTr:GetChild(i - 1).gameObject:GetComponent("UILocalizationText")
            cloneText:SetText(StringTable.Get(cfg.Desc))
        end
    end

    if self._realLevel >= self._maxAffinityMaxLevel then
        -- self._giveAwayGiftButtonPanelGo:SetActive(false)
        -- self._affinityMaxPanelGo:SetActive(true)
        self._giveAwayGiftButtonPanelGo:SetActive(true)
        self._affinityMaxPanelGo:SetActive(false)
    else
        self._giveAwayGiftButtonPanelGo:SetActive(true)
        self._affinityMaxPanelGo:SetActive(false)
    end
end

--宠物信息
function UIAircraftSendGiftController:GetPetValue()
    self._maxAffinityMaxLevel = self._petData:GetPetAffinityMaxLevel()
    local petConfig = Cfg.cfg_pet[self._petData:GetTemplateID()]
    self._functionType = petConfig.FunctionType
    self._tags = petConfig.Tags
    self._realLevel = self._petData:GetPetAffinityLevel()
    self._realExp = self._petData:GetPetAffinityExp()
    self._realMaxExp = self._petData:GetPetAffinityMaxExp(self._realLevel)

    self._lvChanged = false
    if self._realLevel ~= self._lastLv then
        self._lvChanged = true
    end

    self._curLevel = self._realLevel
    self._curExp = self._realExp
    self._curMaxExp = self._realMaxExp
    self._addExp = 0
end

function UIAircraftSendGiftController:OnItemCountChanged()
    self:InitScrollView()
end

function UIAircraftSendGiftController:InitScrollView()
    self:_CalRow()
    if self._scrollViewInited then
        self._scrollView:SetListItemCount(self._giftRow)
        self._scrollView:ResetListView()
        self._scrollView:RefreshAllShownItem()
    else
        self._scrollViewInited = true
        self._scrollView:InitListView(
            self._giftRow,
            function(scrollview, index)
                return self:_OnGeGiftItem(scrollview, index)
            end
        )
    end
end

--获取礼物信息
function UIAircraftSendGiftController:GetGiftData()
    self._itemModule = GameGlobal.GetModule(ItemModule)
    local itemDatas = self._itemModule:GetItemListBySubType(ItemSubType.ItemSubType_PetPresent)

    self._giftDatas = {}
    if itemDatas then
        local giftDatas = {}
        for i = 1, #itemDatas do
            local giftData = {}
            giftData.giftData = itemDatas[i]
            giftData.isSelected = false
            giftData.selectedCount = 0
            local templateId = itemDatas[i]:GetTemplateID()
            local cfg = Cfg.cfg_item_pet_present[templateId]
            if cfg then
                giftData.baseAffinity = cfg.BaseAffinity --增加的基础好感度
                giftData.extAffinity = cfg.ExtAffinity --增加的额外好感度
                giftData.forceFavorType = cfg.ForceFavorType --势力偏爱类型
                giftData.functionFavorType = cfg.FunctionFavorType --功能偏爱类型
                giftData.des = cfg.Desc
            end
            giftData.index = 0
            if self:IsFavorableGift(giftData) then
                giftData.index = 1
            end
            giftDatas[i] = giftData
        end
        self._giftDatas = giftDatas
    end
    self._giftDatas = self:_SortGiftDatas(self._giftDatas)
    self._giftCount = table.count(self._giftDatas)
end

function UIAircraftSendGiftController:Refresh()
    self:GetPetValue()
    self:ShowExp()
    self:ShowAttackValue()
    self:GetGiftData()
    self:InitScrollView()
end

function UIAircraftSendGiftController:OnHide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftChangeGiftSending, false)
    self:DetachEvent(GameEventType.ItemCountChanged, self.OnItemCountChanged)

    self:_StopPlayVoice()

    ---@type PetAudioModule
    local pm = GameGlobal.GetModule(PetAudioModule)
    pm:StopAll()
end

function UIAircraftSendGiftController:_LoadVoiceRes()
end

function UIAircraftSendGiftController:_StopPlayVoicePlayAnim()
    self:_StopPlayVoice()
end

function UIAircraftSendGiftController:_StopPlayVoice()
    -- self._playVoicePanel:SetActive(false)
end

function UIAircraftSendGiftController:_PlayVoice(isLove)
    self:_StopPlayVoice()
    ---@type PetAudioModule
    local pm = GameGlobal.GetModule(PetAudioModule)
    local l_play_audio_id = nil
    if isLove then
        l_play_audio_id = pm:PlayPetAudio("ReceiveLoveGift", self._petData:GetTemplateID(), true)
        self._normalVoiceIconGo:SetActive(false)
        self._inteimacyVoiceIconGo:SetActive(true)
    else
        l_play_audio_id = pm:PlayPetAudio("ReceiveGift", self._petData:GetTemplateID(), true)
        self._normalVoiceIconGo:SetActive(true)
        self._inteimacyVoiceIconGo:SetActive(false)
    end
    local l_config = AudioHelperController.GetCfgAudio(l_play_audio_id)
    self._voiceContent:SetText(HelperProxy:GetInstance():ReplacePlayerName(StringTable.Get(l_config.Content)))
    -- self._playVoicePanel:SetActive(true)
end

function UIAircraftSendGiftController:_SortGiftDatas(giftDatas)
    if not giftDatas then
        local emptyTable = {}
        return emptyTable
    end
    table.sort(
        giftDatas,
        function(a, b)
            if a.index ~= b.index then
                return a.index > b.index
            end
            return a.giftData:GetTemplateID() > b.giftData:GetTemplateID()
        end
    )
    return giftDatas
end

function UIAircraftSendGiftController:_RefreshPetAniffityInfo()
    local curExp = self._curExp - Cfg.cfg_pet_affinity_exp[self._curLevel].NeedAffintyExp
    local percent = curExp / self._curMaxExp
    if self._maxAffinityMaxLevel <= self._curLevel then --等级达到最大
        -- self._affinityLevelMaxGo:SetActive(true)
        self._affinityLevelMaxGo:SetActive(false)
        self._curExpLabel:SetText(self._curMaxExp)
        self._maxExpLabel:SetText(self._curMaxExp)
        percent = 1
    else
        self._affinityLevelMaxGo:SetActive(false)
        self._curExpLabel:SetText(curExp)
        self._maxExpLabel:SetText(self._curMaxExp)
    end

    if self._realLevel >= self._maxAffinityMaxLevel then
        self._addExpGo:SetActive(false)
    else
        if self._addExp ~= 0 then
            self._addExpGo:SetActive(true)
            self._addExpLabel:SetText("+" .. self._addExp)
        else
            self._addExpGo:SetActive(false)
        end
    end

    self._affinityLevelLabel:SetText(self._curLevel)
    self._affinityExpBar1.fillAmount = percent
    self._affinityExpBar2.value = percent

    local cfg = Cfg.cfg_pet_affinity_exp[self._curLevel] --实际的等级
    --self._affinityRelationNameLabel:SetText(StringTable.Get(cfg.Desc))
    if self._affinityTr.childCount > 0 then
        for i = 1, self._affinityTr.childCount do
            local cloneText = self._affinityTr:GetChild(i - 1).gameObject:GetComponent("UILocalizationText")
            cloneText:SetText(StringTable.Get(cfg.Desc))
        end
    end

    if self._realLevel >= self._maxAffinityMaxLevel then
        -- self._giveAwayGiftButtonPanelGo:SetActive(false)
        -- self._affinityMaxPanelGo:SetActive(true)
        self._giveAwayGiftButtonPanelGo:SetActive(true)
        self._affinityMaxPanelGo:SetActive(false)
    else
        self._giveAwayGiftButtonPanelGo:SetActive(true)
        self._affinityMaxPanelGo:SetActive(false)
    end
    self:ShowAttackValue()
end

function UIAircraftSendGiftController:_CalRow()
    self._giftRow = math.ceil(self._giftCount / self._itemCountPerRow)
    if self._giftRow < 4 then
        self._giftRow = 4
    end
end

function UIAircraftSendGiftController:_InitScrollView()
    self._scrollView:InitListView(
        self._giftRow,
        function(scrollview, index)
            return self:_OnGeGiftItem(scrollview, index)
        end
    )
end

function UIAircraftSendGiftController:_SetListItemCount()
    self._scrollView:SetListItemCount(self._giftRow)
end

function UIAircraftSendGiftController:_OnGeGiftItem(scrollView, index)
    if index < 0 then
        return nil
    end

    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UIAircraftSendGiftItem", self._itemCountPerRow)
    end

    local rowList = rowPool:GetAllSpawnList()
    for i = 1, self._itemCountPerRow do
        local itemWidget = rowList[i]
        local itemIndex = index * self._itemCountPerRow + i
        self:_RefreshGiftItemInfo(itemWidget, itemIndex)
    end
    return item
end

---@param itemWidget UIAircraftSendGiftItem
function UIAircraftSendGiftController:_RefreshGiftItemInfo(itemWidget, index)
    itemWidget:Refresh(
        self._petData,
        self._giftDatas[index],
        function(giftData, isAdd)
            return self:OnItemClicked(giftData, isAdd)
        end,
        function(itemId, pos)
            self:ShowItemTips(itemId, pos)
        end,
        function()
            self:CloseItemTips()
        end,
        function(giftData)
            return self:IsFavorableGift(giftData)
        end
    )
end

function UIAircraftSendGiftController:OnItemClicked(giftData, isAdd)
    if giftData == nil then
        return false
    end

    if self._realLevel < self._maxAffinityMaxLevel then
        if isAdd and self._curLevel >= self._maxAffinityMaxLevel then
            return false
        end
    end

    -- if self._realLevel >= self._maxAffinityMaxLevel then
    --     return false
    -- end

    -- if isAdd and self._curLevel >= self._maxAffinityMaxLevel then
    --     return false
    -- end

    local affinityValue = 0
    if giftData.baseAffinity then
        affinityValue = affinityValue + giftData.baseAffinity
    end
    if self:IsFavorableGift(giftData) then
        affinityValue = affinityValue + giftData.extAffinity
    end

    if isAdd then
        self._addExp = self._addExp + affinityValue
        self._curExp = self._curExp + affinityValue
    else
        self._addExp = self._addExp - affinityValue
        self._curExp = self._curExp - affinityValue
    end
    self:_CalPetData()
    self:_RefreshPetAniffityInfo()
    return true
end

function UIAircraftSendGiftController:_CalPetData()
    for i = 1, self._maxAffinityMaxLevel do
        local expCfg = Cfg.cfg_pet_affinity_exp[i]
        if expCfg.NeedAffintyExp > self._curExp then
            self._curLevel = i - 1
            break
        end
        if i == self._maxAffinityMaxLevel then
            self._curLevel = self._maxAffinityMaxLevel
        end
    end
    self._curMaxExp = self._petData:GetPetAffinityMaxExp(self._curLevel)
end

function UIAircraftSendGiftController:ButtonClearOnClick()
    self:Refresh()
end

function UIAircraftSendGiftController:ButtonSendOnClick()
    local items = self:_GetSelectedGiftItems()
    if table.count(items) <= 0 then
        return
    end

    if self._maxAffinityMaxLevel <= self._realLevel then
        PopupManager.Alert(
            "UICommonMessageBox",
            PopupPriority.Normal,
            PopupMsgBoxType.OkCancel,
            "",
            StringTable.Get("str_affinity_level_has_reachmax"),
            function(param)
                self:Lock("ButtonSendOnClick")
                --获取一下当前真实等级
                self._lastLv = self._petData:GetPetAffinityLevel()
                GameGlobal.TaskManager():StartTask(self._SendGiftMsg, self, items)
            end,
            nil,
            function(param)
            end,
            nil
        )
    else
        self:Lock("ButtonSendOnClick")
        --获取一下当前真实等级
        self._lastLv = self._petData:GetPetAffinityLevel()
        GameGlobal.TaskManager():StartTask(self._SendGiftMsg, self, items)
    end
end

--发送消息
function UIAircraftSendGiftController:_SendGiftMsg(TT, items)
    local res, replay = self._petModule:RequestGivePetPresent(TT, self._petData:GetPstID(), items)
    self:UnLock("ButtonSendOnClick")
    if res:GetSucc() then
        self:Refresh()
        --self:_PlayVoice(self._hasFavorableGift)
        -- local tab = {}
        -- if replay.trigger_story_event_id and replay.trigger_story_event_id ~= 0 then
        --     table.insert(tab, replay.trigger_story_event_id)
        -- end
        if replay.trigger_story_event_id and replay.trigger_story_event_id ~= 0 then
            --self:_PickPetTaskReward(tab)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.SendGiftRandomStory, replay.trigger_story_event_id)
            return
        end
        -- GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftOnSendGiftSuccess, self._hasFavorableGift)
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.AircraftOnSendGiftSuccess,
            self._lvChanged,
            self._hasFavorableGift
        )

        Log.debug("###UIAircraftSendGiftController send success !")
    else
        Log.fatal("###UIAircraftSendGiftController:_SendGiftMsg err:", res.m_result)
    end
end

function UIAircraftSendGiftController:_GetSelectedGiftItems()
    self._hasFavorableGift = false
    local items = {}
    local giftCount = table.count(self._giftDatas)
    for i = 1, giftCount do
        local giftData = self._giftDatas[i]
        if giftData.isSelected then
            local item = ItemAsset:New()
            item.assetid = giftData.giftData:GetID()
            item.count = giftData.selectedCount
            table.insert(items, item)
            if self:IsFavorableGift(giftData) then
                self._hasFavorableGift = true
            end
        end
    end
    return items
end

function UIAircraftSendGiftController:_PickPetTaskReward(storyIds)
    local s = storyIds
    local idx = 1
    if s and #s > 0 then
        local cfg_pet_story = Cfg.cfg_pet_story[s[idx]]
        if cfg_pet_story == nil then
            Log.fatal("#######UIAircraftSendGiftController:_PickPetTaskReward -- cfg_pet_story == nil", s[idx])
        end
        local storyid = cfg_pet_story.StoryID
        self:ShowDialog(
            "UIStoryController",
            storyid,
            function()
                idx = idx + 1
                if s[idx] then
                    Log.debug("##该星灵还有一个剧情，先把星灵移到触发点，然后关闭送礼")
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.AirStartOneRandomEvent, s[idx])
                end
            end
        )
    end
end

function UIAircraftSendGiftController:ShowItemTips(itemId, pos)
    self._tips:SetData(itemId, pos)
end
function UIAircraftSendGiftController:CloseItemTips()
    self._tips:closeOnClick()
end

function UIAircraftSendGiftController:IsFavorableGift(giftData)
    if giftData.forceFavorType and self._tags then
        for i = 1, #self._tags do
            if self._tags[i] == giftData.forceFavorType then
                return true
            end
        end
    end
    if giftData.functionFavorType and self._functionType and giftData.functionFavorType == self._functionType then
        return true
    end
    return false
end

function UIAircraftSendGiftController:bgOnClick()
    self:CloseDialog()
end
