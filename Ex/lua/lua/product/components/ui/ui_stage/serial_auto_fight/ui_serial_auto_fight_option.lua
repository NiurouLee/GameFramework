---@class UISerialAutoFightOption:UIController
_class("UISerialAutoFightOption", UIController)
UISerialAutoFightOption = UISerialAutoFightOption

function UISerialAutoFightOption:GetParams()
    return {
        matchType = self._matchType,
        stageId = self._stageId,
        needPower = self._needPower,
        uuid = self._uuid,
        unlock = self._unlock,
        trackData = self._trackData,
        campParams = self._campParams
    }
end

function UISerialAutoFightOption:Constructor()
    self._titleState_One = 1 -- 只显示自动战斗
    self._titleState_Two = 2 -- 显示 自动战斗/扫荡 单选按钮
    self._titleStateWidget = { { "_title" }, { "_tabBtns" } }

    self._tabIndex_Sweep = 1 -- 扫荡页签按钮
    self._tabIndex_Fight = 2 -- 自动战斗页签按钮
    self._tabTitle = { "str_battle_auto_fight_option_title_sweep", "str_battle_auto_fight_option_title_fight" }
    self._tabWidget = { { "IntroBtn", "_costTicket" }, {} }

    self._target_Hide = 1 -- 不显示目标
    self._target_Show = 2 -- 显示目标
    self._targetWidget = {
        { "_bg1", "_space1_1",  "_space1_2" },
        { "_bg2", "_targetItem" }
    }
end

function UISerialAutoFightOption:OnShow(uiParams)
    self._powerID = RoleAssetID.RoleAssetPhyPoint
    self._needTicket = 1
    self._fightCount = 1

    self._tipsCallback = function(matid, pos)
        UIWidgetHelper.SetAwardItemTips(self, "_tipsPool", matid, pos)
    end

    self._matchType = uiParams[1]
    self._stageId = uiParams[2]
    self._needPower = uiParams[3]
    self._uuid = uiParams[4]
    self._unlock = uiParams[5]
    self._trackData = uiParams[6] -- SerialAutoFightJumpData._jumpTo.data

    self._campParams = uiParams[7]

    local toIndex = uiParams[8]

    if self._campParams then
        self._pointComp = self._campParams._pointComp
    end
    if self._pointComp then
        local cmpID = self._pointComp:GetComponentCfgId()
        local pointCfg = self._pointComp:GetActionPointConfig()
        local itemCfg = Cfg.cfg_top_tips[pointCfg.ItemID]
        UIWidgetHelper.SetImageSprite(self, "Icon", "UICommon.spriteatlas", itemCfg.Icon)
        self._powerID = pointCfg.ItemID
    else
        --体力的物品ID,正常情况下是棱镜
        self._powerID = RoleAssetID.RoleAssetPhyPoint
    end
    if self._campParams and self._campParams._campType then
        self._campType = self._campParams._campType
    end
    if self._campParams and self._campParams._forceTitleState then
        self._forceTitleState = self._campParams._forceTitleState
    end
    if self._campParams and self._campParams._needTicket then
        self._needTicket = self._campParams._needTicket
    end
    if self._campParams and self._campParams._componentId then
        self._componentId = self._campParams._componentId
    end
    if self._campParams and self._campParams._campaignMissionParams then
        self._campaignMissionParams = self._campParams._campaignMissionParams
    end

    self:_SetStyleUI(self._matchType)
    local titleState = self:_SetTitleState()
    self:_SetTargetState(self._trackData)

    self._tabIndex = self:_CalcFirstIndex(titleState, self._unlock, toIndex)
    self:_SetTabBtns()
    self._tabBtns[self._tabIndex_Sweep]:SetLock(not self._unlock)

    self:_SetTabSelect(self._tabIndex)

    self:_RefreshUI()

    -- 记录信息
    ---@type SerialAutoFightJumpData
    local jumpData = GameGlobal.GetModule(SerialAutoFightModule):GetJumpData()
    jumpData:Track_Option(self:GetParams())

    self:_AttachEvents()
end

function UISerialAutoFightOption:OnHide()
    self:_DetachEvents()
end

--region state

