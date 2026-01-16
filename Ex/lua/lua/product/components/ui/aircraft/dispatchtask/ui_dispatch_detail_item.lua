---@class UIDispatchDetailItem:UICustomWidget
_class("UIDispatchDetailItem", UICustomWidget)
UIDispatchDetailItem = UIDispatchDetailItem

function UIDispatchDetailItem:OnShow(uiParams)
    self.Element2ImageName = {
        [ElementType.ElementType_Blue] = "str_shop_pet_shui",
        [ElementType.ElementType_Red] = "str_shop_pet_huo",
        [ElementType.ElementType_Green] = "str_shop_pet_sen",
        [ElementType.ElementType_Yellow] = "str_shop_pet_lei"
    }
    self.ElementSpriteName = {
        [ElementType.ElementType_Blue] = "bing_color",
        [ElementType.ElementType_Red] = "huo_color",
        [ElementType.ElementType_Green] = "sen_color",
        [ElementType.ElementType_Yellow] = "lei_color"
    }
    self._prof2Img = {
        [2001] = "spirit_prof_5",
        [2002] = "spirit_prof_1",
        [2003] = "spirit_prof_3",
        [2004] = "spirit_prof_7"
    }
    self._prof2Tex = {
        [2001] = "str_pet_tag_job_name_color_change",
        [2002] = "str_pet_tag_job_name_return_blood",
        [2003] = "str_pet_tag_job_name_attack",
        [2004] = "str_pet_tag_job_name_function"
    }
    self._uiHeartItemAtlas = self:GetAsset("UIHeartItem.spriteatlas", LoadType.SpriteAtlas)
    ---@type AircraftModule
    self._aircraftModule = GameGlobal.GetModule(AircraftModule)
    ---@type AircraftDispatchRoom
    self._roomData = self._aircraftModule:GetRoomByRoomType(AirRoomType.DispatchRoom)
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)

    self._taskNameLabel = self:GetUIComponent("UILocalizationText", "TaskName")
    self._starLoader = self:GetUIComponent("UISelectObjectPath", "StarPanel")
    self._taskDesLabel = self:GetUIComponent("UILocalizationText", "TaskDes")
    self._suggestName1Label = self:GetUIComponent("UILocalizationText", "SuggestName1")
    self._suggestName2Label = self:GetUIComponent("UILocalizationText", "SuggestName2")
    self._suggestIcon1Img = self:GetUIComponent("RawImageLoader", "SuggestIcon1")
    self._suggestIcon1Go = self:GetGameObject("SuggestIcon1")
    self._profIcon1Img = self:GetUIComponent("Image", "ProfIcon1")
    self._profIcon1Go = self:GetGameObject("ProfIcon1")
    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlasProperty = self:GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)
    self._elementIconGo = self:GetGameObject("ElementIcon")
    ---@type UnityEngine.UI.Image
    self._elementIconImg = self:GetUIComponent("Image", "ElementIcon")
    self._profIcon2Img = self:GetUIComponent("Image", "ProfIcon2")
    self._profIcon2Go = self:GetGameObject("ProfIcon2")
    self._rewardLoader = self:GetUIComponent("UISelectObjectPath", "RewardList")
    self._petLoader = self:GetUIComponent("UISelectObjectPath", "PetList")
    self._taskTimePanel = self:GetGameObject("TaskTimePanel")
    self._taskTimeLabel = self:GetUIComponent("UILocalizationText", "TaskTime")
    self._autoSelectBtnGo = self:GetGameObject("AutoSelectBtn")
    self._dispatchtBtnGo = self:GetGameObject("DispatchtBtn")
    self._tipsLabel = self:GetUIComponent("UILocalizationText", "Tips")
    self._tipsGo = self:GetGameObject("Tips")
    self._giveUpBtnGo = self:GetGameObject("GiveUpBtn")
    self._extraRewardItem = nil
    self:AttachEvent(GameEventType.UpdateDispatchPetList, self._RefreshPetInfo)
    self:AttachEvent(GameEventType.UpdateDispatchTaskItemInfo, self.RefreshTaskStatus)
end

function UIDispatchDetailItem:OnHide()
    self._uiHeartItemAtlas = nil
    if self._timer then
        GameGlobal.Timer():CancelEvent(self._timer)
        self._timer = nil
    end
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
    self:DetachEvent(GameEventType.UpdateDispatchPetList, self._RefreshPetInfo)
    self:DetachEvent(GameEventType.UpdateDispatchTaskItemInfo, self.RefreshTaskStatus)
end

