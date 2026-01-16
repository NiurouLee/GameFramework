---@class UISetAutoFightCountAndTicket:UIController
_class("UISetAutoFightCountAndTicket", UIController)
UISetAutoFightCountAndTicket = UISetAutoFightCountAndTicket

function UISetAutoFightCountAndTicket:OnShow(uiParams)
    self._matchType = uiParams[1]
    self._oneBattleNeedPower = uiParams[2]
    self._uuid = uiParams[3]

    self._ticketSelectTab = {}
    self._ticketSelectTab[0] = self:GetGameObject("NoneTicketSelect")
    self._ticketSelectTab[1] = self:GetGameObject("OneTicketSelect")
    self._ticketSelectTab[2] = self:GetGameObject("TwoTicketSelect")
    self._ticketBgTab = {}
    self._ticketBgTab[0] = self:GetGameObject("NoneTicketBg")
    self._ticketBgTab[1] = self:GetGameObject("OneTicketBg")
    self._ticketBgTab[2] = self:GetGameObject("TwoTicketBg")
    self._countLabel = self:GetUIComponent("UILocalizationText", "Count")
    self._countShadowLabel = self:GetUIComponent("UILocalizationText", "CountShadow")
    self._powerCountLabel = self:GetUIComponent("UILocalizationText", "PowerCount")
    self._ticketCountLabel = self:GetUIComponent("UILocalizationText", "TicketCount")
    self._rewardMultipleLabel = self:GetUIComponent("UILocalizationText", "RewardMultiple")
    self._btStartOnClicked = self:GetGameObject("BtStartOnClicked")
    self._btnStart = self:GetGameObject("BtnStart")
    self._btnTxtLabel = self:GetUIComponent("UILocalizationText", "btnTxt")

    self._powerID = RoleAssetID.RoleAssetPhyPoint
    self._maxFightCount = 99

    self._fightCount = 1
    self._ticketCount = 2
    self._needPower = 0
    self._totalPower = 0
    self._needTicket = 0
    self._totalTicket = 0
    self._rewardMultiple = 0

    self:Refresh()
    self:ChkAutoPick()

    --注册体力值更新的回调
    self:AttachEvent(GameEventType.RolePropertyChanged, self.ChangePhysicalPowerNumber)

    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._btnStart),
        UIEvent.Press,
        function(go)
            self._btStartOnClicked:SetActive(true)
            self._btnTxtLabel.color = Color(1, 1, 1, 1)
            self:RefreshPowerInfo(true)
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._btnStart),
        UIEvent.Release,
        function(go)
            self._btStartOnClicked:SetActive(false)
            self._btnTxtLabel.color = Color(0, 0, 0, 1)
            self:RefreshPowerInfo(false)
        end
    )
end

function UISetAutoFightCountAndTicket:ChangePhysicalPowerNumber()
    self:RefreshPowerCount()
    self:RefreshUI()
end

function UISetAutoFightCountAndTicket:Refresh()
    self:RefreshPowerCount()
    self:RefreshTicketCount()
    self:CalcTicketAndPower()
    self:RefreshUI()
end

function UISetAutoFightCountAndTicket:RefreshTicketCount()
    ---@type ResDungeonModule
    local resModule = self:GetModule(ResDungeonModule)
    self._totalTicket = resModule:GetDoubleResNum()
end

function UISetAutoFightCountAndTicket:RefreshPowerCount()
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    self._totalPower = roleModule:GetAssetCount(self._powerID)
end

function UISetAutoFightCountAndTicket:CalcTicketAndPower()
    self._needTicket = self._fightCount * self._ticketCount
    if self._needTicket > self._totalTicket then
        self._needTicket = self._totalTicket
    end
    self._needPower = (self._fightCount + self._needTicket) * self._oneBattleNeedPower
    self._rewardMultiple = self._needTicket + self._fightCount
end

function UISetAutoFightCountAndTicket:CalcAutoFightData()
    local autoDatas = {}
    local totalTicketCount = self._totalTicket
    for i = 1, self._fightCount do
        local autoData = {}
        autoData.ticketCount = 0
        if self._ticketCount <= totalTicketCount then
            autoData.ticketCount = self._ticketCount
            totalTicketCount = totalTicketCount - self._ticketCount
        else
            autoData.ticketCount = totalTicketCount
            totalTicketCount = 0
        end
        autoDatas[#autoDatas + 1] = autoData
    end
    return autoDatas
end

function UISetAutoFightCountAndTicket:RefreshUI()
    self._countLabel:SetText(self._fightCount)
    self._countShadowLabel:SetText(self._fightCount)

    for k, v in pairs(self._ticketSelectTab) do
        v:SetActive(k == self._ticketCount)
    end
    for k, v in pairs(self._ticketBgTab) do
        v:SetActive(k ~= self._ticketCount)
    end
    self:RefreshPowerInfo(false)
    self._ticketCountLabel:SetText(self._needTicket .. "/" .. self._totalTicket)
    self._rewardMultipleLabel:SetText(StringTable.Get("str_battle_auto_battle_reward_multiple", self._rewardMultiple))
end

function UISetAutoFightCountAndTicket:RefreshPowerInfo(isPress)
    local str = ""
    if isPress then
        if self._needPower <= self._totalPower then
            str = "<color=#FFFFFF>" .. self._needPower .. "/" .. self._totalPower .. "</color>"
        else
            str = "<color=#FF0000>" .. self._needPower .. "</color>" .. "<color=#FFFFFF>" .. "/" .. self._totalPower .. "</color>"
        end
    else
        if self._needPower <= self._totalPower then
            str = "<color=#000000>" .. self._needPower .. "/" .. self._totalPower .. "</color>"
        else
            str = "<color=#FF0000>" .. self._needPower .. "</color>" .. "<color=#000000>" .. "/" .. self._totalPower .. "</color>"
        end
    end
    
    self._powerCountLabel:SetText(str)
end

function UISetAutoFightCountAndTicket:MaskOnClick()
    self:CloseDialog()
end

function UISetAutoFightCountAndTicket:BtnStartOnClick()
    --体力不够打开恢复棱镜界面
    if self._needPower > self._totalPower then
        if self._powerID == RoleAssetID.RoleAssetPhyPoint then
            self:ShowDialog("UIGetPhyPointController")
        else
            local name = StringTable.Get(Cfg.cfg_item[self._powerID].Name)
            ToastManager.ShowToast(StringTable.Get("str_activity_point_not_enough2", name))
        end
        return
    end

    self:CloseDialog()
    ---@type SerialAutoFightModule
    local serialAutoFightModule = GameGlobal.GetModule(SerialAutoFightModule)
    local autoData = self:CalcAutoFightData()
    serialAutoFightModule:SetAutoFightDatas(self._matchType, self._fightCount, autoData)
    --进入编队界面
    if self._matchType == MatchType.MT_Mission then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.FakeInput,
            {ui = "UIStage", input = "btnFightOnClick", args = {}}
        )
    elseif self._matchType == MatchType.MT_ResDungeon then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.FakeInput,
            {ui = "UIResDetailInfoCell", uiid = self._uuid, input = "btngoOnClick", args = {}}
        )
    end
