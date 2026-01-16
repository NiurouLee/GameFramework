_class("UIWidgetTrapSkill", UICustomWidget)
---@class UIWidgetTrapSkill:UICustomWidget
UIWidgetTrapSkill = UIWidgetTrapSkill

function UIWidgetTrapSkill:Constructor()
    self._selectIndex = {}
end

function UIWidgetTrapSkill:OnShow()
    --允许模拟输入
    self.enableFakeInput = true

    self._root = self:GetGameObject("root")
    self._selectRect = self:GetUIComponent("RectTransform", "root")

    self._skillName = self:GetUIComponent("UILocalizationText", "skillName")
    self._revolvingTextName = self:GetUIComponent("RevolvingTextWithDynamicScroll", "RevolvingTextName")
    self._skillDesc = self:GetUIComponent("UILocalizationText", "skillDesc")
    self._skillCD = self:GetUIComponent("UILocalizationText", "skillCD")
    self._revolvingTextCD = self:GetUIComponent("RevolvingTextWithDynamicScroll", "RevolvingTextCD")

    self._btnGo = self:GetUIComponent("Button", "btnGo")
    local txtGo = self:GetUIComponent("UILocalizationText", "txtGo")

    self._uiSkillListRoot = self:GetUIComponent("UISelectObjectPath", "skillListRoot")
    self._uiSkillListRootRect = self:GetUIComponent("RectTransform", "skillListRoot")

    self._isSummonLimit = false
end
function UIWidgetTrapSkill:OnHide()
end

function UIWidgetTrapSkill:Init(trapEntityID)
    self._entityID = trapEntityID

    if not self._selectIndex[self._entityID] then
        self._selectIndex[self._entityID] = 1
    end

    self:GetGameObject():SetActive(true)

    self._isAutoFighting = BattleStatHelper.GetAutoFightStat()

    local pos = InnerGameHelperRender.CalcUIPos(trapEntityID)
    if pos then
        self._selectRect.anchoredPosition = pos
    end
    local skillList = InnerGameHelperRender.GetTrapActiveSkillList(trapEntityID)
    self:_OnRefreshTrapSkillInfo(skillList)
end

function UIWidgetTrapSkill:_OnRefreshTrapSkillInfo(skillList)
    self._uiSkillListRoot:SpawnObjects("UIWidgetTrapSkillItem", #skillList)

    --根据技能数量修改布局
    if table.count(skillList) <= 3 then
        self._uiSkillListRootRect.sizeDelta = Vector2(360, 120)
        self._uiSkillListRootRect.anchoredPosition = Vector2(-15, 56)
    else
        self._uiSkillListRootRect.sizeDelta = Vector2(480, 120)
        self._uiSkillListRootRect.anchoredPosition = Vector2(-70, 56)
    end

    local uiSkillList = self._uiSkillListRoot:GetAllSpawnList()
    self.items = uiSkillList
    for i = 1, #skillList do
        ---@type UIWidgetTrapSkillItem
        local uiSkillItem = uiSkillList[i]

        uiSkillItem:GetGameObject():SetActive(i <= #skillList)
        if i <= #skillList then
            uiSkillItem:Init(
                i,
                skillList[i],
                function(index)
                    self._selectIndex[self._entityID] = index

                    --ui
                    for i = 1, #uiSkillList do
                        ---@type UIWidgetTrapSkillItem
                        local uiSkillIem = uiSkillList[i]
                        local canCast = self:_OnGetCanCastSkill(skillList[i])
                        uiSkillIem:OnSelect(i == index, canCast)
                    end
                    self:_OnShowSelectSkill(skillList[index])
                end
            )
        end
    end

    uiSkillList[self._selectIndex[self._entityID]]:buttonBgOnClick(nil)
end

function UIWidgetTrapSkill:_OnShowSelectSkill(skillId)
    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        {ui = "UIWidgetTrapSkill", input = "_OnShowSelectSkill", args = {skillId}}
    )
    self._skillId = skillId

    local cfgSkillInfo = BattleSkillCfg(self._skillId)

    --ui
    local strName = StringTable.Get(cfgSkillInfo.Name)
    --在技能名字的后面，是否显示技能消耗能量值
    local showSkillCostPower = InnerGameHelperRender.GetTrapAttribute(self._entityID, "ShowSkillCostPower")
    if showSkillCostPower == 1 then
        local strSkillCostPower = StringTable.Get("str_trap_cost_trap_power", cfgSkillInfo.TriggerParam)
        strName = strName .. strSkillCostPower
    end

    self._skillName:SetText(strName)
    self._revolvingTextName:OnRefreshRevolving()

    --机关本回合可以释放技能的次数
    local canCastSkillCount = InnerGameHelperRender.GetTrapCurRoundCanCastSkillCount(self._entityID)
    --一回合限制使用机关技能次数
    local oneRoundLimit = InnerGameHelperRender.GetTrapAttribute(self._entityID, "OneRoundLimit")
    if oneRoundLimit == 1 then
        --如果是1回合限制用1次，显示CD
        self._skillCD:SetText(string.format(StringTable.Get("str_common_cooldown_round"), cfgSkillInfo.TriggerParam))
    elseif oneRoundLimit == 99 then
        self._skillCD:SetText(string.format(StringTable.Get("str_common_cooldown_round"), 0))
    else
        --如果次数大于1，关闭CD图标，显示剩余可以使用次数
        self._skillCD:SetText(StringTable.Get("str_trap_can_cast_count", canCastSkillCount))
    end
    self._revolvingTextCD:OnRefreshRevolving()

    self._skillDesc:SetText(StringTable.Get(cfgSkillInfo.Desc))

    --可以释放次数大于0  and   当前能量大于技能消耗能量
    self._canCast = self:_OnGetCanCastSkill(self._skillId)
    self._btnGo.interactable = self._canCast
    self._isSummonLimit = self:_IsSummonCountLimit(self._skillId)

    --技能预览
    local coreGameStateID = GameGlobal:GetInstance():CoreGameStateID()
    local enableInput = GameGlobal:GetInstance():IsInputEnable()
    if coreGameStateID == GameStateID.WaitInput and enableInput == true then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.HideCanMoveArrow)
    elseif coreGameStateID == GameStateID.PreviewActiveSkill or coreGameStateID == GameStateID.PickUpActiveSkillTarget then
        --切换预览预览  要先取消上一次的显示
        GameGlobal.EventDispatcher():Dispatch(GameEventType.StopPreviewActiveSkill, true, false)
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.PreClickPetHead, self._skillId, true)
    -- GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickPetHead, self._skillId, 0, true)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickTrapHead, self._skillId, self._entityID, true)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.TrapPowerVisible, false)
