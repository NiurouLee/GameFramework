_class("UIWidgetPetSkill", UICustomWidget)
---@class UIWidgetPetSkill:UICustomWidget
UIWidgetPetSkill = UIWidgetPetSkill

function UIWidgetPetSkill:OnShow()
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

    self:AttachEvent(GameEventType.BattleUIRefreshActiveSkillCastButtonState, self._RefreshCastButtonState)

    self.activeSkillCheckPass = true

    ---@type UnityEngine.GameObject
    self._objEquipRefineUpPos = self:GetGameObject("objEquipRefineUpPos")
    ---@type UnityEngine.GameObject
    self._objEquipRefineDownPos = self:GetGameObject("objEquipRefineDownPos")
end
function UIWidgetPetSkill:HideSelf()
    self._isShow = false
    self:GetGameObject():SetActive(false)
end
function UIWidgetPetSkill:ShowSelf()
    self._isShow = true
    self:GetGameObject():SetActive(true)
end
function UIWidgetPetSkill:SetUiPos(position)
    self:GetGameObject().transform.position = position
end
function UIWidgetPetSkill:GetPetSkillBtn()
    local btn = self:GetGameObject("btnGo")
    return btn
end

function UIWidgetPetSkill:SetPetPstId(petPstId)
    self.petPstId = petPstId
    ---@type MatchEnterData
    local enterData = GameGlobal.GetModule(MatchModule):GetMatchEnterData()
    local matchPets = enterData:GetLocalMatchPets()
    self.pet = matchPets[self.petPstId]
end

function UIWidgetPetSkill:SetPet(pet)
    ---@type MatchPet
    self.pet = pet
end

function UIWidgetPetSkill:ShowPreAttack()
    if self.preAttackCell then
        self.preAttackCell:SetData(self.petPstId, self.skillID, false)
    end
end

function UIWidgetPetSkill:OnHide()
    self.activeSkillCheckPass = true
    self._cannotCastReason = nil
end

function UIWidgetPetSkill:ResetSkillCanCast()
    self.activeSkillCheckPass = true
    self._cannotCastReason = nil
end

function UIWidgetPetSkill:Init(skillID, maxEnergy, leftEnergy, canCast, castCallback, petPstID)
    self.skillID = skillID

    self.leftPower = leftEnergy
    self.castCallback = castCallback
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
    local skillData = ConfigServiceHelper.GetSkillConfigData(self.skillID, petPstID)

    skillName:SetText(StringTable.Get(skillData:GetSkillName()))
    if UILogicPetHelper.ShowSkillEnergy(skillData:GetSkillTriggerType()) then
        skillCD.gameObject:SetActive(true)
        skillCD:SetText(string.format(StringTable.Get("str_common_cooldown_round"), skillData:GetSkillTriggerParam()))
    else
        skillCD.gameObject:SetActive(false)
    end

    local mask = self:GetUIComponent("RevolvingTextWithDynamicScroll", "mask")
    mask:OnRefreshRevolving()

    --杰诺 san消耗递增
    local descForceParam = {}
    local extraParam = skillData:GetSkillTriggerExtraParam()
    if extraParam and extraParam[SkillTriggerTypeExtraParam.SanChangeByRoundCastTimes] then
        local baseCost = extraParam[SkillTriggerTypeExtraParam.SanValue]
        local modCost = extraParam[SkillTriggerTypeExtraParam.SanChangeByRoundCastTimes]
        local curTimes = BattleStatHelper.GetCurRoundDoActiveSkillTimes(self.petPstId)
        local curCost = baseCost + (modCost * curTimes)
        table.insert(descForceParam,tostring(curCost))
    end
    local skillDescString = skillData:GetPetSkillDes(descForceParam)
    ---默认按照utf8，每个字符三个字节来算，后边优化可以考虑每个字符的宽度
    local skillDescUtf8Len = #skillDescString

    -- local skillDescLen = skillDescUtf8Len / 3
    -- local skillDescWidth = skillDescLen * 28

    -- local lineNum = skillDescWidth / self.lineMaxWidth
    -- lineNum = math.ceil(lineNum)

    -- local targetHeight = self.threeLineHeight
    -- if lineNum == 1 then
    --     targetHeight = self.oneLineHeight
    -- elseif lineNum == 2 then
    --     targetHeight = self.twoLineHeight
    -- elseif lineNum == 3 then
    --     targetHeight = self.threeLineHeight
    -- end
    self.skillDesc = skillDesc
    if not self:CheckRefineSkillReplace(self.skillID) then
        skillDesc:SetText(skillDescString)
    end

    local skillInfo = self:GetGameObject("skillInfo")
    skillInfo:SetActive(true)

    --self:GetUIComponent("ContentSizeFitter", "bg"):SetLayoutVertical()
    UIHelper.RefreshLayout(self:GetUIComponent("RectTransform", "skillInfo"))

    ---@type UnityEngine.RectTransform
    local skillInfoTrans = bgRectTransform.parent.parent
    local isAdapteHead = InnerGameHelperRender.UICheckIsFifthPet(self.petPstId)
    local tmpPos = skillInfoTrans.anchoredPosition3D
    tmpPos.y = 0
    ---解决MSG30248[印尼语，选择吉纳维芙作为最后一名光灵出战，查看局内技能描述显示不全]
    if skillInfoTrans and isAdapteHead then
        local baseHeight = 170
        local heightDef = bgRectTransform.sizeDelta.y - baseHeight
        if heightDef > 0 then
            tmpPos.y = heightDef / 2
        end
    end
    skillInfoTrans.anchoredPosition3D = tmpPos

    local cancelSkillInfo = self:GetGameObject("cancelSkillInfo")
    cancelSkillInfo:SetActive(false)

    local skillConfigData = ConfigServiceHelper.GetSkillConfigData(self.skillID)
    ---@type SkillPickUpType
    local pickUpType = skillConfigData:GetSkillPickType()

    --发动按钮在发动不需要选择格子的技能时可显示
    --btnGo.gameObject:SetActive(pickUpType == SkillPickUpType.None)