function UISerialAutoFightOption:_SetStyleUI(matchType)
    local tb = {
        [MatchType.MT_Mission] = nil,
        [MatchType.MT_ResDungeon] = "dark",
        [MatchType.MT_Season] = "season"
    }
    self._styleName = tb[matchType]
    if self._styleName == nil then
        return
    end

    UISerialAutoFightStyleHelper.FitStyle_Widget(self._styleName, "bg_di05", self, "_bg1")
    UISerialAutoFightStyleHelper.FitStyle_Widget(self._styleName, "bg_di04", self, "_bg2")
    UISerialAutoFightStyleHelper.FitStyle_Widget(self._styleName, "di08", self, "_titleBg")
    UISerialAutoFightStyleHelper.FitStyle_Widget(self._styleName, "kuang03", self, "_fightCountBg")
    UISerialAutoFightStyleHelper.FitStyle_Widget(self._styleName, "optionColor", self, "_title")
    UISerialAutoFightStyleHelper.FitStyle_Widget(self._styleName, "optionColor", self, "_cost")
    UISerialAutoFightStyleHelper.FitStyle_Widget(self._styleName, "optionColor", self, "_costPowerCount")
    UISerialAutoFightStyleHelper.FitStyle_Widget(self._styleName, "optionColor", self, "_costTicketCount")
    UISerialAutoFightStyleHelper.FitStyle_Widget(self._styleName, "optionColor2", self, "_fightCountShadow")
    UISerialAutoFightStyleHelper.FitStyle_Widget(self._styleName, "optionFightBtnBg", self, "_fightBtnBg")
    UISerialAutoFightStyleHelper.FitStyle_Widget(self._styleName, "optionFightBtnImg", self, "_fightBtnImg")
end

function UISerialAutoFightOption:_SetTitleState()
    ---@type AircraftModule
    local aircraftModule = self:GetModule(AircraftModule)
    local room = aircraftModule:GetResRoom()
    local state = room and self._titleState_Two or self._titleState_One
    if self._forceTitleState then
        state = self._forceTitleState
    end
    local objs = UIWidgetHelper.GetObjGroupByWidgetName(self, self._titleStateWidget)
    UIWidgetHelper.SetObjGroupShow(objs, state)
    return state
end

function UISerialAutoFightOption:_SetTargetState(trackData)
    ---@type SerialAutoFightJumpData
    local jumpData = GameGlobal.GetModule(SerialAutoFightModule):GetJumpData()
    local isShow = jumpData:IsShowTargetItem(trackData)
    local state = isShow and self._target_Show or self._target_Hide
    local objs = UIWidgetHelper.GetObjGroupByWidgetName(self, self._targetWidget)
    UIWidgetHelper.SetObjGroupShow(objs, state)

    if isShow then
        local itemId, itemCondition = jumpData:GetTargetItem()
        self:_SetTargetItem(itemId, itemCondition)
    end
end

function UISerialAutoFightOption:_SetTabSelect(index)
    self._tabIndex = index

    for i = 1, #self._tabBtns do
        self._tabBtns[i]:SetSelected(i == index)
    end

    local objs = UIWidgetHelper.GetObjGroupByWidgetName(self, self._tabWidget)
    UIWidgetHelper.SetObjGroupShow(objs, index)
end

