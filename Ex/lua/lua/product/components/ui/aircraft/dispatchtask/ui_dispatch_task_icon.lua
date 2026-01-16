_class("UIDispatchTaskIcon", UICustomWidget)
---@class UIDispatchTaskIcon : UICustomWidget
UIDispatchTaskIcon = UIDispatchTaskIcon

function UIDispatchTaskIcon:OnShow(uiParam)
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
    self._uiHeartItemAtlas = self:GetAsset("UIHeartItem.spriteatlas", LoadType.SpriteAtlas)
    self.atlasProperty = self:GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)
    self._suggestIcon1Img = self:GetUIComponent("RawImageLoader", "SuggestIcon1")
    self._suggestIcon1Go = self:GetGameObject("SuggestIcon1")
    self._profIcon1Img = self:GetUIComponent("Image", "ProfIcon1")
    self._profIcon1Go = self:GetGameObject("ProfIcon1")
    self._elementIconGo = self:GetGameObject("ElementIcon")
    self._elementIconImg = self:GetUIComponent("Image", "ElementIcon")
    self._profIcon2Img = self:GetUIComponent("Image", "ProfIcon2")
    self._profIcon2Go = self:GetGameObject("ProfIcon2")
    self._emptyPanel = self:GetGameObject("Empty")
    self._unStartPanel = self:GetGameObject("UnStart")
    self._rewardIconImg = self:GetUIComponent("RawImageLoader", "RewardIcon")
    self._unStartStarPanelLoader = self:GetUIComponent("UISelectObjectPath", "UnStartStarPanel")
    self._runningPanel = self:GetGameObject("Running")
    self._runningPetIconImg = self:GetUIComponent("RawImageLoader", "RunningPetIcon")
    self._hourLabel = self:GetUIComponent("UILocalizationText", "Hour")
    self._minLabel = self:GetUIComponent("UILocalizationText", "Min")
    self._runningStarPanelLoader = self:GetUIComponent("UISelectObjectPath", "RunningStarPanel")
    self._completePanel = self:GetGameObject("Complete")
    self._completePetIconImg = self:GetUIComponent("RawImageLoader", "CompletePetIcon")
    self._completeStarPanelLoader = self:GetUIComponent("UISelectObjectPath", "CompleteStarPanel")
    self._siteInfo = nil
    self._timerHandler = nil
    ---@type AircraftModule
    self._aircraftModule = GameGlobal.GetModule(AircraftModule)
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)
    ---@type PetModule
    self._petModule = GameGlobal.GetModule(PetModule)
end

function UIDispatchTaskIcon:OnHide()
    self._uiHeartItemAtlas = nil
    self.atlasProperty = nil
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
end

---@param mapController UIDispatchMapController
function UIDispatchTaskIcon:Refresh(pointIndex, mapController)
    self._mapController = mapController
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
    ---@type AircraftDispatchRoom
    local roomData = self._aircraftModule:GetRoomByRoomType(AirRoomType.DispatchRoom)
    local siteInfo = roomData:GetSiteInfo(pointIndex)
    self._siteInfo = siteInfo
    self._pointIndex = pointIndex
    if not siteInfo then
        self:_TaskIsEmpty()
        return
    end
    ---@type DispatchTaskStateType
    local state = siteInfo.state
    if state == DispatchTaskStateType.DTST_Invalid or state == DispatchTaskStateType.DTST_End then
        self:_TaskIsEmpty()
        return
    end
    self:GetGameObject():SetActive(true)
    local taskId = siteInfo.taskId
    local taskCfg = Cfg.cfg_aircraft_dispatch_task {ID = taskId}
    self._taskStar = taskCfg[1].Star
    self._unStartPanel:SetActive(false)
    self._runningPanel:SetActive(false)
    self._completePanel:SetActive(false)
    self._emptyPanel:SetActive(false)
    if state == DispatchTaskStateType.DTST_New then --新的
        --未开始的任务，显示奖励图标。一个任务会有多个奖励，图标按以下优先度显示：光尘>家具>书籍>基础奖励配置的第一种道具。
        self._unStartPanel:SetActive(true)
        self._unStartStarPanelLoader:SpawnObjects("UIDispatchTaskStar", self._taskStar)
        local itemId = self:_GetShowItemId(siteInfo.awardId, taskId)
        local itemCfgs = Cfg.cfg_item {ID = itemId}
        local itemCfg = itemCfgs[1]
        self._rewardIconImg:LoadImage(itemCfg.Icon)
        self:_RefreshSuggestInfo(taskCfg[1])
    elseif state == DispatchTaskStateType.DTST_Doing then --进行中
        --正在进行的任务，显示派遣队伍中的第一个光灵，和完成任务的剩余时间“小时：分钟”，最后一分钟内显示“00:01”。
        self._runningPanel:SetActive(true)
        self._runningStarPanelLoader:SpawnObjects("UIDispatchTaskStar", self._taskStar)
        local teamMembers = siteInfo.teamMember
        ---@type Pet
        local pet = self._petModule:GetPet(teamMembers[1])
        self._runningPetIconImg:LoadImage(
            HelperProxy:GetInstance():GetPetHead(pet:GetTemplateID(), pet:GetPetGrade(),pet:GetSkinId(),PetSkinEffectPath.HEAD_ICON_DISPATCH)
        )
        self._minLabel.text = self:_GetRemainTimeStr(siteInfo.endTime)
        self._timerHandler =
            GameGlobal.Timer():AddEventTimes(
            1000,
            TimerTriggerCount.Infinite,
            function()
                self._minLabel.text = self:_GetRemainTimeStr(self._siteInfo.endTime)
                local nowTime = self._timeModule:GetServerTime() / 1000
                local seconds = self._siteInfo.endTime - nowTime
                if seconds <= 0 then
                    if self._timerHandler then
                        GameGlobal.Timer():CancelEvent(self._timerHandler)
                        self._timerHandler = nil
                    end
                    --发送消息告诉服务器完成事件了
                    self:_ReqData()
                end
            end
        )
    elseif state == DispatchTaskStateType.DTST_Complete then --完成
        self._completePanel:SetActive(true)
        self._completeStarPanelLoader:SpawnObjects("UIDispatchTaskStar", self._taskStar)
        local teamMembers = siteInfo.teamMember
        ---@type Pet
        local pet = self._petModule:GetPet(teamMembers[1])
        self._completePetIconImg:LoadImage(
            HelperProxy:GetInstance():GetPetHead(pet:GetTemplateID(), pet:GetPetGrade(),pet:GetSkinId(),PetSkinEffectPath.HEAD_ICON_DISPATCH)
        )
    end
