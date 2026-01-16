---多技能 技能板

_class("UIWidgetPetMultiActiveSkill", UICustomWidget)
---@class UIWidgetPetMultiActiveSkill:UICustomWidget
UIWidgetPetMultiActiveSkill = UIWidgetPetMultiActiveSkill

--显示
function UIWidgetPetMultiActiveSkill:OnShow()
    self.enableFakeInput = true
    ---@type UnityEngine.U2D.SpriteAtlas
    self._uiBattleAtlas = self:GetAsset("UIBattle.spriteatlas", LoadType.SpriteAtlas)
    --先制攻击
    local sop = self:GetUIComponent("UISelectObjectPath", "preattack")
    sop:SpawnObject("UIPreAttackItem")
    ---@type UIPreAttackItem
    self._preAttackCell = sop:GetAllSpawnList()[1]
    self._preAttackCell:Enable(false)

    --发动按钮
    self._btnGo = self:GetUIComponent("Button", "btnGo")
    self._castBtn = self._btnGo
    self._txtGo = self:GetUIComponent("UILocalizationText", "txtGo")

    --子技能列表
    self._skillListRoot = self:GetUIComponent("UISelectObjectPath", "skillListRoot")
    self._skillListRootRect = self:GetUIComponent("RectTransform", "skillListRoot")


    self._txtSkillName = self:GetUIComponent("UILocalizationText", "skillName")
    self._tmpSkillDesc = self:GetUIComponent("UILocalizedTMP", "skillDesc")
    self._rectBg = self:GetUIComponent("RectTransform", "bg")
    ---@type UnityEngine.UI.LayoutElement
    self._layoutBg = self:GetUIComponent("LayoutElement", "bg")
    self._txtSkillCD = self:GetUIComponent("UILocalizationText", "skillCD")
    self._rtxtMask = self:GetUIComponent("RevolvingTextWithDynamicScroll", "mask")

    self._objSkillInfo = self:GetGameObject("skillInfo")
    ---@type UnityEngine.RectTransform
    self._rectSkillInfo = self:GetUIComponent("RectTransform", "skillInfo")

    self._objCancelSkillInfo = self:GetGameObject("cancelSkillInfo")
    ---@type UnityEngine.UI.Image
    self._subIconImage = self:GetUIComponent("Image", "SubIcon")
    self._subIconRect = self:GetUIComponent("RectTransform", "SubIcon")


    self._selectIndex = 1
    self._curSkillID = nil

    self:AttachEvent(GameEventType.BattleUIRefreshActiveSkillCastButtonState, self._RefreshCastButtonState)
    self:ResetSkillCanCast()
end
function UIWidgetPetMultiActiveSkill:HideSelf()
    self._isShow = false
    self:GetGameObject():SetActive(false)
end
function UIWidgetPetMultiActiveSkill:ShowSelf()
    self._isShow = true
    self:GetGameObject():SetActive(true)
end
function UIWidgetPetMultiActiveSkill:SetUiPos(position)
    self:GetGameObject().transform.position = position
end
function UIWidgetPetMultiActiveSkill:GetPetSkillBtn()
    local btn = self:GetGameObject("btnGo")
    return btn
end
function UIWidgetPetMultiActiveSkill:GetPetMultiSkillIndexBtn(index)
    local skillItem = self._skillItems[index]
    local btn = skillItem:GetSelectBtn()
    return btn
end

--小秘境 头像双列，第五个位置不用调整ui
--超过五个人要处理第四个人的UI位置
function UIWidgetPetMultiActiveSkill:SetIsMoreFivePet(isMoreFivePet)
    self._isMoreFivePet = isMoreFivePet
end

---用来判断是否超过五个人
function UIWidgetPetMultiActiveSkill:GetIsMoreFivePet()
    return self._isMoreFivePet
end