---@param detailController UIDispatchDetailController
function UIDispatchDetailItem:Refresh(index, detailController)
    self._pointIndex = index
    ---@type UIDispatchDetailController
    self._detailController = detailController
    --工作中星灵列表，key是星灵pstid, value是空间id
    self._workingPets = self._detailController:GetWorkingPets()
    local siteInfo = self._roomData:GetSiteInfo(self._pointIndex)
    self._siteInfo = siteInfo
    if not siteInfo then
        self._detailController:Close()
        return
    end
    ---@type DispatchTaskStateType
    local state = siteInfo.state
    if state == DispatchTaskStateType.DTST_Invalid then
        self._detailController:Close()
        return
    end
    local taskId = siteInfo.taskId
    local taskCfgs = Cfg.cfg_aircraft_dispatch_task {ID = taskId}
    self._taskCfg = taskCfgs[1]
    --刷新基础信息
    self:_RefreshBaseInfo()
    --刷新推荐星灵信息
    self:_RefreshSuggestInfo()
    --刷新星灵信息
    self:_RefreshPetInfo()
    --刷新奖励信息
    self:_RefreshReward(false)
    --刷新任务状态信息
    self:_RefreshTaskStatusInfo()
end

function UIDispatchDetailItem:GetSiteInfo()
    return self._siteInfo
end

function UIDispatchDetailItem:GetTaskState()
    return self._siteInfo.state
end

function UIDispatchDetailItem:GetSiteId()
    return self._pointIndex
end

function UIDispatchDetailItem:GetSuggestInfo()
    return self._taskCfg.AssignPetId, self._taskCfg.AssignPetType
end

---@param pet Pet
function UIDispatchDetailItem:IsSuggestPet(pet)
    --势力
    local extraForce = self._taskCfg.ExtraForce
    if extraForce and extraForce > 0 then
        local tags = pet:GetPetTags()
        local tag = tags[1]
        if tag ~= extraForce then
            return false
        end
    end
    --属性
    local extraElement = self._taskCfg.ExtraElement
    if extraElement and extraElement > 0 then
        if pet:GetPetFirstElement() ~= extraElement then
            return false
        end
    end
    --职业
    local extraJop = self._taskCfg.ExtraJop
    if extraJop and extraJop > 0 then
        if pet:GetProf() ~= extraJop then
            return false
        end
    end
    return true
end

---@param pet Pet
function UIDispatchDetailItem:GetWorkingSpace(pet)
    -- return self._workingPets[pet:GetPstID()]
    return nil
end

function UIDispatchDetailItem:IsSuggestPetIsElement()
    local extraElement = self._taskCfg.ExtraElement
    if extraElement and extraElement > 0 then
        return true
    end
    return false
end

function UIDispatchDetailItem:RefreshTaskStatus()
    local siteInfo = self._roomData:GetSiteInfo(self._pointIndex)
    self._siteInfo = siteInfo
    local maxCount = self._roomData:GetTeamMemberMaxNum()
    for i = 1, maxCount do
        self._dispatchPets[i] = nil
    end

    local teamMembers = self._siteInfo.teamMember
    if teamMembers then
        ---@type PetModule
        local petModule = GameGlobal.GetModule(PetModule)
        for i = 1, maxCount do
            local pstId = teamMembers[i]
            if pstId and pstId > 0 then
                local pet = petModule:GetPet(pstId)
                self._dispatchPets[i] = pet
            end
        end
    end
    self:_RefreshPetInfo()
    self:_RefreshReward(false)
    self:_RefreshTaskStatusInfo()
end

function UIDispatchDetailItem:_RefreshBaseInfo()
    self._taskNameLabel.text = StringTable.Get(self._taskCfg.Name)
    self._taskDesLabel.text = StringTable.Get(self._taskCfg.Des)
    self._starLoader:SpawnObjects("UIDispatchTaskStar", self._taskCfg.Star)
end