end

function UIDispatchTaskIcon:_RefreshSuggestInfo(taskCfg)
    --显示顺序从左到右为：势力 > 职业 > 属性。
    local extraForce = taskCfg.ExtraForce
    local extraElement = taskCfg.ExtraElement
    local extraJop = taskCfg.ExtraJop
    --第一个推荐图标
    if extraForce and extraForce > 0 then --势力
        self._suggestIcon1Go:SetActive(true)
        self._profIcon1Go:SetActive(false)
        local tagCfg = Cfg.cfg_pet_tags[extraForce]
        self._suggestIcon1Img:LoadImage(tagCfg.Icon)
    elseif extraJop and extraJop > 0 then --职业
        self._suggestIcon1Go:SetActive(false)
        self._profIcon1Go:SetActive(true)
        self._profIcon1Img.sprite = self._uiHeartItemAtlas:GetSprite(self._prof2Img[extraJop])
    end
    --第二个推荐图标
    if extraElement and extraElement > 0 then --属性
        self._elementIconGo:SetActive(true)
        self._profIcon2Go:SetActive(false)
        self._elementIconImg.sprite =
            self.atlasProperty:GetSprite(
            UIPropertyHelper:GetInstance():GetColorBlindSprite(self.ElementSpriteName[extraElement])
        )
    elseif extraJop and extraJop > 0 then --职业
        self._elementIconGo:SetActive(false)
        self._profIcon2Go:SetActive(true)
        self._profIcon2Img.sprite = self._uiHeartItemAtlas:GetSprite(self._prof2Img[extraJop])
    end
end

function UIDispatchTaskIcon:_GetRemainTimeStr(endTime)
    local nowTime = self._timeModule:GetServerTime() / 1000
    local seconds = math.floor(endTime - nowTime)
    if seconds < 0 then
        seconds = 0
    end
    --时
    local hour = math.floor(seconds / 3600)
    seconds = seconds - hour * 3600
    local hourStr = hour
    if hour < 10 then
        hourStr = "0" .. hour
    end
    --分
    local min = math.floor(seconds / 60)
    seconds = seconds - min * 60
    local minStr = min
    if min < 10 then
        minStr = "0" .. min
    end
    --秒
    local secondStr = seconds
    if hour == 0 and min == 0 and seconds <= 0 then
        seconds = 1
    end
    if seconds < 10 then
        secondStr = "0" .. seconds
    end
 
    return hourStr .. ":" .. minStr .. ":" .. secondStr
end
function UIDispatchTaskIcon:_ReqData()
    GameGlobal.TaskManager():StartTask(self._ReqDataCoro, self)
end

