---@class UIForgeSequenceItem:UICustomWidget
_class("UIForgeSequenceItem", UICustomWidget)
UIForgeSequenceItem = UIForgeSequenceItem

function UIForgeSequenceItem:Constructor()
    self.mHomeland = GameGlobal.GetModule(HomelandModule)
    self.data = self.mHomeland:GetForgeData()
end

function UIForgeSequenceItem:OnShow()
    self.unlock = self:GetGameObject("unlock")
    self.forging = self:GetGameObject("forging")
    self.getable = self:GetGameObject("getable")
    self.lock = self:GetGameObject("lock")
    self.idle = self:GetGameObject("idle")
    ---@type RawImageLoader
    self.imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    ---@type UILocalizationText
    self.txtName = self:GetUIComponent("UILocalizationText", "txtName")
    ---@type UILocalizationText
    self.txtSize = self:GetUIComponent("UILocalizationText", "txtSize")
    ---@type UILocalizationText
    self.txtLiveable = self:GetUIComponent("UILocalizationText", "txtLiveable")
    ---@type UILocalizationText
    self.txtOwn = self:GetUIComponent("UILocalizationText", "txtOwn")
    ---@type UILocalizationText
    self.txtPlace = self:GetUIComponent("UILocalizationText", "txtPlace")
    ---@type UILocalizationText
    self.txtCD = self:GetUIComponent("UILocalizationText", "txtCD")
    ---@type UILocalizationText
    self.txtUnlockCondition = self:GetUIComponent("UILocalizationText", "txtUnlockCondition")
    ---@type UILocalizationText
    self.forgeCount = self:GetUIComponent("UILocalizationText", "forgeCount")
    self.forgeCountParent = self:GetGameObject("forgeCountParent")

    self._helpCDTime = self:GetUIComponent("UILocalizationText", "helpCDTime")
    self._helpTime = self:GetUIComponent("UILocalizationText", "helpTime")
    self._helpCD = self:GetGameObject("helpCD")
end
function UIForgeSequenceItem:OnHide()
    self.imgIcon:DestoryLastImage()
    self:CancelTimerEvent()
end

function UIForgeSequenceItem:RegisterTimeEvent()
    self:CancelTimerEvent()
    self.te =
        GameGlobal.Timer():AddEventTimes(
        1000,
        TimerTriggerCount.Infinite,
        function()
            self:FlushTime()
        end
    )
end
function UIForgeSequenceItem:CancelTimerEvent()
    if self.te then
        GameGlobal.Timer():CancelEvent(self.te)
        self.te = nil
    end
end

---@param index number ForgeSequence的index
function UIForgeSequenceItem:Flush(index)
    self:CancelTimerEvent()
    self.index = index
    local s = self.data:GetForgeSequenceByIndex(index)
    if s.state == ForgeSequenceState.Locked then
        self.unlock:SetActive(false)
        self.lock:SetActive(true)
        self.idle:SetActive(false)
        self.txtUnlockCondition:SetText(StringTable.Get("str_homeland_skin_islock", s.unlockLevel))
    elseif s.state == ForgeSequenceState.Idle then
        self.unlock:SetActive(false)
        self.lock:SetActive(false)
        self.idle:SetActive(true)
    else
        self.unlock:SetActive(true)
        self.lock:SetActive(false)
        self.idle:SetActive(false)
        local item = self.data:GetForgeInfoItemById(s.forgeItemId)
        self.imgIcon:LoadImage(item.icon)
        self.txtName:SetText(
            StringTable.Get(
                "str_homeland_forge_detail_name",
                StringTable.Get("str_homeland_quality_" .. item.quality),
                item.name
            )
        )
        self.txtSize:SetText(item.size.x .. "*" .. item.size.y)
        self.txtLiveable:SetText(item.livableValue)
        local curCount, placedCount = UIForgeData.GetOwnPlaceCount(item.id)
        self.txtOwn:SetText(StringTable.Get("str_homeland_forge_detail_own", curCount))
        self.txtPlace:SetText(StringTable.Get("str_homeland_forge_sequence_place", placedCount))
        self.forgeCount:SetText("×" .. item.forgeCount)
        self.forgeCountParent:SetActive(item.forgeCount > 1)
        if s.state == ForgeSequenceState.Forging then
            self.forging:SetActive(true)
            self.getable:SetActive(false)
            self:RegisterTimeEvent()
            self:FlushTime()
            --一般情况下所有打造中的物品都可以助力
            if s.helpRemainTime then
                --助力相关
                self._helpTime.gameObject:SetActive(true)
                local hour = math.ceil(s.helpRemainTime / 3600)
                if hour > 0 then
                    self._helpTime:SetText(StringTable.Get("str_homeland_visit_help_time", hour))
                    self._helpTime.color = Color(70 / 255, 162 / 255, 200 / 255, 1)
                else
                    self._helpTime:SetText(StringTable.Get("str_homeland_visit_help_finish"))
                    self._helpTime.color = Color(160 / 255, 159 / 255, 159 / 255, 1)
                end
                if s.helpedTime > 0 then
                    self._helpCD:SetActive(true)
                    local cdHour = math.ceil(s.helpedTime / 3600)
                    self._helpCDTime:SetText(StringTable.Get("str_homeland_visit_helped_time", cdHour))
                else
                    self._helpCD:SetActive(false)
                end
            else
                self._helpTime.gameObject:SetActive(false)
                self._helpCD:SetActive(false)
            end
        elseif s.state == ForgeSequenceState.Getable then
            self.forging:SetActive(false)
            self.getable:SetActive(true)
        else
            Log.fatal("### invalid state. state=", s.state)
        end
    end