function UIDispatchDetailItem:_RefreshSuggestInfo()
    --显示顺序从左到右为：势力 > 职业 > 属性。
    local extraForce, extraElement, extraJop = self:GetSuggestCfg()
    --第一个推荐图标
    if extraForce and extraForce > 0 then --势力
        self._suggestIcon1Go:SetActive(true)
        self._profIcon1Go:SetActive(false)
        local tagCfg = Cfg.cfg_pet_tags[extraForce]
        self._suggestName1Label.text = StringTable.Get(tagCfg.Name)
        self._suggestIcon1Img:LoadImage(tagCfg.Icon)
    elseif extraJop and extraJop > 0 then --职业
        self._suggestIcon1Go:SetActive(false)
        self._profIcon1Go:SetActive(true)
        self._suggestName1Label.text = StringTable.Get(self._prof2Tex[extraJop])
        self._profIcon1Img.sprite = self._uiHeartItemAtlas:GetSprite(self._prof2Img[extraJop])
    end
    --第二个推荐图标
    if extraElement and extraElement > 0 then --属性
        self._elementIconGo:SetActive(true)
        self._profIcon2Go:SetActive(false)
        self._suggestName2Label.text = StringTable.Get(self.Element2ImageName[extraElement])
        self._elementIconImg.sprite =
            self.atlasProperty:GetSprite(
            UIPropertyHelper:GetInstance():GetColorBlindSprite(self.ElementSpriteName[extraElement])
        )
    elseif extraJop and extraJop > 0 then --职业
        self._elementIconGo:SetActive(false)
        self._profIcon2Go:SetActive(true)
        self._suggestName2Label.text = StringTable.Get(self._prof2Tex[extraJop])
        self._profIcon2Img.sprite = self._uiHeartItemAtlas:GetSprite(self._prof2Img[extraJop])
    end
end

function UIDispatchDetailItem:GetSuggestCfg()
    return self._taskCfg.ExtraForce, self._taskCfg.ExtraElement, self._taskCfg.ExtraJop
end