--设置光灵pstid
function UIWidgetPetMultiActiveSkill:SetPetPstId(petPstId)
    self._petPstId = petPstId
    ---@type MatchEnterData
    local enterData = GameGlobal.GetModule(MatchModule):GetMatchEnterData()
    local matchPets = enterData:GetLocalMatchPets()
    self._pet = matchPets[self._petPstId]
end

--设置光灵
function UIWidgetPetMultiActiveSkill:SetPet(pet)
    ---@type MatchPet
    self._pet = pet
end

--先制攻击
function UIWidgetPetMultiActiveSkill:ShowPreAttack(skillID)
    if self._preAttackCell then
        self._preAttackCell:SetData(self._petPstId, skillID, false)
    end
end

--清除选择的子技能ID
function UIWidgetPetMultiActiveSkill:ClearCurSkillID()
    self._curSkillID = nil
end

--隐藏
function UIWidgetPetMultiActiveSkill:OnHide()
    self:ResetSkillCanCast()
end

--刷新子技能列表控件
---@param uiDataArray UIDataActiveSkillUIInfo[]
function UIWidgetPetMultiActiveSkill:_OnRefreshSkillList(uiDataArray,isVariantSkillList)
    self._skillListRoot:SpawnObjects("UIWidgetPetMultiSkillItem", #uiDataArray)

    local uiSkillList = self._skillListRoot:GetAllSpawnList()
    self._skillItems = uiSkillList
    local dataCount = #uiDataArray
    for i = 1, #uiSkillList do
        ---@type UIWidgetTrapSkillItem
        local uiSkillItem = uiSkillList[i]
        if i <= dataCount then    
            uiSkillItem:GetGameObject():SetActive(true)
            uiSkillItem:Init(
                i,
                uiDataArray[i],
                function(index)
                    self:SubSkillOnClick(index)
                end,
                isVariantSkillList
            )
        else
            uiSkillItem:GetGameObject():SetActive(false)
        end
    end
    uiSkillList[self._selectIndex]:ButtonBgOnClick(nil)
end
--给自动战斗用
function UIWidgetPetMultiActiveSkill:SubSkillOnClick(index)
    self._selectIndex = index
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIMultiSkillClickIndex,self._petPstId,index)
    --ui
    for i = 1, #self._skillItems do
        if i <= self._skillCount then
            ---@type UIWidgetTrapSkillItem
            local uiSkillIem = self._skillItems[i]
            local uiData = self._uiDataArray[i]

            local canCast = uiData._canCast
            uiSkillIem:OnSelect(i == index, canCast)
        end
    end
    self:_OnShowSelectSkill(index)
end