function UISerialAutoFightOption:_SetTabBtns()
    local title = self._tabTitle

    ---@type UIActivityCommonTextTabBtn[]
    self._tabBtns = UIWidgetHelper.SpawnObjects(self, "_tabBtns", "UIActivityCommonTextTabBtn", #title)
    for i, v in ipairs(self._tabBtns) do
        v:SetData(
            i,                                                                       -- 索引
            {
                indexWidgets = { { "bgOff_1", "bgOn_1" }, { "bgOff_2", "bgOn_2" } }, -- 与索引相关的状态组
                onoffWidgets = { { "OnBtn" }, { "OffBtn" } },                        -- 与是否选中相关的状态组 [1] = 选中 [2] = 非选中
                lockWidgets = { { "iconLock" }, {} },                                -- 与是否锁定相关的状态组 [1] = 锁定 [2] = 正常
                titleWidgets = { "txtTitle_off", "txtTitle_on" },                    -- 标题列表组
                titleText = StringTable.Get(title[i]),                               -- 标题文字
                callback = function(index, isOffBtnClick)                            -- 点击按钮回调
                    if isOffBtnClick then
                        self:_SetTabSelect(index)
                        self:_RefreshUI()
                    end
                end,
                lockCallback = function()
                    ToastManager.ShowToast(StringTable.Get("str_battle_auto_needStar"))
                end
            }
        )
        UISerialAutoFightStyleHelper.FitStyle_Widget(self._styleName, "optionTabBtnOff1", v, "bgOff_1")
        UISerialAutoFightStyleHelper.FitStyle_Widget(self._styleName, "optionTabBtnOn1", v, "bgOn_1")
        UISerialAutoFightStyleHelper.FitStyle_Widget(self._styleName, "optionTabBtnOff2", v, "bgOff_2")
        UISerialAutoFightStyleHelper.FitStyle_Widget(self._styleName, "optionTabBtnOn2", v, "bgOn_2")

        UISerialAutoFightStyleHelper.FitStyle_Widget(self._styleName, "optionTitleColorOff", v, "txtTitle_off")
        UISerialAutoFightStyleHelper.FitStyle_Widget(self._styleName, "optionTitleColorOn", v, "txtTitle_on")
    end
end

--endregion

--region ui

function UISerialAutoFightOption:_RefreshUI()
    self:_SetFightCount(self._fightCount)
    self:_SetCostPower(self._fightCount)
    self:_SetCostTicket(self._fightCount)
end

function UISerialAutoFightOption:_SetTargetItem(itemId, itemCondition)
    ---@type UISerialAutoFightSweepResultTargetItem
    local obj = UIWidgetHelper.SpawnObject(self, "_targetItemPool", "UISerialAutoFightSweepResultTargetItem")
    obj:SetStyleUI(self._styleName)
    obj:SetData(1, itemId, itemCondition, self._tipsCallback)
end

function UISerialAutoFightOption:_SetFightCount(count)
    UIWidgetHelper.SetLocalizationText(self, "_fightCount", count)
    UIWidgetHelper.SetLocalizationText(self, "_fightCountShadow", count)
end

function UISerialAutoFightOption:_SetCostPower(count)
    local n, t = self:_CalcPower(count)
    self:_SetChangeColorText("_costPowerCount", n, t)
end

function UISerialAutoFightOption:_SetCostTicket(count)
    local n, t = self:_CalcTicket(count)
    self:_SetChangeColorText("_costTicketCount", n, t)
    if self._needTicket <= 0 then --不需要票时隐藏
        local objs = UIWidgetHelper.GetObjGroupByWidgetName(self, self._tabWidget)
        UIWidgetHelper.SetObjGroupShow(objs, 2)
    end
end

function UISerialAutoFightOption:_SetChangeColorText(widgetName, n, t)
    local tc = (n <= t) and t or UIActivityHelper.GetColorText("#FF0000", t)
    UIWidgetHelper.SetLocalizationText(self, widgetName, tc .. "/" .. n)
end

--endregion

--region ui logic

function UISerialAutoFightOption:_CalcFirstIndex(titleState, unlock, param)
    if titleState == self._titleState_One or (not unlock) then
        return self._tabIndex_Fight
    end

    local n, t = self:_CalcTicket(1)
    local index = self._tabIndex_Fight
    if n > 0 then --需要消耗携行者
        index = (t > 0) and self._tabIndex_Sweep or self._tabIndex_Fight
    else
        index = self._tabIndex_Sweep
    end

    -- if param == self._tabIndex_Sweep and index == self._tabIndex_Sweep then
    --     return param
    -- end

    return index
end

function UISerialAutoFightOption:_CalcFightCount(newCount)
    local min, max = 1, 99

    local err = (newCount < min) and "str_battle_serial_auto_fight_min_count" or nil
    err = (newCount > max) and "str_common_max_num" or err
    if not string.isnullorempty(err) then
        ToastManager.ShowToast(StringTable.Get(err))
        return
    end

    self._fightCount = Mathf.Clamp(newCount, min, max)

    self:_RefreshUI()
end

function UISerialAutoFightOption:_CalcMinCount()
    local min, max = 1, 99
    return min
end

function UISerialAutoFightOption:_CalcMaxCount()
    local min, max = 1, 99

    local n, t = self:_CalcPower(1)
    local pCount = (n <= 0) and max or (t / n)
    local tCount = max
    if self._tabIndex == self._tabIndex_Sweep then
        local n, t = self:_CalcTicket(1)
        tCount = t / n
    end

    local count = Mathf.Floor(Mathf.Min(pCount, tCount))
    return Mathf.Clamp(count, min, max)
end

function UISerialAutoFightOption:_CalcPower(count)
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local total = roleModule:GetAssetCount(self._powerID)
    local need = count * self._needPower
    return need, total
end

function UISerialAutoFightOption:_CalcTicket(count)
    ---@type ResDungeonModule
    local resModule = self:GetModule(ResDungeonModule)
    local total = resModule:GetDoubleResNum()
    local need = count * self._needTicket
    return need, total
end

--endregion

--region auto fight logic

function UISerialAutoFightOption:_CheckPower()
    local n, t = self:_CalcPower(self._fightCount)
    if (n <= t) then
        return true
    end

    if self._powerID == RoleAssetID.RoleAssetPhyPoint then
        self:ShowDialog("UIGetPhyPointController")
    else
        local name = StringTable.Get(Cfg.cfg_item[self._powerID].Name)
        ToastManager.ShowToast(StringTable.Get("str_activity_point_not_enough2", name))
    end
    return false
end

function UISerialAutoFightOption:_CheckTicket()
    local n, t = self:_CalcTicket(self._fightCount)
    if (n <= t) then
        return true
    end

    ToastManager.ShowToast(StringTable.Get("str_battle_auto_fight_sweep_msg_desc"))
    return false
end

function UISerialAutoFightOption:_DoAutoFight()
    ---@type SerialAutoFightModule
    local serialAutoFightModule = GameGlobal.GetModule(SerialAutoFightModule)
    local campStageUI, campWaitUI = CampaignConst.GetCampaignAutoFightInfo(self._campType)
    --设置次数
    serialAutoFightModule:SetSerialAutoFight(self._matchType, self._fightCount, campWaitUI)
    --进入编队界面
    if self._matchType == MatchType.MT_Mission then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.FakeInput,
            { ui = "UIStage", input = "btnFightOnClick", args = {} }
        )
    elseif self._matchType == MatchType.MT_ResDungeon then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.FakeInput,
            { ui = "UIResDetailInfoCell", uiid = self._uuid, input = "btngoOnClick", args = {} }
        )
    elseif self._matchType == MatchType.MT_Campaign then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.FakeInput,
            { ui = campStageUI, input = "btnFightOnClick", args = {} }
        )
    elseif self._matchType == MatchType.MT_Season then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.FakeInput,
            { ui = campStageUI, input = "BtnFightOnClick", args = {} }
        )
    end