function UIDispatchDetailItem:_RefreshReward(isPlayAnim)
    --奖励
    local baseRewards, extraRewards, bookOrFuniture =
        self._roomData:GetAward(self._siteInfo.awardId, self._siteInfo.taskId)
    local rewardCount = #baseRewards + #extraRewards + #bookOrFuniture
    self._rewardLoader:SpawnObjects("UIDispatchRewardItem", rewardCount)
    local rewardList = self._rewardLoader:GetAllSpawnList()
    local rewards = {}
    for i = #baseRewards, 1, -1 do
        local itemId = baseRewards[i].id
        if itemId == RoleAssetID.RoleAssetGlow then
            rewards[#rewards + 1] = baseRewards[i]
            table.remove(baseRewards, i)
            break
        end
    end
    for i = #baseRewards, 1, -1 do
        local itemId = baseRewards[i].id
        if itemId == RoleAssetID.RoleAssetGold then
            rewards[#rewards + 1] = baseRewards[i]
            table.remove(baseRewards, i)
            break
        end
    end
    for i = #baseRewards, 1, -1 do
        local itemId = baseRewards[i].id
        local itemCfgs = Cfg.cfg_item {ID = itemId}
        if itemCfgs then
            local itemCfg = itemCfgs[1]
            if itemCfg.ItemSubType == ItemSubType.ItemSubType_PetExp then
                rewards[#rewards + 1] = baseRewards[i]
                table.remove(baseRewards, i)
            end
        end
    end
    for i = 1, #baseRewards do
        rewards[#rewards + 1] = baseRewards[i]
    end
    --基础奖励
    for i = 1, #rewards do
        local rewardInfo = {
            id = rewards[i].id,
            count = rewards[i].count,
            des = nil,
            isNew = false,
            isMax = false,
            isBook = false,
            isFuniture = false,
            isExtraReward = false,
            maxCount = rewards[i].count
        }
        ---@type UIDispatchRewardItem
        local item = rewardList[i]
        item:Refresh(
            rewardInfo,
            function()
                self:_RewardItemOnClick(rewardInfo, item:GetGameObject(), false)
            end,
            false
        )
    end
    self._extraRewardItem = nil
    --额外奖励
    if #extraRewards > 0 then
        local isMax = false
        local extraMaxCount = extraRewards[1].count
        local count = extraMaxCount
        if table.count(self._dispatchPets) <= 0 then
            count = "0~" .. extraMaxCount
        else
            --根据星灵获取奖励数量
            local currentSocre = self._roomData:GetScore(self._dispatchPets, self._siteInfo.taskId)
            local score = self._taskCfg.Score
            local percent = 1
            if score ~= 0 then
                percent = currentSocre / score
            end
            if percent > 1 then
                percent = 1
            end
            local countRes = math.floor(extraMaxCount * percent)
            count = countRes
            if countRes >= extraMaxCount then
                isMax = true
            end
        end
        local rewardInfo = {
            id = extraRewards[1].id,
            count = count,
            des = StringTable.Get("str_dispatch_room_extra_reward"),
            isNew = false,
            isMax = isMax,
            isBook = false,
            isFuniture = false,
            isExtraReward = true,
            maxCount = extraMaxCount
        }
        ---@type UIDispatchRewardItem
        local item = rewardList[#rewards + 1]
        item:Refresh(
            rewardInfo,
            function()
                self:_RewardItemOnClick(rewardInfo, item:GetGameObject(), false)
            end,
            isPlayAnim
        )
        self._extraRewardItem = item
    end
    --书籍或家具
    if #bookOrFuniture > 0 then
        local itemId = bookOrFuniture[1].id
        local itemCfgs = Cfg.cfg_item {ID = itemId}
        local isBook = false
        local isFuniture = false
        local isNew = self:_GetRewardItemRedPointStatus()
        local des = ""
        --概率
        local odds = self._taskCfg.Odds
        --星灵
        local assignPetId = self._taskCfg.AssignPetId
        --1表示或，2表示与
        local assignPetType = self._taskCfg.AssignPetType
        if odds >= 1 then
            des = StringTable.Get("str_dispatch_room_must")
        else
            if assignPetId == nil or table.count(assignPetId) <= 0 then
                des = StringTable.Get("str_dispatch_room_rate")
            else
                if assignPetType == 1 then --1表示或
                    des = StringTable.Get("str_dispatch_room_rate")
                    for _, petid in pairs(assignPetId) do
                        for _, v in pairs(self._dispatchPets) do
                            ---@type Pet
                            local pet = v
                            if pet:GetTemplateID() == petid then
                                des = StringTable.Get("str_dispatch_room_must")
                                break
                            end
                        end
                    end
                elseif assignPetType == 2 then --2表示与
                    local findCount = 0
                    for _, petid in pairs(assignPetId) do
                        for _, v in pairs(self._dispatchPets) do
                            ---@type Pet
                            local pet = v
                            if pet:GetTemplateID() == petid then
                                findCount = findCount + 1
                                break
                            end
                        end
                    end
                    if findCount >= table.count(assignPetId) then
                        des = StringTable.Get("str_dispatch_room_must")
                    else
                        des = StringTable.Get("str_dispatch_room_rate")
                    end
                end
            end
        end
        if itemCfgs then
            local itemCfg = itemCfgs[1]
            if itemCfg.ItemSubType == ItemSubType.ItemSubType_Furniture then
                isFuniture = true
            end
            if itemCfg.ItemSubType == ItemSubType.ItemSubType_Book then
                isBook = true
            end
        end
        local rewardInfo = {
            id = bookOrFuniture[1].id,
            count = 1,
            des = des,
            isNew = isNew,
            isMax = false,
            isBook = isBook,
            isFuniture = isFuniture,
            isExtraReward = false,
            maxCount = 1
        }
        ---@type UIDispatchRewardItem
        local item = rewardList[#rewards + #extraRewards + 1]
        item:Refresh(
            rewardInfo,
            function()
                self:_RewardItemOnClick(rewardInfo, item:GetGameObject(), true)
                self:_SetRewardItemRedPointStatus()
            end,
            false
        )
    end
end

function UIDispatchDetailItem:_RewardItemOnClick(rewardInfo, go, isSpecialDes)
    local des = nil
    if isSpecialDes then
        local desKey = self._taskCfg.AwardDes
        des = StringTable.Get(desKey)
        local assignPetIds = self._taskCfg.AssignPetId
        if assignPetIds then
            local count = #assignPetIds
            if count == 1 then
                local petNameStr = StringTable.Get(Cfg.cfg_pet[assignPetIds[1]].Name)
                des = StringTable.Get(desKey, petNameStr)
            elseif count == 2 then
                local petNameStr1 = StringTable.Get(Cfg.cfg_pet[assignPetIds[1]].Name)
                local petNameStr2 = StringTable.Get(Cfg.cfg_pet[assignPetIds[2]].Name)
                des = StringTable.Get(desKey, petNameStr1, petNameStr2)
            elseif count == 3 then
                local petNameStr1 = StringTable.Get(Cfg.cfg_pet[assignPetIds[1]].Name)
                local petNameStr2 = StringTable.Get(Cfg.cfg_pet[assignPetIds[2]].Name)
                local petNameStr3 = StringTable.Get(Cfg.cfg_pet[assignPetIds[3]].Name)
                des = StringTable.Get(desKey, petNameStr1, petNameStr2, petNameStr3)
            end
        end
    end
    self._detailController:ShowTips(rewardInfo.id, go.transform.position, des)
end

function UIDispatchDetailItem:_GetRewardItemRedPointStatus()
    local key = self:_GetRedPointKey()
    if not UnityEngine.PlayerPrefs.HasKey(key) then
        return true
    end
    local value = UnityEngine.PlayerPrefs.GetInt(key)
    if value == 1 then
        return false
    end
    return true
end

function UIDispatchDetailItem:_SetRewardItemRedPointStatus()
    local key = self:_GetRedPointKey()
    UnityEngine.PlayerPrefs.SetInt(key, 1)
end

function UIDispatchDetailItem:_GetRedPointKey()
    if self._redPointKey then
        return self._redPointKey
    end
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = "DISPATCH_TASK_REWARD_ITEM_RED_POINT" .. pstId
    self._redPointKey = key .. self._pointIndex .. self._siteInfo.taskId
    return self._redPointKey
end

function UIDispatchDetailItem:_RefreshPetInfo()
    self._dispatchPets = self._detailController:GetDispatchPets(self._pointIndex)
    self._petLoader:SpawnObjects("UIDispatchPetIconItem", self._roomData:GetTeamMemberMaxNum())
    self._petItemList = self._petLoader:GetAllSpawnList()
    for i = 1, #self._petItemList do
        ---@type UIDispatchPetIconItem
        local petItem = self._petItemList[i]
        petItem:Refresh(i, self)
    end
    self:_RefreshReward(false)
end

function UIDispatchDetailItem:_RefreshTaskStatusInfo()
    ---@type DispatchTaskStateType
    local state = self._siteInfo.state
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
    if state == DispatchTaskStateType.DTST_New then --新的
        self._taskTimePanel:SetActive(true)
        self._giveUpBtnGo:SetActive(false)
        self._taskTimeLabel.text =
            StringTable.Get("str_dispatch_room_task_time_long", self:_GetTimeStr(self._taskCfg.CompleteTime))
        local dispatchCount = self._roomData:GetDispatchCount()
        local roomCfg = self._roomData:GetRoomConfig()
        local dispatchTeamCount = self._roomData:GetDispatchTeamCount()
        if roomCfg.TeamMax <= dispatchTeamCount then --队伍数量达到最大
            self._autoSelectBtnGo:SetActive(false)
            self._dispatchtBtnGo:SetActive(false)
            self._tipsGo:SetActive(true)
            self._tipsLabel.text =
                StringTable.Get(
                "str_dispatch_room_dispatch_count_together",
                dispatchTeamCount .. "/" .. roomCfg.TeamMax
            )
        elseif dispatchCount <= 0 then --派遣次数用光
            self._autoSelectBtnGo:SetActive(false)
            self._dispatchtBtnGo:SetActive(false)
            self._tipsGo:SetActive(true)
            self:_ShowRecoverTime()
        else
            self._autoSelectBtnGo:SetActive(true)
            self._dispatchtBtnGo:SetActive(true)
            self._tipsGo:SetActive(false)
        end
        return
    elseif state == DispatchTaskStateType.DTST_Doing then --进行中
        self._giveUpBtnGo:SetActive(true)
        self._tipsGo:SetActive(false)
        self._autoSelectBtnGo:SetActive(false)
        self._dispatchtBtnGo:SetActive(false)
        local str =
            StringTable.Get("str_dispatch_room_task_detail_complete", self:_GetRemainTimeStr(self._siteInfo.endTime))
        self._taskTimeLabel.text = str
        if self._timerHandler then
            GameGlobal.Timer():CancelEvent(self._timerHandler)
            self._timerHandler = nil
        end
        self._timerHandler =
            GameGlobal.Timer():AddEventTimes(
            50,
            TimerTriggerCount.Infinite,
            function()
                local str =
                    StringTable.Get(
                    "str_dispatch_room_task_detail_complete",
                    self:_GetRemainTimeStr(self._siteInfo.endTime)
                )
                self._taskTimeLabel.text = str
                local nowTime = self._timeModule:GetServerTime() / 1000
                local seconds = self._siteInfo.endTime - nowTime
                if seconds <= 0 then
                    if self._timerHandler then
                        GameGlobal.Timer():CancelEvent(self._timerHandler)
                        self._timerHandler = nil
                    end
                    --发送消息告诉服务器完成事件了
                    self:ReqDataAndRefreshRoomMsg()
                end
            end
        )
        return
    end
    self._detailController:Close()
end

function UIDispatchDetailItem:_GetRemainTimeStr(endTime)
    local nowTime = self._timeModule:GetServerTime() / 1000
    local seconds = math.floor(endTime - nowTime)
    if seconds < 0 then
        seconds = 0
    end
    local hour = math.floor(seconds / 3600)
    seconds = seconds - hour * 3600
    local timeStr = ""
    if hour > 0 then
        timeStr = StringTable.Get("str_dispatch_room_task_detail_hour", hour)
    end
    local min = 1
    if seconds == 0 and hour > 0 then
        min = 0
    end
    if seconds > 60 then
        min = math.floor(seconds / 60)
    end
    if min > 0 then
        timeStr = timeStr .. StringTable.Get("str_dispatch_room_task_detail_min", min)
    end
    return timeStr
end

function UIDispatchDetailItem:_ShowRecoverTime()
    local dispatchCount = self._roomData:GetDispatchCount()
    if dispatchCount > 0 then
        if self._timer then
            GameGlobal.Timer():CancelEvent(self._timer)
            self._timer = nil
        end
        self:ReqDataAndRefreshRoomMsg()
        return
    end
    local time = self._roomData:GetSurplusSecond()

    if time == -1 then
        self._tipsLabel.text = StringTable.Get("str_dispatch_room_next_dispatch_recover", "--:--:--")
    elseif time >= 0 then
        if self._timer then
            GameGlobal.Timer():CancelEvent(self._timer)
            self._timer = nil
        end
        if time == 0 then
            self._tipsLabel.text = StringTable.Get("str_dispatch_room_next_dispatch_recover", "00:00:00")
        else
            self._tipsLabel.text =
                StringTable.Get(
                "str_dispatch_room_next_dispatch_recover",
                HelperProxy:GetInstance():FormatTime(math.floor(time))
            )
        end
        self._timer =
            GameGlobal.Timer():AddEventTimes(
            1000,
            TimerTriggerCount.Infinite,
            function()
                local dispatchCount = self._roomData:GetDispatchCount()

                local _text = nil
                local time = self._roomData:GetSurplusSecond()
                if time == -1 then
                    _text = "--:--:--"
                elseif time == 0 or dispatchCount > 0 then
                    if self._timer then
                        GameGlobal.Timer():CancelEvent(self._timer)
                        self._timer = nil
                    end
                    _text = "00:00:00"
                    --时间到，请求服务器消息
                    self:ReqDataAndRefreshRoomMsg()
                else
                    _text = HelperProxy:GetInstance():FormatTime(math.floor(time))
                end
                self._tipsLabel.text = StringTable.Get("str_dispatch_room_next_dispatch_recover", _text)
            end
        )
    end
end

function UIDispatchDetailItem:ReqDataAndRefreshRoomMsg()
    GameGlobal.TaskManager():StartTask(self._ReqData, self)
end

function UIDispatchDetailItem:_ReqData(TT)
    self:Lock("UIDispatchDetailItem_ReqData")
    local ack = self._aircraftModule:AircraftUpdate(TT)
    self._aircraftModule:HandleCEventDispatchSite(TT)
    if ack:GetSucc() then
        local siteInfo = self._roomData:GetSiteInfo(self._pointIndex)
        self._siteInfo = siteInfo
        self:_RefreshTaskStatusInfo()
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateDispatchTaskSiteInfo)
    else
        ToastManager.ShowToast(self._aircraftModule:GetErrorMsg(ack:GetResult()))
    end
    self:UnLock("UIDispatchDetailItem_ReqData")
end

function UIDispatchDetailItem:_GetTimeStr(seconds)
    local hour = math.floor(seconds / 3600)
    seconds = seconds - hour * 3600
    local timeStr = ""
    if hour > 0 then
        timeStr = StringTable.Get("str_dispatch_room_task_detail_hour", hour)
    end
    local min = 1
    if seconds == 0 and hour > 0 then
        min = 0
    end
    if seconds > 60 then
        min = math.floor(seconds / 60)
    end
    if min > 0 then
        timeStr = timeStr .. StringTable.Get("str_dispatch_room_task_detail_min", min)
    end
    return timeStr
end

function UIDispatchDetailItem:GetDispatchPetByIndex(index)
    return self._dispatchPets[index]
end

function UIDispatchDetailItem:GetDispatchPetList()
    return self._dispatchPets
end

---@param pet Pet
function UIDispatchDetailItem:UpdatePetInfo(index, pet)
    self._dispatchPets[index] = pet
    self._petItemList[index]:Refresh(index, self)
    self:_RefreshReward(true)
end

function UIDispatchDetailItem:GetExcludePets()
    return self._detailController:GetExcludePets()
end

function UIDispatchDetailItem:SuggestBtnOnClick(go)
    self._detailController:ShowSuggestDesPanel()
end

function UIDispatchDetailItem:AutoSelectBtnOnClick(go)
    self:_AutoSelectPets()
end

function UIDispatchDetailItem:DispatchtBtnOnClick(go)
    local pets = self._detailController:GetDispatchPets(self._pointIndex)
    local petCount = table.count(pets)
    if petCount < self._roomData:GetTeamMemberMaxNum() then
        ToastManager.ShowToast(
            StringTable.Get("str_dispatch_room_team_person_not_enough", self._roomData:GetTeamMemberMaxNum())
        )
        return
    end
    GameGlobal.TaskManager():StartTask(self._AcceptTask, self)
end

function UIDispatchDetailItem:_AcceptTask(TT)
    self:Lock("UIDispatchDetailItem_AcceptTask")
    local pets = self._detailController:GetDispatchPets(self._pointIndex)
    local pstIds = {}
    local templateIds = {}
    for i = 1, #pets do
        ---@type Pet
        local pet = pets[i]
        pstIds[#pstIds + 1] = pet:GetPstID()
        templateIds[#templateIds + 1] = pet:GetTemplateID()
    end
    local res, replay = self._aircraftModule:HandleCEventDispatchAcceptTask(TT, self._pointIndex, pstIds)
    if res:GetSucc() then
        self._aircraftModule:HandleCEventDispatchSite(TT)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateDispatchTaskSiteInfo)
        self:DeletePets(templateIds)
        self._detailController:Close()
        ToastManager.ShowToast(StringTable.Get("str_dispatch_room_task_start"))
    else
        ToastManager.ShowToast(self._aircraftModule:GetErrorMsg(res:GetResult()))
    end
    self:UnLock("UIDispatchDetailItem_AcceptTask")
end

function UIDispatchDetailItem:GiveUpBtnOnClick(go)
    self:ShowDialog("UIDispatchGiveUpController", self)
end

function UIDispatchDetailItem:DeletePets(templateIds)
    if not templateIds then
        return
    end
    for i = 1, #templateIds do
        -- GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftDeletePet, templateIds[i])
    end
end

function UIDispatchDetailItem:_getAutoPet(includeAssignPet)
    local maxCount = self._roomData:GetTeamMemberMaxNum()
    local targetScore = self._taskCfg.Score
    --指定光灵
    local assignPet = nil
    if self._taskCfg.Type == 3 then
        if self._taskCfg.AssignPetId then
            assignPet = self._taskCfg.AssignPetId[1] --指定星灵只会有1个，多了不处理
        end
    end
    local pets = self:GetCanDispatchPetList(self:GetExcludePets(), nil)
    local count = #pets
    local index = 1
    while index <= count do
        local pet = pets[index]
        if self:GetWorkingSpace(pet) and (pet:GetTemplateID() ~= assignPet or not includeAssignPet) then
            --只要是工作星灵都不能自动派遣,除非这个星灵是指定星灵
            table.remove(pets, index)
            count = count - 1
        else
            index = index + 1
        end
    end

    local targetPets = {}
    local index = 0
    for i = 1, maxCount do
        if pets[i] == nil then
            break
        end
        local score = self._roomData:GetScore({pets[i]}, self._siteInfo.taskId)
        targetScore = targetScore - score
        targetPets[i] = pets[i]
        index = i
        if targetScore <= 0 then
            break
        end
    end
    if index < maxCount then
        local tmpPets = {}
        local count = maxCount - index
        for i = 0, count - 1 do
            local petIndex = #pets - i
            if petIndex <= index then
                break
            end
            local pet = pets[petIndex]
            if not pet then
                break
            end
            table.insert(tmpPets, 1, pet)
        end
        for i = 1, count do
            local pet = tmpPets[i]
            if not pet then
                break
            end
            targetPets[index + i] = pet
        end
    end

    --第一个星灵是否为指定星灵(如果有指定星灵一定排在第一位)
    local _1stIsAssignPet = false
    if #targetPets > 0 then
        _1stIsAssignPet = targetPets[1]:GetTemplateID() == assignPet
    end
    return targetPets, _1stIsAssignPet
end

function UIDispatchDetailItem:_AutoSelectPets()
    local pets, isAssignPet = self:_getAutoPet(true)

    local tip = nil
    -- if isAssignPet then
    --     ---@type Pet
    --     local pet = pets[1]
    --     local workingSpace = self:GetWorkingSpace(pets[1])
    --     if workingSpace then
    --         local petName = StringTable.Get(pet:GetPetName())
    --         local furName = StringTable.Get(Cfg.cfg_item[self._taskCfg.ItemId].Name)
    --         local roomName = StringTable.Get(self._aircraftModule:GetRoom(workingSpace):GetRoomName())
    --         tip = StringTable.Get("str_aircraft_dispatch_tip2", petName, furName, roomName)
    --     end
    -- end

    local refresh = function(ps)
        for i, pet in ipairs(ps) do
            self._dispatchPets[i] = ps[i]
        end
        self:_RefreshPetInfo()
        self:_RefreshReward(true)
    end

    if tip then
        PopupManager.Alert(
            "UICommonMessageBox",
            PopupPriority.Normal,
            PopupMsgBoxType.OkCancel, --1
            "",
            tip,
            function()
                refresh(pets)
            end,
            nil,
            function(param)
                --取消
                refresh(self:_getAutoPet(false))
            end,
            nil,
            nil,
            nil,
            StringTable.Get("str_story_btn_skip")
        )
        return
    end

    refresh(pets)
end

function UIDispatchDetailItem:GetCanDispatchPetList(exculdePets, selectedPet)
    local pets = self._roomData:GetDispatchPetList()
    --去除已经选择了的星灵
    if exculdePets then
        for _, v in pairs(exculdePets) do
            ---@type Pet
            local pet = v
            if selectedPet == nil or pet:GetPstID() ~= selectedPet:GetPstID() then
                for k, v1 in pairs(pets) do
                    if pet:GetPstID() == v1:GetPstID() then
                        table.remove(pets, k)
                        break
                    end
                end
            end
        end
    end
    return self:_SortPets(pets, selectedPet)
end

---@param pets Pet[]
---@param selectedPet Pet
function UIDispatchDetailItem:_SortPets(pets, selectedPet)
    if not pets then
        return {}
    end
    local sortFuc = function(a, b)
        local aIsWorking = self:GetWorkingSpace(a)
        local bIsWorking = self:GetWorkingSpace(b)
        if aIsWorking ~= bIsWorking then
            return aIsWorking == nil
        end
        local aScore = self._roomData:GetScore({a}, self._siteInfo.taskId)
        local bScore = self._roomData:GetScore({b}, self._siteInfo.taskId)
        if aScore ~= bScore then
            return aScore > bScore
        end
        local aIsSuggestPet = self:IsSuggestPet(a)
        local bIsSuggestPet = self:IsSuggestPet(b)
        local aSuggestScore = 0
        local bSuggestScore = 0
        if aIsSuggestPet then
            aSuggestScore = 1
        end
        if bIsSuggestPet then
            bSuggestScore = 1
        end
        if aSuggestScore ~= bSuggestScore then
            return aSuggestScore > bSuggestScore
        end
        return a:GetPstID() > b:GetPstID()
    end
    table.sort(pets, sortFuc)
    --星灵 1表示或，2表示与
    local assignPetId, assignPetType = self:GetSuggestInfo()
    if assignPetId then
        if assignPetType == 1 then --1表示或
            --如果此任务设置了指定光灵“谁或谁”，则在玩家拥有的指定光灵中，选择“推荐分+觉醒分”最高的那个显示在列表的最前面。
            local petResult = {}
            for _, petid in pairs(assignPetId) do
                for _, v in pairs(pets) do
                    ---@type Pet
                    local pet = v
                    if pet:GetTemplateID() == petid then
                        petResult[#petResult + 1] = pet
                        break
                    end
                end
            end
            if #petResult > 0 then
                table.sort(petResult, sortFuc)
                ---@type Pet
                local pet = petResult[1]
                for pos, v in pairs(pets) do
                    if pet:GetTemplateID() == v:GetTemplateID() then
                        table.remove(pets, pos)
                        break
                    end
                end
                table.insert(pets, 1, pet)
            end
        elseif assignPetType == 2 then --2表示与
            --如果此任务设置了指定光灵“谁和谁”，如果玩家同时拥有这些光灵，则全部显示在列表的最前面，如果没有同时拥有，则不处理。
            local petResult = {}
            for _, petid in pairs(assignPetId) do
                for _, v in pairs(pets) do
                    ---@type Pet
                    local pet = v
                    if pet:GetTemplateID() == petid then
                        petResult[#petResult + 1] = pet
                        break
                    end
                end
            end
            if #petResult >= table.count(assignPetId) then
                table.sort(petResult, sortFuc)
                for i = 1, #petResult do
                    ---@type Pet
                    local pet = petResult[i]
                    for pos, v in pairs(pets) do
                        if pet:GetTemplateID() == v:GetTemplateID() then
                            table.remove(pets, pos)
                            break
                        end
                    end
                    table.insert(pets, 1, pet)
                end
            end
        end
    end
    if selectedPet then
        for k, v1 in pairs(pets) do
            if selectedPet:GetPstID() == v1:GetPstID() then
                table.remove(pets, k)
                break
            end
        end
        table.insert(pets, 1, selectedPet)
    end
    return pets
end

function UIDispatchDetailItem:GetExtraRewardItem()
    return self._extraRewardItem
end