--显示选择的子技能
function UIWidgetPetMultiActiveSkill:_OnShowSelectSkill(index)
    local uiData = self._uiDataArray[index]
    if not uiData then
        return
    end
    local skillID = uiData._skillId
    if self._curSkillID == skillID then
        return
    end
    self:ResetSkillCanCast()
    local lastSkillID = self._curSkillID
    self._curSkillID = skillID
    self:ShowPreAttack(skillID)
    local canCast = uiData._canCast
    if canCast then
        self._btnGo.interactable = true
        self._txtGo.color = Color.white
    else
        self._btnGo.interactable = false
        self._txtGo.color = Color(123 / 255, 123 / 255, 123 / 255, 1)
    end

    ---@type SkillConfigData
    local skillData = ConfigServiceHelper.GetSkillConfigData(skillID)
    self._txtSkillName:SetText(StringTable.Get(skillData:GetSkillName()))
    if skillData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy then
        self._txtSkillCD.gameObject:SetActive(false)
    else
        local cdSkillCfgData = skillData
        if self._isVariantSkill then--变体技 使用主技能的cd
            local cdSkillData = self._uiDataArray[1]
            local cdSkillID = cdSkillData._skillId
            cdSkillCfgData = ConfigServiceHelper.GetSkillConfigData(cdSkillID)
        end
        self._txtSkillCD.gameObject:SetActive(true)
        local strSkillCD = string.format(StringTable.Get("str_common_cooldown_round"), cdSkillCfgData:GetSkillTriggerParam())
        self._txtSkillCD:SetText(strSkillCD)
    end

    self._rtxtMask:OnRefreshRevolving()
    local strSkillDes = skillData:GetPetSkillDes()
    if not self:CheckRefineSkillReplace(skillID) then
        self._tmpSkillDesc:SetText(strSkillDes)
    end
    self._objSkillInfo:SetActive(true)
    UIHelper.RefreshLayout(self._rectSkillInfo)

    ---@type UnityEngine.RectTransform
    local skillInfoTrans = self._rectBg.parent.parent
    local isAdapteHead = false
    if self._skillCount == 2 then
        isAdapteHead = (not self:GetIsMoreFivePet()) and (InnerGameHelperRender.UICheckIsFifthPet(self._petPstId))
    elseif self._skillCount > 2 then
        if not self:GetIsMoreFivePet() then
            isAdapteHead = (InnerGameHelperRender.UICheckIsFourthPet(self._petPstId)) or (InnerGameHelperRender.UICheckIsFifthPet(self._petPstId))
        else
            isAdapteHead = InnerGameHelperRender.UICheckIsEndPet(self._petPstId)
        end
    end
     
    local tmpPos = skillInfoTrans.anchoredPosition3D
    tmpPos.y = 0
    if skillInfoTrans and isAdapteHead then
        local baseHeight = 160
        local adpH = 15
        local toPosY = self._rectBg.sizeDelta.y - baseHeight - adpH
        if toPosY > 0 then
            tmpPos.y = toPosY
        end
    end
    skillInfoTrans.anchoredPosition3D = tmpPos

    self._objCancelSkillInfo:SetActive(false)

    self:_SwitchSkillPreview(canCast, lastSkillID)
end

--技能预览相关
function UIWidgetPetMultiActiveSkill:_SwitchSkillPreview(canCast, lastSkillID)
    --技能预览
    local coreGameStateID = GameGlobal:GetInstance():CoreGameStateID()
    local enableInput = GameGlobal:GetInstance():IsInputEnable()
    if coreGameStateID == GameStateID.WaitInput and enableInput == true then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.HideCanMoveArrow)
    elseif coreGameStateID == GameStateID.PreviewActiveSkill
        or coreGameStateID == GameStateID.PickUpActiveSkillTarget
    then
        --切换预览预览  要先取消上一次的显示
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.CasterPreviewAnimatorExitPreview,
            self._petPstId,
            lastSkillID
        )
        GameGlobal.EventDispatcher():Dispatch(GameEventType.StopPreviewActiveSkill, true, false)
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.PreClickPetHead, self._curSkillID, true)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickPetHead, self._petPstId, true, self._curSkillID)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.SelectSubActiveSkill, self._curSkillID, canCast)
end

--初始化
---@param uiDataArray UIDataActiveSkillUIInfo[]
function UIWidgetPetMultiActiveSkill:Init(index,uiDataArray, castCallback,isVariantSkillList,lastClickIndex)
    self._castCallback = castCallback
    if not uiDataArray then
        return
    end
    ---@type UIDataActiveSkillUIInfo[]
    self._uiDataArray = uiDataArray
    self._skillCount = #uiDataArray
    self._isVariantSkill = isVariantSkillList
    if self._skillCount == 3 then
        self._layoutBg.minHeight = 480
    elseif self._skillCount == 2 then
        self._layoutBg.minHeight = 320
    end
    if isVariantSkillList then
        self._subIconImage.sprite = self._uiBattleAtlas:GetSprite("thread_zhudong_icon02")
    else
        self._subIconImage.sprite = self._uiBattleAtlas:GetSprite("thread_zhudong_icon01")
    end
    if lastClickIndex then
        self._selectIndex = lastClickIndex
    end
    self:_OnRefreshSkillList(uiDataArray,isVariantSkillList)