end

function UIWidgetTrapSkill:_OnGetCanCastSkill(skillID)
    if not skillID then
        return false
    end
    local cfgSkillInfo = BattleSkillCfg(skillID)
    --机关本回合可以释放技能的次数
    local canCastSkillCount = InnerGameHelperRender.GetTrapCurRoundCanCastSkillCount(self._entityID)
    local trapPower = InnerGameHelperRender.GetTrapAttribute(self._entityID, "TrapPower")

    --技能是否是召唤机关技能，若是，则需判断是否达到召唤数量上限
    local canCastByLimitCount = not self:_IsSummonCountLimit(skillID)

    --可以释放次数大于0  and   当前能量大于技能消耗能量 and 召唤机关数量未达到上限
    local canCast = canCastSkillCount > 0 and trapPower >= cfgSkillInfo.TriggerParam and canCastByLimitCount
    return canCast
end

function UIWidgetTrapSkill:_IsSummonCountLimit(skillID)
    local cfgSkillInfo = BattleSkillCfg(skillID)
    --技能是否是召唤机关技能，若是，则需判断是否达到召唤数量上限
    local isLimit = false
    if cfgSkillInfo.Tag and table.icontains(cfgSkillInfo.Tag, PetSkillTag.SummonTrap) then
        isLimit = InnerGameHelperRender.IsTrapSummonCountLimit(self._entityID)
    end

    return isLimit
end

function UIWidgetTrapSkill:btnGoOnClick(go)
    if not self._canCast then
        if self._isSummonLimit then
            ToastManager.ShowToast(StringTable.Get("str_battle_trap_summon_limit"))
        end
        return
    end

    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        {ui = "UIWidgetTrapSkill", input = "btnGoOnClick", args = {}}
    )

    local skillConfigData = ConfigServiceHelper.GetSkillConfigData(self._skillId)
    ---@type SkillPickUpType
    local pickUpType = skillConfigData:GetSkillPickType()
    if pickUpType == SkillPickUpType.None then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.CastActiveSkillNoPet, self._skillId, self._entityID)
    elseif pickUpType == SkillPickUpType.Instruction or pickUpType == SkillPickUpType.PickAndDirectionInstruction then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, false)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActiveSkillPickUp, self._skillId, self._entityID)

        --UIBattle的显示选择几个点
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.ShowActiveSkillChooseUI,
            self._skillId,
            pickUpType,
            self._entityID,
            self._canCast
        )
    end

    self:GetGameObject():SetActive(false)
end

function UIWidgetTrapSkill:btnCloseOnClick(go)
    --自动战斗不能取消技能释放
    if self._isAutoFighting then
        return
    end
    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        {ui = "UIWidgetTrapSkill", input = "btnCloseOnClick", args = {}}
    )
    self:GetGameObject():SetActive(false)

    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowCanMoveArrow)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.StopPreviewActiveSkill, false, true)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.PreClickPetHead, -1)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.TrapPowerVisible, true)
end

function UIWidgetTrapSkill:GetTrapSkillIcon(index)
    return self.items and self.items[index] and self.items[index]:GetGameObject("canCast")
end
