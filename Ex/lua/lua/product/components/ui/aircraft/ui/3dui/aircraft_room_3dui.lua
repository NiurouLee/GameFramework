---@class AircraftRoom3DUI:Object
_class("AircraftRoom3DUI", Object)
AircraftRoom3DUI = AircraftRoom3DUI

function AircraftRoom3DUI:Constructor(resReq, roomGo)
    self._view = nil
    self._viewReq = resReq
    self._view = resReq.Obj
    --房间GameObject，从中获取场景内的ui，用于显示奖励数量
    self._roomGO = roomGo
    self._viewGO = resReq.Obj

    ---@type UIView
    self._uiViewCpt = resReq.Obj:GetComponent(typeof(UIView))
    self:InitWidgets()

    ---@type AirUIState
    self._state = AirUIState.SpaceNotOpen

    self._countDown = false
    self._refreshAward = false

    --当前是否在这个房间内
    self._inThisRoom = false

    --是否初始化过了奖励控件
    self._awardWidgetInited = false

    ---@type AircraftModule
    self._module = GameGlobal.GetModule(AircraftModule)

    self._awardFormat = "<color=#2ee5ff>%s</color><color=#b2b2b2>/%s</color>"

    self._canLvUpAnim = {[1] = "uieff_RoomLevelUp_Yellow", [2] = "uieff_RoomLevelUp_Green"}

    self.resReqs = {}
    local atlas = ResourceManager:GetInstance():SyncLoadAsset("UIAircraftMainUI.spriteatlas", LoadType.SpriteAtlas)
    self.levelUpSprite = atlas.Obj:GetSprite("wind_tongyong_icon13")
    self.normalLevelSprite = atlas.Obj:GetSprite("wind_tongyong_icon14")
    self.nameBgRestRoom = atlas.Obj:GetSprite("wind_tongyong_icon19")

    self.resReqs[#self.resReqs] = atlas
    self._inited = false
    self.UpdateBookRedPointStatusHandler = GameHelper:GetInstance():CreateCallback(self.UpdateBookRedPointStatus, self)
    GameGlobal.EventDispatcher():AddCallbackListener(
        GameEventType.UpdateBookRedPointStatus,
        self.UpdateBookRedPointStatusHandler
    )
end

function AircraftRoom3DUI:UpdateBookRedPointStatus()
    if self._roomData == nil then
        return
    end
    local roomType = self._roomData:GetRoomType()
    if roomType ~= AirRoomType.CoffeeRoom then
        return
    end
    if not self._roomGO then
        return
    end
    local newTran = self._roomGO.transform:GetChild(0):Find("UIAircraftBookTip/BookNew")
    if not newTran then
        return
    end
    ---@type ItemModule
    local itemModule = GameGlobal.GetModule(ItemModule)
    newTran.gameObject:SetActive(itemModule:HasNewBook())
end

function AircraftRoom3DUI:InitWidgets()
    self.stateGO = self:GetGameObject("State")
    self._animation = self:GetUIComponent("Animation", "anim")
    self.stateText = self:GetUIComponent("UILocalizationText", "stateText")
    self.timerText = self:GetUIComponent("UILocalizationText", "stateTime")

    self.canCleanGO = self:GetGameObject("Unclean")

    -- self.canBuildGO = self:GetGameObject("Unbuild")

    self.collectGO = self:GetGameObject("Collect")
    self.assetIcon = self:GetUIComponent("Image", "assetIcon")

    self.canCollectGo = self:GetGameObject("CanCollect")
    self.newTaskGo = self:GetGameObject("NewTask")

    self._hasPlotGo = self:GetGameObject("HasPlot")
    self._taskCanTriggerGo = self:GetGameObject("TaskCanTrigger")
    self._taskHasGetGo = self:GetGameObject("TaskHasGet")
    self._taskCanCompleteGo = self:GetGameObject("TaskCanComplete")
    self._taskStatusPanel = self:GetGameObject("TaskStatus")

    self.idleInfoGO = self:GetGameObject("IdleInfo")
    self.nameText = self:GetUIComponent("UILocalizationText", "NameText")

    self._lv_anim = self:GetUIComponent("Animation", "uieff_RoomLevelUp")
    self._lv_anim_go = self:GetGameObject("uieff_RoomLevelUp")
    self._arrowGo = self:GetGameObject("arrowGo")
    self._arrowGo:SetActive(false)
    self._arrow_01 = self._arrowGo.transform:GetChild(0).gameObject:GetComponent("RawImage")
    self._arrow_02 = self._arrowGo.transform:GetChild(1).gameObject:GetComponent("RawImage")
    self._arrow_03 = self._arrowGo.transform:GetChild(2).gameObject:GetComponent("RawImage")
    self.lvup = self:GetGameObject("lvup")

    self.canSettleGO = self:GetGameObject("CanSettle")
    self.levelTips = {
        self:GetGameObject("Level1Tip"),
        self:GetGameObject("Level2Tip"),
        self:GetGameObject("Level3Tip"),
        self:GetGameObject("Level4Tip"),
        self:GetGameObject("Level5Tip")
    }

    self.btnGuide = self:GetGameObject("btnguide")

    self.effectPlot = self:GetGameObject("Eff")

    self._unLockGO = self:GetGameObject("UnLock")
    self._unlockCondition = self:GetUIComponent("UILocalizationText", "Unlock_cond")
    self._selectAnim = self:GetUIComponent("Animation", "select")
    self._boxRoot = self:GetGameObject("Root")

    self._nameBg = self:GetUIComponent("Image", "nameBg")

    self._canvasGroup = self:GetUIComponent("CanvasGroup", "RoomUIBase")
    self._tacticTip = self:GetGameObject("TacticTip")
    self._tacticText = self:GetUIComponent("UILocalizationText", "tacticText")
end

function AircraftRoom3DUI:OnDestroy()
    if self._event then
        GameGlobal.Timer():CancelEvent(self._event)
        self._event = nil
    end

    if self._viewReq then
        self._viewReq:Dispose()
    end
    if self.timeEvent then
        GameGlobal.Timer():CancelEvent(self.timeEvent)
        self.timeEvent = nil
    end

    for _, req in ipairs(self.resReqs) do
        req:Dispose()
    end

    if self._animEvent then
        GameGlobal.Timer():CancelEvent(self._animEvent)
        self._animEvent = nil
    end

    self.awardGO = nil
    self.awardIcon = nil
    self.awardText = nil
    GameGlobal.EventDispatcher():RemoveCallbackListener(
        GameEventType.AircraftOnFireFlyChanged,
        self.fireflyChangeCallback
    )
    GameGlobal.EventDispatcher():RemoveCallbackListener(
        GameEventType.UpdateBookRedPointStatus,
        self.UpdateBookRedPointStatusHandler
    )

    if self._spaceOpenTimer then
        GameGlobal.Timer():CancelEvent(self._spaceOpenTimer)
        self._spaceOpenTimer = nil
    end
end

function AircraftRoom3DUI:Show(roomData, state, spaceID)
    self._spaceID = spaceID
    self:InitAward(roomData)
    self:InitDispatchTaskTipsUI(roomData)
    self._state = state

    self:Refresh(roomData, state)

    self.fireflyChangeCallback = GameHelper:GetInstance():CreateCallback(self.OnFireFlyChanged, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.AircraftOnFireFlyChanged, self.fireflyChangeCallback)
    self:UpdateBookRedPointStatus()
end

function AircraftRoom3DUI:InitDispatchTaskTipsUI(roomData)
    if roomData == nil then
        return
    end
    local roomType = roomData:GetRoomType()
    --特定的三种房间有奖励
    if roomType == AirRoomType.DispatchRoom then
        if self._roomGO.transform:GetChild(0) == nil then
            Log.exception("[Aircraft] 房间prefab加载失败，空间id：", roomData:SpaceId())
            return
        end
        self.newTaskGO = self._roomGO.transform:GetChild(0):Find("TaskTipsUI/NewTask").gameObject
        self.taskCompleteGO = self._roomGO.transform:GetChild(0):Find("TaskTipsUI/TaskComplete").gameObject
        self.taskTipsUI = self._roomGO.transform:GetChild(0):Find("TaskTipsUI").gameObject
        if not self._inited then
            self.taskTipsUI:SetActive(false)
            self._inited = true
        end
        self:RefreshDispatchTips()
    end
end

function AircraftRoom3DUI:RefreshDispatchTips()
    local tipsGo = self._roomGO.transform:GetChild(0):Find("UIAircraftDispatchTip").gameObject
    if not tipsGo then
        return
    end
    if not self._roomData then
        return
    end
    local uiView = tipsGo:GetComponent(typeof(UIView))
    local tipsLabel = uiView:GetUIComponent("UILocalizationText", "Tips")
    if self._roomData:HasCompleteTask() then
        tipsLabel.text = StringTable.Get("str_dispatch_room_click_tips2")
    else
        tipsLabel.text = StringTable.Get("str_dispatch_room_click_tips1")
    end
end

function AircraftRoom3DUI:Refresh(roomData, state)
    self._oldState = self._state
    self._state = state
    ---@type AircraftRoomBase
    self._roomData = roomData

    self:RefreshRoomUI()

    self:RefreshAwardUI()
    self:CheckAndStartTimer()

    self:RefreshPetTaskAndPlotUI()
    self:InitDispatchTaskTipsUI(roomData)
    self:UpdateBookRedPointStatus()

    self:RefreshCollider()
end

function AircraftRoom3DUI:RefreshCollider()
    local colliders = self._roomGO:GetComponents(typeof(UnityEngine.Collider))
    local normalCollider = colliders[0]
    local unlockCollider = colliders[1]
    if self._state == AirUIState.SpaceNotOpen then
        --未开放的空间用小的碰撞器
        normalCollider.enabled = false
        unlockCollider.enabled = true
    else
        normalCollider.enabled = true
        unlockCollider.enabled = false
    end
end

function AircraftRoom3DUI:CountDownTime()
    local time = 0
    if self._state == AirUIState.SpaceCleaning then
        --空间清理中，倒计时特殊处理
        return self._module:GetCleanSpaceRemainingTime(self._spaceID)
    else
        --为了保证客户端时间慢于服务器，此处向上取整
        time = math.ceil(self._roomData:BuildRemainTime())
    end
    return time
end

function AircraftRoom3DUI:RefreshPetTaskAndPlotUI()
    self:HidePetTaskAndPlotUI()
    if self._roomData == nil then
        return
    end
    local pets = self._roomData:GetPets()
    if pets == nil then
        return
    end
    for _, pet in pairs(pets) do
        local storyId = pet:GetTriggeredStoryId()
        local taskId = pet:GetTriggeredTaskId()
        local hasPlot = storyId and storyId ~= 0
        local hasEvent = taskId and taskId ~= 0

        if hasPlot then
            self._hasPlotGo:SetActive(true)
        elseif hasEvent then
            local taskInfo = pet:GetFirstTaskInfo()
            if taskInfo then
                local state = taskInfo.state
                if state == PetTaskState.PetTS_Active then --可触发
                    self._taskCanTriggerGo:SetActive(true)
                elseif state == PetTaskState.PetTS_Accept then --已接
                    self._taskHasGetGo:SetActive(true)
                elseif state == PetTaskState.PetTS_Finish then --可完成
                    self._taskCanCompleteGo:SetActive(true)
                end
            else
                self._taskCanTriggerGo:SetActive(true)
            end
        end
    end
end

--监听萤火改变
function AircraftRoom3DUI:OnFireFlyChanged()
    if not self._inThisRoom and self._state == AirUIState.RoomIdle then
        --刷新可升级提示
        local canLvUp, matEnough = self._module:CanRoomLevelUp(self._roomData:SpaceId(), true)
        self.lvup:SetActive(canLvUp)
        if canLvUp then
            if matEnough then
                self:FlushGreenArrow(true)
            else
                self:FlushGreenArrow(false)
            end
        end
    end
end

function AircraftRoom3DUI:FlushGreenArrow(green)
    if green then
        self._arrow_01.color = Color(0.4, 0.75, 0.1)
        self._arrow_02.color = Color(0, 0, 0)
        self._arrow_03.color = Color(0.45, 0.63, 0.14)
    else
        self._arrow_01.color = Color(1, 0.47, 0.23)
        self._arrow_02.color = Color(0.63, 0.27, 0.14)
        self._arrow_03.color = Color(0.63, 0.27, 0.14)
    end
end

function AircraftRoom3DUI:HidePetTaskAndPlotUI()
    self._hasPlotGo:SetActive(false)
    self._taskCanTriggerGo:SetActive(false)
    self._taskHasGetGo:SetActive(false)
    self._taskCanCompleteGo:SetActive(false)
end

function AircraftRoom3DUI:RefreshRoomUI()
    local state = self._state
    self.stateGO:SetActive(false)
    self.collectGO:SetActive(false)
    self.canCollectGo:SetActive(false)
    self.newTaskGo:SetActive(false)
    self.canCleanGO:SetActive(false)
    -- self.canBuildGO:SetActive(false)
    self.idleInfoGO:SetActive(false)
    self._unLockGO:SetActive(false)

    local showInfo = false

    local onlyName = false

    --临时处理
    self.stateText.text = "建造中"
    if state == AirUIState.RoomBuilding then
        self._countDown = true
        showInfo = false
        self.stateGO:SetActive(true)
    elseif state == AirUIState.RoomUpgrading then
        self.stateText.text = "升级中"
        self._countDown = true
        showInfo = false
        self.stateGO:SetActive(true)
    elseif state == AirUIState.RoomDegrading then
        self.stateText.text = "降级中"
        self._countDown = true
        showInfo = false
        self.stateGO:SetActive(true)
    elseif state == AirUIState.RoomTearing then
        self.stateText.text = "拆除中"
        self._countDown = true
        showInfo = false
        self.stateGO:SetActive(true)
    elseif state == AirUIState.SpaceCleaning then
        self.stateText.text = "空间清理中"
        self._countDown = true
        showInfo = false
        self.stateGO:SetActive(true)
    elseif state == AirUIState.CollectAward then
        if not self._awardWidgetInited then
            self:InitAward(self._roomData)
        end

        self.assetIcon.sprite = self.awardSprite
        self._countDown = false
        self.collectGO:SetActive(true)
        showInfo = true
    elseif state == AirUIState.SpaceUnclean or state == AirUIState.SpaceUnbuild then
        -- self._animation:Play("eff_RoomUIBase_unclean")
        -- elseif state == AirUIState.SpaceUnbuild then
        -- self._countDown = false
        -- showInfo = false
        -- self.canBuildGO:SetActive(true)
        -- if self._oldState == AirUIState.SpaceUnclean then
        --     self.canCleanGO:SetActive(true)
        --     self:LoadEffect("uieff_RoomUIBase_01")
        --     self._animation:Play("eff_RoomUIBase_1to2")
        -- end
        self._countDown = false
        showInfo = false
        self.canCleanGO:SetActive(true)
    elseif state == AirUIState.AisleUnclean then
        self._countDown = false
        self.canCleanGO:SetActive(true)
        showInfo = false
    elseif state == AirUIState.RoomIdle or state == AirUIState.CanCollectAward or state == AirUIState.HaveNewTask then
        self._countDown = false
        showInfo = true
        --2020.11.12 直接清理加建造
        if self._oldState == AirUIState.SpaceUnclean or self._oldState == AirUIState.SpaceUnbuild then
            self._animation:Play("eff_RoomUIBase_unclean_end")
        end
        if state == AirUIState.CanCollectAward then
            self.canCollectGo:SetActive(true)
            self.newTaskGo:SetActive(false)
        elseif state == AirUIState.HaveNewTask then
            self.canCollectGo:SetActive(false)
            self.newTaskGo:SetActive(true)
        end
    elseif state == AirUIState.Aisle then
        if self._oldState == AirUIState.AisleUnclean or self._oldState == AirUIState.AisleUnbuild then
            self._animation:Play("eff_RoomUIBase_unclean_end")
        end
    elseif state == AirUIState.SpaceNotOpen or state == AirUIState.AisleNotOpen then
        local level = self._module:GetSpaceUnlockLevel(self._spaceID)
        if level then
            self._unLockGO:SetActive(true)
            self._unlockCondition.text = string.format(StringTable.Get("str_aircraft_unlock_condition"), level)
        end
    elseif state == AirUIState.RestAreaRoom then
        -- if self._oldState == AirUIState.SpaceUnbuild then
        --     self.canBuildGO:SetActive(true)
        --     self._animation:Play("eff_RoomUIBase_1end")
        -- end
        --qa 12241
        self._countDown = false
        onlyName = true
        showInfo = true
    elseif state == AirUIState.RestAreaRoomLock then
    elseif state == AirUIState.SpaceClosed then
        local unlockTime = Cfg.cfg_aircraft_space[self._spaceID].UnlockTime
        local time =
            GameGlobal.GetModule(LoginModule):GetTimeStampByTimeStr(unlockTime, Enum_DateTimeZoneType.E_ZoneType_GMT)
        local now = GetSvrTimeNow()
        if time < now then
            Log.exception("空间开启倒计时已结束,不应该是未开启状态")
        end
        --开始1个倒计时
        if self._spaceOpenTimer then
            GameGlobal.Timer():CancelEvent(self._spaceOpenTimer)
            self._spaceOpenTimer = nil
        end
        self._spaceOpenTimer =
            GameGlobal.Timer():AddEvent(
            (time + 1 - now) * 1000,
            function()
                GameGlobal:EventDispatcher():Dispatch(GameEventType.AircraftRefreshRoomUI, self._spaceID)
                self._spaceOpenTimer = nil
            end
        )
    else
        self._countDown = false
    end

    --名字背景
    if state == AirUIState.RestAreaRoom then
        self._nameBg.sprite = self.nameBgRestRoom
    else
        self._nameBg.sprite = self.normalLevelSprite
    end

    --可展示等级，且不在房间内
    if showInfo then
        self.nameText:SetText(StringTable.Get(self._roomData:GetRoomName()))
        self.idleInfoGO:SetActive(true)
        if onlyName then
            self.canSettleGO:SetActive(false)

            for i = 1, #self.levelTips do
                self.levelTips[i]:SetActive(false)
            end
        else
            local spaceID = self._roomData:SpaceId()
            local canLevelUp, matEnough = self._module:CanRoomLevelUp(spaceID, true)
            self.lvup:SetActive(canLevelUp)
            if canLevelUp then
                self._animIdx = 1
                if matEnough then
                    self._animIdx = 2
                    self:FlushGreenArrow(true)
                else
                    self._animIdx = 1
                    self:FlushGreenArrow(false)
                end
                self._lv_anim_go:SetActive(true)
                self._lv_anim:Play(self._canLvUpAnim[self._animIdx])
                if self._animEvent then
                    GameGlobal.Timer():CancelEvent(self._animEvent)
                    self._animEvent = nil
                end
                self._animEvent =
                    GameGlobal.Timer():AddEvent(
                    1700,
                    function()
                        self._arrowGo:SetActive(true)
                        self._lv_anim_go:SetActive(false)
                        self._animEvent = nil
                    end
                )
            end

            local canSettle = self._module:CanRoomSettlePet(spaceID)
            self.canSettleGO:SetActive(canSettle)

            local level = self._roomData:Level()
            for i = 1, #self.levelTips do
                self.levelTips[i]:SetActive(i <= level)
            end
        end
    end

    if self._countDown then
        local time = self:CountDownTime()
        self.timerText.text = HelperProxy:GetInstance():FormatTime(time)
    end
    if self._roomData then
        if self._roomData:GetRoomType() == AirRoomType.DispatchRoom then
            if not self.newTaskGO then
                self.newTaskGO = self._roomGO.transform:GetChild(0):Find("TaskTipsUI/NewTask").gameObject
            end
            if not self.taskCompleteGO then
                self.taskCompleteGO = self._roomGO.transform:GetChild(0):Find("TaskTipsUI/TaskComplete").gameObject
            end
            if self._roomData:HasCompleteTask() then
                self.newTaskGO:SetActive(false)
                self.taskCompleteGO:SetActive(true)
            elseif self._roomData:HasNewTask() then
                self.newTaskGO:SetActive(true)
                self.taskCompleteGO:SetActive(false)
            else
                self.newTaskGO:SetActive(false)
                self.taskCompleteGO:SetActive(false)
            end
            self:RefreshDispatchTips()
        elseif self._roomData:GetRoomType() == AirRoomType.TacticRoom then
            self._tacticTip:SetActive(true)
            ---@type AircraftTacticRoom
            local room = self._roomData
            if room:CanReceiveWeeklyReward() then --可领取周奖励
                self._tacticText:SetText(StringTable.Get("str_aircraft_tactic_can_collect_award"))
            elseif room:CanOpenCartridgeGiftBox() then --可领取卡带
                self._tacticText:SetText(StringTable.Get("str_aircraft_tactic_can_collect_tape"))
            elseif room:IsCartridgeLimit() then --卡带到上限
                self._tacticText:SetText(StringTable.Get("str_aircraft_tactic_tape_reach_limit"))
            else
                self._tacticTip:SetActive(false)
            end
        end
    end
end

--初始化奖励文本位置
function AircraftRoom3DUI:InitAward(roomData)
    if roomData == nil then
        return
    end

    local roomType = roomData:GetRoomType()
    --特定的三种房间有奖励
    if roomType == AirRoomType.MazeRoom or roomType == AirRoomType.PrismRoom or roomType == AirRoomType.TowerRoom then
        if self._roomGO.transform:GetChild(0) == nil then
            Log.exception("[Aircraft] 房间prefab加载失败，空间id：", roomData:SpaceId())
            return
        end

        --奖励ui挂在房间中，但是逻辑在这里更新
        self.awardGO = self._roomGO.transform:GetChild(0):Find("award/AircraftRoomCanvas").gameObject
        --用于检测点击到的物体是否是本房间的奖励物品
        self.awardChecker = self._roomGO.transform:GetChild(0):Find("award").gameObject
        if not self.awardGO then
            Log.fatal("[Aircraft] 找不到房间ui，房间名称：", self._roomGO.name)
        end
        local uiView = self.awardGO:GetComponent(typeof(UIView))
        self.awardIcon = uiView:GetUIComponent("Image", "awardIcon")
        local assetID = roomData:AwardID()
        local itemCfg = Cfg.cfg_top_tips[assetID]
        local atlasReq = ResourceManager:GetInstance():SyncLoadAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
        self.awardSprite = atlasReq.Obj:GetSprite(itemCfg.Icon)
        self.resReqs[#self.resReqs] = atlasReq

        self.awardIcon.sprite = self.awardSprite
        self.awardText = uiView:GetUIComponent("UILocalizationText", "awardText")
        self.awardGO:SetActive(false)

        self._awardWidgetInited = true
    end
end

function AircraftRoom3DUI:RefreshAwardUI()
    if self._roomData == nil then
        return
    end

    local cur, ceiling = 0
    local awardText = nil
    local roomType = self._roomData:GetRoomType()
    if roomType == AirRoomType.MazeRoom then
        -- ceiling = math.floor(self._roomData:GetBaseLightCount())
        cur = math.floor(self._module:GetLightStorage())
        self._refreshAward = true
        awardText = cur
    elseif roomType == AirRoomType.PrismRoom then
        local base, petBonus = self._roomData:GetPhysicStorageLimit()
        ceiling = math.floor(base + petBonus)
        self._refreshAward = cur < ceiling
        cur = math.floor(self._module:GetPhysicStorage())
        awardText = string.format(self._awardFormat, cur, ceiling)
    elseif roomType == AirRoomType.TowerRoom then
        local base, petBonus = self._roomData:GetOutputLimit()
        ceiling = math.floor(base + petBonus)
        cur = math.floor(self._module:GetHeartAmberCount())
        self._refreshAward = cur < ceiling
        awardText = string.format(self._awardFormat, cur, ceiling)
    end
    if awardText then
        if not self._awardWidgetInited then
            self:InitAward(self._roomData)
        end
        self.awardText.text = awardText
    end
end

function AircraftRoom3DUI:CheckAndStartTimer()
    if self._refreshAward or self._countDown then
        if self.timeEvent then
            GameGlobal.Timer():CancelEvent(self.timeEvent)
            self.timeEvent = nil
        end

        self.timeEvent =
            GameGlobal.Timer():AddEventTimes(
            1000,
            TimerTriggerCount.Infinite,
            function()
                --倒计时
                if self._countDown then
                    local time = self:CountDownTime()
                    if time <= 0 then
                        self.timerText.text = "00:00:00"
                        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftRequestDataAndRefreshMainUI)
                        self._countDown = false
                        time = 0
                    end
                    self.timerText.text = HelperProxy:GetInstance():FormatTime(time)
                end

                --奖励
                if self._refreshAward and self._inThisRoom then
                    self:RefreshAwardUI()
                end

                if not self._refreshAward and not self._countDown then
                    GameGlobal.Timer():CancelEvent(self.timeEvent)
                    self.timeEvent = nil
                end
            end
        )
    end
end

function AircraftRoom3DUI:LoadEffect(name)
    local req = ResourceManager:GetInstance():SyncLoadAsset(name .. ".prefab", LoadType.GameObject)
    local eft = req.Obj
    self.resReqs[#self.resReqs] = req
    eft.transform:SetParent(self.effectPlot.transform)
    eft.transform.localPosition = Vector3.zero
    eft.transform.localRotation = Quaternion.Euler(Vector3.zero)
    eft.transform.localScale = Vector3.one
    return eft
end

function AircraftRoom3DUI:Hide()
    if self.timeEvent then
        GameGlobal.Timer():CancelEvent(self.timeEvent)
        self.timeEvent = nil
    end
end

function AircraftRoom3DUI:GetState()
    return self._state
end

function AircraftRoom3DUI:EnterRoom()
    self._inThisRoom = true

    -- self.stateGO:SetActive(false)
    -- self.collectGO:SetActive(false)
    -- self.canCleanGO:SetActive(false)
    -- self.canBuildGO:SetActive(false)

    -- self._taskStatusPanel:SetActive(false)
    -- self:HidePetTaskAndPlotUI()
    self:Select()
end

function AircraftRoom3DUI:ExitRoom()
    self._inThisRoom = false
    -- self._taskStatusPanel:SetActive(true)
    self:Deselect()
end

function AircraftRoom3DUI:Selected()
    return self._inThisRoom
end

function AircraftRoom3DUI:SetAwardUIActive(active)
    if self.awardGO then
        self.awardGO:SetActive(active)
    end
    if self.taskTipsUI then
        self.taskTipsUI:SetActive(active)
    end
end

function AircraftRoom3DUI:IsAwardObject(go)
    if self.awardChecker then
        return self.awardChecker == go
    end
    return false
end

function AircraftRoom3DUI:Select()
    if self._selectAnim.gameObject.activeInHierarchy then
        self._selectAnim:PlayQueued("uieff_FCSelect_In")
        self._selectAnim:PlayQueued("uieff_FCSelect_Loop")
        --第一次调用Animation.Play时如果GameObject时关闭的，那之后再调用Play则都无效，这里需要特殊处理
        self._playedBoxAnim = true
    end
end

function AircraftRoom3DUI:Deselect()
    if self._playedBoxAnim then
        -- self._selectAnim:Play("uieff_FCSelect_Out")
        self._selectAnim:Stop()
        self._boxRoot:SetActive(false)
    else
        if self._selectAnim.gameObject.activeInHierarchy then
            -- self._selectAnim:Play("uieff_FCSelect_Out")
            self._selectAnim:Stop()
            self._boxRoot:SetActive(false)
        end
    end
end

function AircraftRoom3DUI:GetUIComponent(cpt, name)
    return self._uiViewCpt:GetUIComponent(cpt, name)
end

function AircraftRoom3DUI:GetGameObject(name)
    return self._uiViewCpt:GetGameObject(name)
end

function AircraftRoom3DUI:GetBtnGuide()
    return self.btnGuide
end

function AircraftRoom3DUI:HalfShow()
    self._canvasGroup.alpha = 0.5
end

function AircraftRoom3DUI:WholeShow()
    self._canvasGroup.alpha = 1
end

function AircraftRoom3DUI:SetActive(active)
    self._viewGO:SetActive(active)
end