end

function UISerialAutoFightOption:_DoAutoSweep()
    self:ShowDialog("UISerialAutoFightSweepResult",
        self._styleName, self._matchType, self._stageId, self._fightCount, self._trackData, self._componentId,
        self._campaignMissionParams)
end

--endregion


--region event

function UISerialAutoFightOption:BgOnClick()
    self:_CloseDialogWithAnim()
end

function UISerialAutoFightOption:FightBtnOnClick()
    if self._tabIndex == self._tabIndex_Fight then -- 自动战斗
        if not self:_CheckPower() then
            return
        end

        self:_CloseDialogWithAnim(function()
            self:_DoAutoFight()
        end)
    elseif self._tabIndex == self._tabIndex_Sweep then -- 扫荡
        if not self:_CheckTicket() then
            return
        end
        if not self:_CheckPower() then
            return
        end

        self:_CloseDialogWithAnim(function()
            self:_DoAutoSweep()
        end)
    end
end

function UISerialAutoFightOption:MinBtnOnClick()
    local newCount = self:_CalcMinCount()
    self:_CalcFightCount(newCount)
end

function UISerialAutoFightOption:SubBtnOnClick()
    local newCount = self._fightCount - 1
    self:_CalcFightCount(newCount)
end

function UISerialAutoFightOption:AddBtnOnClick()
    local newCount = self._fightCount + 1
    self:_CalcFightCount(newCount)
end

function UISerialAutoFightOption:MaxBtnOnClick()
    local newCount = self:_CalcMaxCount()
    self:_CalcFightCount(newCount)
end

function UISerialAutoFightOption:IntroBtnOnClick()
    self:ShowDialog("UISetAutoFightIntroduce")
end

--endregion

--region AttachEvent

function UISerialAutoFightOption:_AttachEvents()
    --注册体力值更新的回调
    self:AttachEvent(GameEventType.RolePropertyChanged, self._RefreshUI)
    self:AttachEvent(GameEventType.ItemCountChanged, self._RefreshUI)
end

function UISerialAutoFightOption:_DetachEvents()
    self:DetachEvent(GameEventType.RolePropertyChanged, self._RefreshUI)
    self:DetachEvent(GameEventType.ItemCountChanged, self._RefreshUI)
end

--endregion

function UISerialAutoFightOption:_CloseDialogWithAnim(callback)
    UIWidgetHelper.PlayAnimation(self, "_anim", "uieff_UISerialAutoFightOption_out", 200, function()
        if callback then
            callback()
        end
        self:CloseDialog()
    end)
end
