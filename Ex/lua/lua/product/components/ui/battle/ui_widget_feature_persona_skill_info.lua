_class("UIWidgetFeaturePersonaSkillInfo", UICustomWidget)
---@class UIWidgetFeaturePersonaSkillInfo:UICustomWidget
UIWidgetFeaturePersonaSkillInfo = UIWidgetFeaturePersonaSkillInfo

function UIWidgetFeaturePersonaSkillInfo:OnShow()
    --以下是根据美术图配的三个高度，需要根据字数，动态设置背景图的高度
    self.oneLineHeight = 154
    self.twoLineHeight = 176
    self.threeLineHeight = 189

    --单行最大的像素数
    self.lineMaxWidth = 678
    local sop = self:GetUIComponent("UISelectObjectPath", "preattack")
    sop:SpawnObject("UIPreAttackItem")
    self.preAttackCell = sop:GetAllSpawnList()[1]
    self.preAttackCell:Enable(false)

end

function UIWidgetFeaturePersonaSkillInfo:ShowPreAttack()
    if self.preAttackCell then
        self.preAttackCell:SetData(self.petPstId, self.skillID, false)
    end
end

function UIWidgetFeaturePersonaSkillInfo:OnHide()
    self._cannotCastReason = nil
end

function UIWidgetFeaturePersonaSkillInfo:ResetSkillCanCast()
    self._cannotCastReason = nil
end

function UIWidgetFeaturePersonaSkillInfo:Init(featureType,skillID, maxEnergy, leftEnergy, canCast, castCallback,cancelCallBack)
    self.featureType = featureType
    self.skillID = skillID

    self.leftPower = leftEnergy
    self.castCallback = castCallback
    self.cancelCallBack = cancelCallBack
    local skillName = self:GetUIComponent("UILocalizationText", "skillName")
    ---@type UILocalizedTMP
    local skillDesc = self:GetUIComponent("UILocalizedTMP", "skillDesc")
    ---@type UnityEngine.RectTransform
    local bgRectTransform = self:GetUIComponent("RectTransform", "bg")
    ---@type UILocalizationText
    local skillCD = self:GetUIComponent("UILocalizationText", "skillCD")

    local btnGo = self:GetUIComponent("Button", "btnGo")
    local txtGo = self:GetUIComponent("UILocalizationText", "txtGo")
    self._castBtn = btnGo

    self.canCast = canCast
    self:ShowPreAttack()
    if canCast then
        btnGo.interactable = true
        txtGo.color = Color.white
    else
        btnGo.interactable = false
        txtGo.color = Color(123 / 255, 123 / 255, 123 / 255, 1)
    end

    ---@type SkillConfigData
    local skillData = ConfigServiceHelper.GetSkillConfigData(self.skillID)

    skillName:SetText(StringTable.Get(skillData:GetSkillName()))
    if skillData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy then
        skillCD.gameObject:SetActive(false)
    else
        skillCD.gameObject:SetActive(true)
        local MaxPower = skillData:GetSkillTriggerParam()
        local cdOff = BattleStatHelper.GetAllFeatureSkillCdOff()
        local specificCdOff = BattleStatHelper.GetSpecificFeatureSkillCdOff(self.featureType)
        MaxPower = MaxPower + cdOff + specificCdOff
        if MaxPower < 0 then
            MaxPower = 0
        end
        skillCD:SetText(string.format(StringTable.Get("str_common_cooldown_round"), MaxPower))
    end

    local mask = self:GetUIComponent("RevolvingTextWithDynamicScroll", "mask")
    mask:OnRefreshRevolving()

    local skillDescString = skillData:GetPetSkillDes()
    ---默认按照utf8，每个字符三个字节来算，后边优化可以考虑每个字符的宽度
    local skillDescUtf8Len = #skillDescString

    skillDesc:SetText(skillDescString)

    local skillInfo = self:GetGameObject("skillInfo")
    skillInfo:SetActive(true)

    --self:GetUIComponent("ContentSizeFitter", "bg"):SetLayoutVertical()
    UIHelper.RefreshLayout(self:GetUIComponent("RectTransform", "skillInfo"))

    ---@type UnityEngine.RectTransform
    -- local skillInfoTrans = bgRectTransform.parent.parent
    -- local isAdapteHead = InnerGameHelperRender.UICheckIsFifthPet(self.petPstId)
    -- local tmpPos = skillInfoTrans.anchoredPosition3D
    -- tmpPos.y = 0
    -- ---解决MSG30248[印尼语，选择吉纳维芙作为最后一名光灵出战，查看局内技能描述显示不全]
    -- if skillInfoTrans and isAdapteHead then
    --     local baseHeight = 170
    --     local heightDef = bgRectTransform.sizeDelta.y - baseHeight
    --     if heightDef > 0 then
    --         tmpPos.y = heightDef / 2
    --     end
    -- end
    -- skillInfoTrans.anchoredPosition3D = tmpPos

    self._cancelSkillInfo = self:GetGameObject("cancelSkillInfo")
    self._cancelSkillInfo:SetActive(false)

    -- local skillConfigData = ConfigServiceHelper.GetSkillConfigData(self.skillID)
    -- ---@type SkillPickUpType
    -- local pickUpType = skillConfigData:GetSkillPickType()

    --发动按钮在发动不需要选择格子的技能时可显示
    --btnGo.gameObject:SetActive(pickUpType == SkillPickUpType.None)