end

--点击发动按钮
function UIWidgetPetMultiActiveSkill:BtnGoOnClick()
    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        { ui = "UIWidgetPetMultiActiveSkill", input = "BtnGoOnClick", args = {} }
    )
    local uiData = self._uiDataArray[self._selectIndex]
    local skillID = uiData._skillId
    local canCast = uiData._canCast

    if (not canCast) or (not self.activeSkillCheckPass) then
        local reasonByBuffSetCanNotReadyReason = BattleStatHelper.CheckCanCastActiveSkill_GetCantReadyReasonByBuff(self._petPstId,skillID)
        if not self:MissionCanCast() then
            local text = StringTable.Get("str_match_pickup_skill_limit")
            ToastManager.ShowToast(text)
        elseif reasonByBuffSetCanNotReadyReason then
            local textKey = ActiveSkillCannotCastReasonText[reasonByBuffSetCanNotReadyReason]
            local text = StringTable.Get(textKey)
            ToastManager.ShowToast(text)
        elseif not BattleStatHelper.CheckCanCastActiveSkill_TeamLeaderCondi(self._petPstId, skillID) then
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
    if not BattleStatHelper.CheckCanCastActiveSkill_SwapPetTeamOrder(self._petPstId, skillID) then
        local text = StringTable.Get("str_battle_hebo_cannot_change_pos_with_cursed_pet")
        ToastManager.ShowToast(text)
        return
    end

    if self._castCallback and canCast and self.activeSkillCheckPass then
        ---@type SkillConfigData
        local skillConfigData = ConfigServiceHelper.GetSkillConfigData(skillID)
        ---@type SkillPickUpType
        local pickUpType = skillConfigData:GetSkillPickType()

        if self:MissionCanCast() then
            self._castCallback(skillID, pickUpType,canCast)
        else
            local text = StringTable.Get("str_match_pickup_skill_limit")
            ToastManager.ShowToast(text)
        end
    end
end

--关卡是否支持释放主动技
function UIWidgetPetMultiActiveSkill:MissionCanCast()
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

--设置取消按钮显示
function UIWidgetPetMultiActiveSkill:ShowCancelBtn(isShow)
    self._objSkillInfo:SetActive(false)

    self._objCancelSkillInfo:SetActive(isShow)
end

--获取发动按钮
function UIWidgetPetMultiActiveSkill:GetCastSkillBtn()
    return self._btnGo
end

--获取技能ID
function UIWidgetPetMultiActiveSkill:GetCurActiveSkillID()
    return self._curSkillID
end
function UIWidgetPetMultiActiveSkill:SubIconBaseOnClick(go)
    local variantStr = "str_battle_bianti_info"
    local multStr = "str_battle_double_info"
    if self._isVariantSkill then
        self:ShowDialog("UIActiveVarInfo",self._subIconRect.position,variantStr)
    else
        self:ShowDialog("UIActiveVarInfo",self._subIconRect.position,multStr)
    end
end


function UIWidgetPetMultiActiveSkill:CheckRefineSkillReplace(skillId)
    if not self._pet or not skillId then
        return false
    end
    
    local refineLv = self._pet:GetEquipRefineLv()
    if refineLv < 1 then
        return false
    end
    
    local refineConfig = UIPetEquipHelper.GetRefineCfg(self._pet:GetTemplateID(), refineLv)
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
        self._tmpSkillDesc:SetText(StringTable.Get(newDesc))
        return true
    end

    return false
end
function UIWidgetPetMultiActiveSkill:ResetSkillCanCast()
    self.activeSkillCheckPass = true
    self._cannotCastReason = nil
end

function UIWidgetPetMultiActiveSkill:_RefreshCastButtonState(result, reason)
    if self._isShow then
        self.activeSkillCheckPass = result
        self._cannotCastReason = reason
        self._castBtn.interactable = result
    end
end