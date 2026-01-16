---@class UISetAutoFightCountNew:UIController
_class("UISetAutoFightCountNew", UIController)
UISetAutoFightCountNew = UISetAutoFightCountNew

function UISetAutoFightCountNew:OnShow(uiParams)
    self._txtCount = self:GetUIComponent("UILocalizationText", "txtCount")
    self._txtCountShadow = self:GetUIComponent("UILocalizationText", "txtCountShadow")
    self._txtCost = self:GetUIComponent("UILocalizationText", "txtCost")
    self._txtDouble = self:GetUIComponent("UILocalizationText", "txtDouble")
    self._btnTxt = self:GetUIComponent("UILocalizationText", "btnTxt")
    self._btnImg = self:GetUIComponent("Image", "btnGo")

    --按钮切换图片和文字颜色
    self._atlas = self:GetAsset("UIShop.spriteatlas", LoadType.SpriteAtlas)

    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._btnImg.gameObject),
        UIEvent.Press,
        function(go)
            self._btnImg.sprite = self._atlas:GetSprite("shop_tuijian_btn14")
            self._btnTxt.color = Color(1, 1, 1, 1)
            if self._powerNotEnough then
                self._txtCost.color = Color.red
            else
                self._txtCost.color = Color(1, 1, 1, 1)
            end
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._btnImg.gameObject),
        UIEvent.Release,
        function(go)
            self._btnImg.sprite = self._atlas:GetSprite("shop_tuijian_btn13")
            self._btnTxt.color = Color(0, 0, 0, 1)
            if self._powerNotEnough then
                self._txtCost.color = Color.red
            else
                self._txtCost.color = Color(0, 0, 0, 1)
            end
        end
    )

    self._setCount = 1
    self._powerNotEnough = false
    self._matchType = uiParams[1]
    self._needPower = uiParams[2]
    self._doubleTicket = uiParams[3]
    self._uuid = uiParams[4]
    --一般情况下体力是棱镜, 活动关的体力可能是行动点, 这里传过来活动的行动点组件, 一旦不为nil, 则视为使用行动点
    ---@type ICampaignComponent
    self._pointComp = uiParams[5]
    --活动的关卡 传入活动类型
    self._campType = uiParams[6]

    if self._pointComp then
        local cmpID = self._pointComp:GetComponentCfgId()
        local pointCfg = self._pointComp:GetActionPointConfig()
        local itemCfg = Cfg.cfg_top_tips[pointCfg.ItemID]
        local phyIcon = self:GetUIComponent("Image", "btnIcon")
        phyIcon.sprite = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas):GetSprite(itemCfg.Icon)
        self._powerID = pointCfg.ItemID
        local camModule = self:GetModule(CampaignModule)
        local campID, tmpValue1, tmpValue2 = camModule:ParseCfgComponentID(cmpID)
        local campConfig = Cfg.cfg_campaign[campID]
        self._campType = campConfig.CampaignType
    else
        --体力的物品ID,正常情况下是棱镜
        self._powerID = RoleAssetID.RoleAssetPhyPoint
    end

    self:Apply()
    self:ChkAutoPick()

    --注册体力值更新的回调
    self:AttachEvent(GameEventType.RolePropertyChanged, self.ChangePhysicalPowerNumber)
end

function UISetAutoFightCountNew:BgOnClick()
    self:CloseDialog()
end

function UISetAutoFightCountNew:BtnGoOnClick()
    --体力不够打开恢复棱镜界面
    if self._powerNotEnough then
        if self._powerID == RoleAssetID.RoleAssetPhyPoint then
            self:ShowDialog("UIGetPhyPointController")
        else
            local name = StringTable.Get(Cfg.cfg_item[self._powerID].Name)
            ToastManager.ShowToast(StringTable.Get("str_activity_point_not_enough2", name))
        end
        return
    end

    self:CloseDialog()
    local campStageUI, campWaitUI = CampaignConst.GetCampaignAutoFightInfo(self._campType)
    --设置次数
    GameGlobal.GetModule(SerialAutoFightModule):SetSerialAutoFight(self._matchType, self._setCount, campWaitUI)
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
    elseif self._matchType == MatchType.MT_Campaign then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.FakeInput,
            {ui = campStageUI, input = "btnFightOnClick", args = {}}
        )
    elseif self._matchType == MatchType.MT_Season then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.FakeInput,
            {ui = campStageUI, input = "BtnFightOnClick", args = {}}
        )
    end
end

function UISetAutoFightCountNew:AddBtnOnClick()
    if self._setCount >= 99 then
        --已达上限
        ToastManager.ShowToast(StringTable.Get("str_common_max_num"))
        return
    end
    self._setCount = self._setCount + 1

    self:Apply()
end

function UISetAutoFightCountNew:SubBtnOnClick()
    if self._setCount <= 1 then
        --至少1次
        ToastManager.ShowToast(StringTable.Get("str_battle_serial_auto_fight_min_count"))
        return
    end
    self._setCount = self._setCount - 1

    self:Apply()
end

function UISetAutoFightCountNew:Apply()
    local power = self._needPower * self._setCount
    if self._doubleTicket > 0 then
        --双倍券数量
        local ticket = self._setCount
        local iiTicket = self._setCount * 2
        if self._doubleTicket <= self._setCount then
            ticket = self._doubleTicket
            iiTicket = self._doubleTicket * 2
        end
        power = self._needPower * (iiTicket + self._setCount)
        self._txtDouble.gameObject:SetActive(true)
        self._txtDouble:SetText(StringTable.Get("str_battle_use_double_ticket", ticket))
    end
    --体力消耗
    self._txtCost:SetText(tostring(power))
    --自动战斗次数
    self._txtCount:SetText(tostring(self._setCount))
    self._txtCountShadow:SetText(tostring(self._setCount))
    
    --获取体力
    local md = GameGlobal.GetModule(RoleModule)
    local assetCnt = md:GetAssetCount(self._powerID)
    if power > assetCnt then
        self._txtCost.color = Color(1, 0, 0, 1)
        self._powerNotEnough = true
    else
        self._txtCost.color = Color(0, 0, 0, 1)
        self._powerNotEnough = false
    end
end

function UISetAutoFightCountNew:ChangePhysicalPowerNumber(num)
    self:Apply()
end

function UISetAutoFightCountNew:GetMatchType()
    return self._matchType
end

function UISetAutoFightCountNew:GetNeedPower()
    return self._needPower
end

function UISetAutoFightCountNew:GetDoubleTicket()
    return self._doubleTicket
end

function UISetAutoFightCountNew:GetUuid()
    return self._uuid
end

function UISetAutoFightCountNew:ChkAutoPick()
    self._txtTitle = self:GetUIComponent("UILocalizationText", "title")
    self._uiSetting = self:GetUIComponent("RectTransform", "setting")
    self._uiAutoPick = self:GetUIComponent("RectTransform", "uiAutoPick")

    local aps = GameGlobal.GetModule(SerialAutoFightModule):GetApsData()
    local isEnable = aps:IsEnable(true)

    -- layout
    if not isEnable then
        self._txtTitle.transform.anchoredPosition = Vector2(0, 167)
        self._uiSetting.anchoredPosition = Vector2(1, 35)
        self._btnImg.transform.anchoredPosition = Vector2(0, -138)
    else
        self._txtTitle.transform.anchoredPosition = Vector2(0, 176)
        self._uiSetting.anchoredPosition = Vector2(1, -55)
        self._btnImg.transform.anchoredPosition = Vector2(0, -160)
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