end

function UIWidgetFeaturePersonaSkillInfo:BtnGoOnClick()
    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        { ui = "UIWidgetFeaturePersonaSkillInfo", input = "btnGoOnClick", args = {} }
    )
    if (not self.canCast) then
        if not self:MissionCanCast() then
            local text = StringTable.Get("str_match_pickup_skill_limit")
            ToastManager.ShowToast(text)
        elseif not BattleStatHelper.CheckCanCastActiveSkill_TeamLeaderCondi(self.petPstId, self.skillID) then
            local text = StringTable.Get("str_battle_team_leader_active_skill_disabled")
            ToastManager.ShowToast(text)
        elseif self._cannotCastReason then
            local textKey = ActiveSkillCannotCastReasonText[self._cannotCastReason]
            local text = StringTable.Get(textKey)
            ToastManager.ShowToast(text)
        else
            local text = StringTable.Get("str_match_cannot_cast_skill_reason")
            ToastManager.ShowToast(text)
        end
    end

    if self.castCallback and self.canCast then
        ---@type SkillConfigData
        local skillConfigData = ConfigServiceHelper.GetSkillConfigData(self.skillID)
        ---@type SkillPickUpType
        local pickUpType = skillConfigData:GetSkillPickType()

        if self:MissionCanCast() then
            self.castCallback(self.skillID, pickUpType)
        else
            local text = StringTable.Get("str_match_pickup_skill_limit")
            ToastManager.ShowToast(text)
        end
    end
end

function UIWidgetFeaturePersonaSkillInfo:MissionCanCast()
    do
        return true--合击技无视关卡禁用
    end
    local matchModule = GameGlobal.GetModule(MatchModule)
    local enterData = matchModule:GetMatchEnterData()
    if enterData:GetMatchType() == MatchType.MT_Mission then
        local currentMissionId = enterData:GetMissionCreateInfo().mission_id
        local current_mission_cfg = Cfg.cfg_mission[currentMissionId]
        if current_mission_cfg == nil then
            return true
        end
        local missionCanCast = current_mission_cfg.CastSkillLimit
        return missionCanCast
    end
    return true
end

function UIWidgetFeaturePersonaSkillInfo:ShowCancelBtn(isShow)
    -- local skillInfo = self:GetGameObject("skillInfo")
    -- skillInfo:SetActive(false)

    self._cancelSkillInfo:SetActive(isShow)
end

function UIWidgetFeaturePersonaSkillInfo:GetCastSkillBtn()
    return self._castBtn
end

--获取技能ID
function UIWidgetFeaturePersonaSkillInfo:GetCurActiveSkillID()
    return self.skillID
end
function UIWidgetFeaturePersonaSkillInfo:CancelSkillBtnOnClick(go)
    if self.cancelCallBack then
        self.cancelCallBack()
    end
end