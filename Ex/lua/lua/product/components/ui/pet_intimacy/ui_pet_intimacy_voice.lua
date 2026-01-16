---@class UIPetIntimacyVoice:Object
_class("UIPetIntimacyVoice", Object)
UIPetIntimacyVoice = UIPetIntimacyVoice

---@param petData Pet
function UIPetIntimacyVoice:Constructor(intimacyMainController, petData)
    ---@type UIPetIntimacyMainController
    self._intimacyMainController = intimacyMainController
    self._petData = petData
    self._isInited = false
end

function UIPetIntimacyVoice:Init()
    self.voiceType = {}
    self.voiceFilter = {}

    local cfg_filter_voice = Cfg.pet_voice_file {}
    for i = 1, #cfg_filter_voice do
        self.voiceType[#self.voiceType + 1] = cfg_filter_voice[i].VoiceType
    end
    for i = 1, #cfg_filter_voice do
        self.voiceFilter[#self.voiceFilter + 1] = cfg_filter_voice[i].VoiceFilter
    end
    -- self.voiceType = {
    --     [1] = "MainLobbyInteract",
    --     [2] = "Obtain",
    --     [3] = "LevelUp",
    --     [4] = "Grade1Up",
    --     [5] = "Grade2Up",
    --     [6] = "Charge",
    --     [7] = "Skill",
    --     [8] = "TeamLeaderAppear",
    --     [9] = "BattleSucceed",
    --     [10] = "BattleFail",
    --     [11] = "AircraftInteract",
    --     [12] = "Story1",
    --     [13] = "Story2",
    --     [14] = "Story3"
    -- }
    self._scrollView = self._intimacyMainController:GetUIComponent("UIDynamicScrollView", "VoiceListScrollView")

    self:_InitVoiceData()
    self:_InitScrollView()
    --暂停播放语音
    ---@type PetAudioModule
    local pm = GameGlobal.GetModule(PetAudioModule)
    pm:StopAll()
end

function UIPetIntimacyVoice:Refresh()
    if self._isInited then
        self._currentPlayVoiceData = nil
        self._currentPlayVoiceItem = nil
        self._currentPlayingID = nil
        self:_InitVoiceData()
        self._scrollView:ResetListView()
        self._scrollView:RefreshAllShownItem()
    else
        self:Init()
        self._isInited = true
    end
end

function UIPetIntimacyVoice:CloseWindow()
    self:StopPlayVoice()
    self._intimacyMainController:StopPlayVoice()
end

function UIPetIntimacyVoice:Destroy()
    self:StopPlayVoice()
    if self._voiceCount then
        for i = 1, self._voiceCount do
            AudioHelperController.ReleaseUIVoice(self._voiceDatas[i].resName)
        end
    end
end

function UIPetIntimacyVoice:Update()
    if self._currentPlayVoiceData and self._currentPlayingID then
        local isPlaying = AudioHelperController.CheckUIVoicePlaying(self._currentPlayingID)
        if not isPlaying then
            self:StopPlayVoice()
            self._currentPlayingID = nil
        end
    end
end

function UIPetIntimacyVoice:_InitVoiceData()
    self._currentPlayVoiceData = nil
    self._currentPlayVoiceItem = nil
    self._currentPlayingID = nil

    self._voiceDatas = {}
    local index = 1

    local petModule = GameGlobal.GetModule(PetModule)
    local petAudioModule = GameGlobal.GetModule(PetAudioModule)
    local cfgs_skin = Cfg.cfg_pet_voice {PetID = self._petData:GetTemplateID()}
    if cfgs_skin and next(cfgs_skin) then
        for k = 1, #cfgs_skin do
            local cfg_skin = cfgs_skin[k]

            local voiceNameConfig = Cfg.pet_voice_name[1]
            for j = 1, #self.voiceType do
                local v = self.voiceType[j]
                if type(cfg_skin[v]) == "table" then
                    local voiceDataArr = cfg_skin[v]
                    if voiceDataArr then
                        for i = 1, #voiceDataArr do
                            local voiceData = {}
                            voiceData.index = index
                            voiceData.voiceId = voiceDataArr[i][1]
                            voiceData.isPlay = false
                            voiceData.condition = voiceDataArr[i][2]

                            local unLock = true
                            if voiceData.condition and voiceData.condition ~= -1 then
                                unLock = petAudioModule:IsUnLock(voiceData.condition, self._petData)
                            end

                            --忽略解锁条件
                            if not unLock then
                                local ignore = false
                                local ignoreList = self.voiceFilter[j]
                                for _, ignoreItem in pairs(ignoreList) do
                                    local ignoreCondition = ignoreItem
                                    if ignoreCondition == voiceData.condition then
                                        ignore = true
                                        break
                                    end
                                end
                                if ignore then
                                    unLock = true
                                end
                            end

                            if voiceData.condition then
                                local conditionCfg = Cfg.pet_intimacy_condition[voiceData.condition]
                                if conditionCfg then
                                    if conditionCfg.ConditionType == 1 then --星灵好感度
                                        voiceData.isIntimacy = true
                                    end
                                end
                            end
                            if #voiceDataArr > 1 then
                                voiceData.name = StringTable.Get(voiceNameConfig[v]) .. i
                            else
                                voiceData.name = StringTable.Get(voiceNameConfig[v])
                            end
                            if voiceDataArr[i][3] then
                                local skinid = cfg_skin.SkinID
                                if Cfg.cfg_pet_skin[skinid] == nil then
                                    break
                                end
                                voiceData.isSkin = true
                                local skinUnLock = true
                                
                                local haveSkin = petModule:HaveSkin(skinid)
                                if not haveSkin then
                                    skinUnLock = false
                                end
                                voiceData.skinUnLock = skinUnLock
                                voiceData.skinID = skinid
                                --拼接皮肤名字
                                local cfg_skin = Cfg.cfg_pet_skin[skinid]
                                if not cfg_skin then
                                    Log.error("###[UIPetIntimacyVoice] cfg_skin is nil ! id --> ", skinid)
                                else
                                    voiceData.name =
                                        StringTable.Get("str_affinity_only_skin", StringTable.Get(cfg_skin.SkinName)) ..
                                        voiceData.name
                                end
                            end

                            voiceData.unLock = unLock
                            voiceData.isIntimacy = false

                            if voiceData.name == nil then
                                Log.fatal("###-->v-->", v, "|id-->", voiceData.voiceId)
                            end
                            local audioConfig = AudioHelperController.GetCfgAudio(voiceData.voiceId)
                            voiceData.content =
                                HelperProxy:GetInstance():ReplacePlayerName(StringTable.Get(audioConfig.Content))
                            voiceData.resName = USEADX2AUDIO and voiceData.voiceId or audioConfig.ResName
                            self._voiceDatas[index] = voiceData
                            index = index + 1
                        end
                    end
                end
            end
        end
    end

    --去重
    self:FilterList()

    self._voiceCount = #self._voiceDatas
    ---注册音效资源
    for i = 1, self._voiceCount do
        AudioHelperController.RequestUIVoice(self._voiceDatas[i].resName)
    end
end
--去重
function UIPetIntimacyVoice:FilterList()
    local tmpDatas = {}
    for i = 1, #self._voiceDatas do
        table.insert(tmpDatas, self._voiceDatas[i])
        -- Log.fatal("###id-->", self._voiceDatas[i].voiceId)
    end
    table.clear(self._voiceDatas)

    for i = 1, #tmpDatas do
        local tmp = tmpDatas[i]

        --1-舍弃后一个,2-舍弃前一个
        local same = 0
        local removeIdx = 0
        for j = 1, #self._voiceDatas do
            local tmp2 = self._voiceDatas[j]
            if tmp2.voiceId == tmp.voiceId then
                if tmp2.unLock then
                    -- Log.fatal("###id重复，舍弃后一个,id-->", tmp.voiceId)
                    same = 1
                else
                    if tmp.unLock then
                        -- Log.fatal("###id重复，舍弃前一个,id-->", tmp.voiceId)
                        same = 2
                        removeIdx = j
                    else
                        -- Log.fatal("###id重复，舍弃后一个,id-->", tmp.voiceId)
                        --都没解锁，舍弃后一个
                        same = 1
                    end
                end
                break
            end
        end

        if same == 1 then
        elseif same == 2 then
            table.remove(self._voiceDatas, removeIdx)
            table.insert(self._voiceDatas, tmp)
        else
            table.insert(self._voiceDatas, tmp)
        end
    end

    for i = 1, #self._voiceDatas do
        self._voiceDatas[i].index = i
    end
end

function UIPetIntimacyVoice:_InitScrollView()
    self._scrollView:InitListView(
        self._voiceCount,
        function(scrollview, index)
            return self:_OnGetVoiceItem(scrollview, index)
        end
    )
end

function UIPetIntimacyVoice:_OnGetVoiceItem(scrollView, index)
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self._intimacyMainController:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UIPetIntimacyVoiceItem", 1)
    end
    local rowList = rowPool:GetAllSpawnList()
    local itemWidget = rowList[1]
    if itemWidget then
        local itemIndex = index + 1
        if itemIndex > self._voiceCount then
            itemWidget:GetGameObject():SetActive(false)
        else
            self:_RefreshVoiceItemInfo(itemWidget, itemIndex)
        end
    end
    UIHelper.RefreshLayout(item:GetComponent("RectTransform"))
    return item
end

function UIPetIntimacyVoice:_RefreshVoiceItemInfo(itemWidget, index)
    -- index 从1开始
    itemWidget:Refresh(self._intimacyMainController, self, self._petData, self._voiceDatas[index])
end

function UIPetIntimacyVoice:PlayVoice(voiceData, voiceItem)
    if not voiceData or not voiceItem then
        return
    end

    self:StopPlayVoice()
    self._currentPlayVoiceData = voiceData
    self._currentPlayVoiceItem = voiceItem
    self._currentPlayVoiceData.isPlay = true

    self._currentPlayVoiceItem:RefreshVoiceStatus()
    self._scrollView:RefreshAllShownItem()
    self._intimacyMainController:PlayVoice(voiceData.content, not voiceData.isIntimacy)

    self._currentPlayingID = AudioHelperController.PlayUIVoice(voiceData.resName, false)
end

function UIPetIntimacyVoice:StopPlayVoice()
    if self._currentPlayVoiceData then
        self._currentPlayVoiceData.isPlay = false
    end
    self._currentPlayVoiceData = nil

    if self._currentPlayVoiceItem then
        self._currentPlayVoiceItem:RefreshVoiceStatus()
    end
    self._currentPlayVoiceItem = nil

    if self._currentPlayingID then
        AudioHelperController.StopUIVoice(self._currentPlayingID)
    end
    self._currentPlayingID = nil

    if self._scrollView then
        self._scrollView:RefreshAllShownItem()
    end

    -- self._intimacyMainController:StopPlayVoice()
end