function UIDispatchTaskIcon:_ReqDataCoro(TT)
    self:Lock("UIDispatchTaskIcon_ReqData")
    local ack = self._aircraftModule:HandleCEventDispatchSite(TT)
    if ack:GetSucc() then
        self._mapController:RefreshTask()
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateDispatchTaskSiteInfo)
    else
        ToastManager.ShowToast(self._aircraftModule:GetErrorMsg(ack:GetResult()))
    end
    self:UnLock("UIDispatchTaskIcon_ReqData")
end

function UIDispatchTaskIcon:_GetShowItemId(rewardId, taskId)
    ---@type AircraftDispatchRoom
    local roomData = self._aircraftModule:GetRoomByRoomType(AirRoomType.DispatchRoom)
    local baseRewards, extraRewards, bookOrFuniture = roomData:GetAward(rewardId, taskId)

    local rewards = {}
    if baseRewards then
        for i = 1, #baseRewards do
            rewards[#rewards + 1] = baseRewards[i]
        end
    end
    if extraRewards then
        for i = 1, #extraRewards do
            rewards[#rewards + 1] = extraRewards[i]
        end
    end
    if bookOrFuniture then
        for i = 1, #bookOrFuniture do
            rewards[#rewards + 1] = bookOrFuniture[i]
        end
    end
    --去掉光珀
    for i = 1, #rewards do
        local itemId = rewards[i].id
        if itemId == RoleAssetID.RoleAssetGlow then
            table.remove(rewards, i)
            break
        end
    end
    local showItemid = nil
    -- {id = RoleAssetID.RoleAssetGold},
    local sortTypes = {
        -- {id = RoleAssetID.RoleAssetGlow},
        {type = ItemSubType.ItemSubType_Furniture},
        {type = ItemSubType.ItemSubType_Book}
    }
    for i = 1, #sortTypes do
        local sortType = sortTypes[i]
        for i = 1, #rewards do
            local itemId = rewards[i].id
            if sortType.id and itemId == sortType.id then
                showItemid = itemId
                break
            end
            if sortType.type then
                local itemCfgs = Cfg.cfg_item {ID = itemId}
                if itemCfgs then
                    local itemCfg = itemCfgs[1]
                    if itemCfg.ItemSubType == sortType.type then
                        showItemid = itemId
                        break
                    end
                end
            end
        end
        if showItemid then
            break
        end
    end
    if not showItemid then
        return rewards[1].id
    end
    return showItemid
end

function UIDispatchTaskIcon:_TaskIsEmpty()
    self:GetGameObject():SetActive(true)
    self._unStartPanel:SetActive(false)
    self._runningPanel:SetActive(false)
    self._completePanel:SetActive(false)
    self._emptyPanel:SetActive(true)
end

function UIDispatchTaskIcon:TaskBtnOnClick(go)
    if self._siteInfo.state == DispatchTaskStateType.DTST_Complete then --完成
        GameGlobal.TaskManager():StartTask(self._GetReward, self)
    elseif self._siteInfo.state == DispatchTaskStateType.DTST_New or self._siteInfo.state == DispatchTaskStateType.DTST_Doing then
        self:ShowDialog("UIDispatchDetailController", self._pointIndex)
    else

        ---@type AircraftDispatchRoom
        local roomData = self._aircraftModule:GetRoomByRoomType(AirRoomType.DispatchRoom)
        local seconds = roomData:GetDispatchTaskRefreshRemainTime(self._pointIndex)
        local tips = self:GetRefreshTaskTimeStr(seconds)
        if tips then
            ToastManager.ShowToast(tips)
        end
    end
end

function UIDispatchTaskIcon:GetRefreshTaskTimeStr(seconds)
    if seconds <= 0 then
        GameGlobal.TaskManager():StartTask(self.ReqTaskData, self)
        -- return StringTable.Get("str_dispatch_room_task_refresh_tips")
        return nil
    end
    local hour = math.floor(seconds / 3600)
    seconds = seconds - hour * 3600
    local min = math.floor(seconds / 60)
    seconds = seconds - min * 60

    local timeStr = ""
    if seconds > 0 then
        timeStr = StringTable.Get("str_dispatch_room_task_refresh_time_second", seconds)
    end
    if min > 0 then
        timeStr = StringTable.Get("str_dispatch_room_task_refresh_time_min", min) .. timeStr
    end
    if hour > 0 then
        timeStr = StringTable.Get("str_dispatch_room_task_refresh_time_hour", hour) .. timeStr
    end

    return StringTable.Get("str_dispatch_room_task_refresh_time_title", timeStr)
end

function UIDispatchTaskIcon:ReqTaskData(TT)
    self:Lock("UIDispatchTaskIcon_ReqTaskData")
    local ack = self._aircraftModule:AircraftUpdate(TT)
    self._aircraftModule:HandleCEventDispatchSite(TT)
    if ack:GetSucc() then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateDispatchTaskSiteInfo)
    else
        ToastManager.ShowToast(self._aircraftModule:GetErrorMsg(ack:GetResult()))
    end
    self:UnLock("UIDispatchTaskIcon_ReqTaskData")
end

function UIDispatchTaskIcon:_GetReward(TT)
    self:Lock("UIDispatchTaskIcon_GetReward")
    local res, reply = self._aircraftModule:HandleCEventDispatchTaskAward(TT, self._pointIndex)
    if res:GetSucc() then
        ---@type AircraftDispatchRoom
        local roomData = self._aircraftModule:GetRoomByRoomType(AirRoomType.DispatchRoom)
        --奖励
        local rewards = {}
        local baseRewards, extraRewards, bookOrFuniture =
            roomData:GetAward(self._siteInfo.awardId, self._siteInfo.taskId)
        if baseRewards then
            for i = 1, #baseRewards do
                rewards[#rewards + 1] = {assetid = baseRewards[i].id, count = baseRewards[i].count}
            end
        end
        if extraRewards and #extraRewards > 0 then
            local extraMaxCount = extraRewards[1].count
            --根据星灵获取奖励数量
            local teamMembers = self._siteInfo.teamMember
            local pets = {}
            if teamMembers then
                for j = 1, #teamMembers do
                    local pet = self._petModule:GetPet(teamMembers[j])
                    pets[#pets + 1] = pet
                end
            end
            local currentSocre = roomData:GetScore(pets, self._siteInfo.taskId)
            local taskCfgs = Cfg.cfg_aircraft_dispatch_task {ID = self._siteInfo.taskId}
            local taskCfg = taskCfgs[1]
            local score = taskCfg.Score
            local percent = 1
            if score ~= 0 then
                percent = currentSocre / score
            end
            if percent > 1 then
                percent = 1
            end
            local countRes = math.floor(extraMaxCount * percent)
            rewards[#rewards + 1] = {
                assetid = extraRewards[1].id,
                count = countRes,
                des = StringTable.Get("str_dispatch_room_extra_reward")
            }
        end
        local isGetBookOrFuniture = reply.is_assign
        if isGetBookOrFuniture then
            if bookOrFuniture and #bookOrFuniture > 0 then
                local des = ""
                local itemCfgs = Cfg.cfg_item {ID = bookOrFuniture[1].id}
                if itemCfgs then
                    local itemCfg = itemCfgs[1]
                    if itemCfg.ItemSubType == ItemSubType.ItemSubType_Furniture then
                        des = StringTable.Get("str_dispatch_room_funiture")
                    end
                    if itemCfg.ItemSubType == ItemSubType.ItemSubType_Book then
                        des = StringTable.Get("str_dispatch_room_book")
                    end
                end
                rewards[#rewards + 1] = {assetid = bookOrFuniture[1].id, count = 1, des = des}
            end
        end
        self:_ShowRewards(rewards)
        self:_ReqData()
    else
        ToastManager.ShowToast(self._aircraftModule:GetErrorMsg(res:GetResult()))
    end
    self:PushPets()
    self:UnLock("UIDispatchTaskIcon_GetReward")
end

function UIDispatchTaskIcon:PushPets()
    local teamMembers = self._siteInfo.teamMember
    local templateIds = {}
    ---@type PetModule
    local petModule = GameGlobal.GetModule(PetModule)
    if teamMembers then
        for i = 1, #teamMembers do
            ---@type Pet
            local pet = petModule:GetPet(teamMembers[i])
            templateIds[#templateIds + 1] = pet:GetTemplateID()
        end
    end
    if not templateIds then
        return
    end
    for i = 1, #templateIds do
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftPushPetQueue, templateIds[i])
    end
end

function UIDispatchTaskIcon:_ShowRewards(rewards)
    local petIdList = {}
    local petModule = GameGlobal.GetModule(PetModule)
    for _, reward in pairs(rewards) do
        if petModule:IsPetID(reward.assetid) then
            table.insert(petIdList, reward)
        end
    end
    if table.count(petIdList) > 0 then
        self:ShowDialog(
            "UIPetObtain",
            petIdList,
            function()
                GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
                self:ShowDialog("UIGetItemController", rewards, nil, true)
            end
        )
        return
    end
    self:ShowDialog("UIGetItemController", rewards, nil, true)
end

function UIDispatchTaskIcon:GetTaskBtn()
    return self:GetGameObject("TaskBtn_Guide")
end

function UIDispatchTaskIcon:GetStarCount()
    return self._taskStar
end