end

function UIWidgetPetSkill:btnGoOnClick()
    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        { ui = "UIWidgetPetSkill", input = "btnGoOnClick", args = {} }
    )
    if (not self.canCast) or (not self.activeSkillCheckPass) then
        local reasonByBuffSetCanNotReadyReason = BattleStatHelper.CheckCanCastActiveSkill_GetCantReadyReasonByBuff(self.petPstId,self.skillID)
        if not self:MissionCanCast() then
            local text = StringTable.Get("str_match_pickup_skill_limit")
            ToastManager.ShowToast(text)
        elseif reasonByBuffSetCanNotReadyReason then
            local textKey = ActiveSkillCannotCastReasonText[reasonByBuffSetCanNotReadyReason]
            local text = StringTable.Get(textKey)
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

    -- 技能效果逻辑有处理，如果选取无效硬放，最后会放一个空技能
    if not BattleStatHelper.CheckCanCastActiveSkill_SwapPetTeamOrder(self.petPstId, self.skillID) then
        local text = StringTable.Get("str_battle_hebo_cannot_change_pos_with_cursed_pet")
        ToastManager.ShowToast(text)
        return
    end

    if self.castCallback and self.canCast and self.activeSkillCheckPass then
        -- TODO: 阿克希亚扫描模块处理
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

function UIWidgetPetSkill:MissionCanCast()
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

function UIWidgetPetSkill:ShowCancelBtn(isShow)
    local skillInfo = self:GetGameObject("skillInfo")
    skillInfo:SetActive(false)

    local cancelSkillInfo = self:GetGameObject("cancelSkillInfo")
    cancelSkillInfo:SetActive(isShow)
end

function UIWidgetPetSkill:GetCastSkillBtn()
    return self._castBtn
end

--获取技能ID
function UIWidgetPetSkill:GetCurActiveSkillID()
    return self.skillID
end

function UIWidgetPetSkill:_RefreshCastButtonState(result, reason)
    if self._isShow then
        self.activeSkillCheckPass = result
        self._cannotCastReason = reason
        self._castBtn.interactable = result
    end
end

---@return UnityEngine.GameObject
function UIWidgetPetSkill:GetEquipRefineUpPosObj()
    return self._objEquipRefineUpPos
end

---@return UnityEngine.GameObject
function UIWidgetPetSkill:GetEquipRefineDownPosObj()
    return self._objEquipRefineDownPos
end

function UIWidgetPetSkill:CheckRefineSkillReplace(skillId)
    if not self.pet or not skillId then
        return false
    end
    
    local refineLv = self.pet:GetEquipRefineLv()
    if refineLv < 1 then
        return false
    end
    
    local refineConfig = UIPetEquipHelper.GetRefineCfg(self.pet:GetTemplateID(), refineLv)
    if not refineConfig then
        return false
    end

    local replaceData = refineConfig.SubstituteSkillDesc
    if not  replaceData then
        return false
    end

    local newDesc
    for k, v in pairs(replaceData) do
        newDesc = v[skillId]
        if newDesc and newDesc ~= "" then
            break
        end
    end

    if newDesc then
        self.skillDesc:SetText(StringTable.Get(newDesc))
        return true
    end

    return false
end