end

function UIForgeSequenceItem:FlushTime()
    local s = self.data:GetForgeSequenceByIndex(self.index)
    if UICommonHelper.GetNowTimestamp() >= s.doneTimestamp then
        s.state = ForgeSequenceState.Getable
        self:Flush(self.index)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandForgeUpdateSequence)
    else
        UIForge.FlushCDText(self.txtCD, s.doneTimestamp, self.data.strsWillGetable, true)
    end
end

function UIForgeSequenceItem:BtnGetOnClick(go)
    local s = self.data:GetForgeSequenceByIndex(self.index)
    if s.state == ForgeSequenceState.Getable then
        local itemId = s.forgeItemId
        self._curExp = self.mHomeland:GetHomelandInfo().exp --记录当前经验值
        self:StartTask(
            function(TT)
                self:Lock("HomeReqPickupItem")
                local res, forge_list, architecture = self.mHomeland:HandlPickUp(TT, self.index)
                if UIForgeData.CheckCode(res:GetResult()) then
                    self.data:InitSequence(forge_list)
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandForgeUpdateSequence)
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandForgeUpdateList)
                    --显示收取道具
                    local a = RoleAsset:New()
                    a.assetid = itemId
                    a.count = s.forgeCount
                    --先弹获得物品弹窗
                    self:ShowDialog("UIHomeShowAwards", {a}, nil, false)

                    --同时弹经验飘字
                    local deltaExp = math.max(0, self.mHomeland:GetHomelandInfo().exp - self._curExp)
                    if deltaExp > 0 then
                        ToastManager.ShowHomeToast(StringTable.Get("str_homeland_forge_add_exp", deltaExp))
                    end
                    YIELD(TT, 1000)

                    --1秒后弹升级提示
                    ---@type UIHomelandModule
                    local uiModule = GameGlobal.GetUIModule(HomelandModule)
                    uiModule:TryPopLevelUpTip()
                    self:UnLock("HomeReqPickupItem")
                else
                    self:UnLock("HomeReqPickupItem")
                end
            end,
            self
        )
    end
end

function UIForgeSequenceItem:btnCancelOnClick(go)
    local s = self.data:GetForgeSequenceByIndex(self.index)
    local item = self.data:GetForgeInfoItemById(s.forgeItemId)
    self:ShowDialog(
        "UIHomelandMessageBox_Items",
        StringTable.Get("str_homeland_forge_cancel"),
        StringTable.Get("str_homeland_forge_cancel_or_not", item.name),
        item.forgeCosts,
        function(param)
            self:StartTask(
                function(TT)
                    local key = "CancelForgeTask"
                    self:Lock(key)
                    local res, forge_list, return_material = self.mHomeland:HandleCancel(TT, s.index)
                    if UIForgeData.CheckCode(res:GetResult()) then
                        self.data:InitSequence(forge_list)
                        GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandForgeUpdateSequence)
                        GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandForgeUpdateList)
                        ToastManager.ShowHomeToast(StringTable.Get("str_homeland_forge_cancel_success"))
                    end
                    self:UnLock(key)
                end,
                self
            )
        end
    )
end

function UIForgeSequenceItem:btnSpeedOnClick(go)
    local item = self.data:GetForgeSequenceByIndex(self.index)
    local accItemId, accSeconds = self.data:GetForgeAccItem()
    self:ShowDialog(
        "UIHomelandAccelerate",
        StringTable.Get("str_homeland_forge_acc_title"),
        item.doneTimestamp,
        accItemId,
        accSeconds,
        function(id, count)
            self:_UseItem(id, count)
        end
    )
end

function UIForgeSequenceItem:_UseItem(id, count)
    if count <= 0 then
        return
    end
    self:StartTask(
        function(TT)
            local accItemId, accSeconds = self.data:GetForgeAccItem()
            local ra = RoleAsset:New()
            ra.assetid = id
            ra.count = count
            local res, forge_list = self.mHomeland:HandleAccelerate(TT, self.index, ra)
            if UIForgeData.CheckCode(res:GetResult()) then
                self.data:InitSequence(forge_list)
                GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandForgeUpdateList)
                local s = self.data:GetForgeSequenceByIndex(self.index)
                if s.state == ForgeSequenceState.Getable then
                    ToastManager.ShowHomeToast(StringTable.Get("str_homeland_forge_acc_success_done"))
                else
                    local s = UIForge.GetTimestampStr(count * accSeconds, self.data.strsWillGetable)
                    ToastManager.ShowHomeToast(StringTable.Get("str_homeland_forge_acc_success", s))
                end
            end
        end,
        self
    )
end