end

function UISetAutoFightCountAndTicket:BtnTipsOnClick()
    self:ShowDialog("UISetAutoFightIntroduce")
end

function UISetAutoFightCountAndTicket:BtnNoneTicketOnClick()
    self._ticketCount = 0
    self:Refresh()
end

function UISetAutoFightCountAndTicket:BtnOneTicketOnClick()
    self._ticketCount = 1
    self:Refresh()
end

function UISetAutoFightCountAndTicket:BtnTwoTicketOnClick()
    self._ticketCount = 2
    self:Refresh()
end

function UISetAutoFightCountAndTicket:MinBtnOnClick()
    self._fightCount = 1
    self:Refresh()
end

function UISetAutoFightCountAndTicket:SubBtnOnClick()
    if self._fightCount <= 1 then
        ToastManager.ShowToast(StringTable.Get("str_battle_serial_auto_fight_min_count"))
        return
    end
    self._fightCount = self._fightCount - 1
    self:Refresh()
end

function UISetAutoFightCountAndTicket:AddBtnOnClick()
    if self._fightCount >= self._maxFightCount then
        ToastManager.ShowToast(StringTable.Get("str_common_max_num"))
        return
    end
    self._fightCount = self._fightCount + 1
    self:Refresh()
end

function UISetAutoFightCountAndTicket:MaxBtnOnClick()
    self._fightCount = 0
    local totalTicket = self._totalTicket
    local totalPower = self._totalPower
    if self._oneBattleNeedPower <= 0 then
        self._fightCount = self._maxFightCount
    else
        while totalPower >= self._oneBattleNeedPower do
            local ticket = 0
            if self._ticketCount > totalTicket then
                ticket = totalTicket
                totalTicket = 0
            else
                ticket = self._ticketCount
                totalTicket = totalTicket - ticket
            end
            local costPower = (ticket + 1) * self._oneBattleNeedPower
            if costPower > totalPower then
                break
            end
            totalPower = totalPower - costPower
            self._fightCount = self._fightCount + 1
        end
    end
    if self._fightCount <= 0 then
        self._fightCount = 1
    end
    self:Refresh()
end

function UISetAutoFightCountAndTicket:GetMatchType()
    return self._matchType
end

function UISetAutoFightCountAndTicket:GetNeedPower()
    return self._oneBattleNeedPower
end

function UISetAutoFightCountAndTicket:GetDoubleTicket()
    return self._doubleTicket
end

function UISetAutoFightCountAndTicket:GetUuid()
    return self._uuid
end

function UISetAutoFightCountAndTicket:ChkAutoPick()
    self._txtTitle = self:GetUIComponent("UILocalizationText", "uiTitle")
    self._uiTicket = self:GetUIComponent("RectTransform", "uiTicket")
    self._uiAutoCount = self:GetUIComponent("RectTransform", "AutoCount")
    self._uiAutoPick = self:GetUIComponent("RectTransform", "uiAutoPick")

    local aps = GameGlobal.GetModule(SerialAutoFightModule):GetApsData()
    local isEnable = aps:IsEnable(true)

    -- layout
    if not isEnable then
        self._txtTitle.transform.anchoredPosition = Vector2(0, 279)
        self._uiTicket.anchoredPosition = Vector2(-1.5, 131)
        self._uiAutoCount.anchoredPosition = Vector2(0, -72)
        self._rewardMultipleLabel.transform.anchoredPosition = Vector2(56.5, -178)
        self._btnStart.transform.anchoredPosition = Vector2(0, -245)
    else
        self._txtTitle.transform.anchoredPosition = Vector2(0, 295)
        self._uiTicket.anchoredPosition = Vector2(-1.5, 31)
        self._uiAutoCount.anchoredPosition = Vector2(0, -150)
        self._rewardMultipleLabel.transform.anchoredPosition = Vector2(56.5, -208)
        self._btnStart.transform.anchoredPosition = Vector2(0, -268)
    end

    -- logic
    if not isEnable then
        self._uiAutoPick.gameObject:SetActive(false)
    else
        self._uiAutoPickItem = self:GetUIComponent("UISelectObjectPath", "uiAutoPickItem")
        self._widgetAutoPickItem = self._uiAutoPickItem:SpawnObject("UISerialAutoPickStuff")
        self._widgetAutoPickItem:SetTips("uiAutoPickTips")
    end
end
