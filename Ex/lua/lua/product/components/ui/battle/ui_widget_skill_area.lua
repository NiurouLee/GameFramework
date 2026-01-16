--
---@class UIWidgetSkillArea : UICustomWidget
_class("UIWidgetSkillArea", UICustomWidget)
UIWidgetSkillArea = UIWidgetSkillArea
--初始化
function UIWidgetSkillArea:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIWidgetSkillArea:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self.chooseTargetRoot = self:GetUIComponent("UISelectObjectPath", "ChooseTargetRoot")
    ---@type UICustomWidgetPool 宝宝技能UI widget pool
    self._petSkillPool = self:GetUIComponent("UISelectObjectPath", "petSkillPool")
    ---@type UIWidgetPetSkill 宝宝技能UI
    self._petSkillUIOri = self._petSkillPool:SpawnObject("UIWidgetPetSkill")
    self._petSkillUI = self._petSkillUIOri

    ---@type UICustomWidgetPool 宝宝技能UI widget pool
    self._petSubSkillPool = self:GetUIComponent("UISelectObjectPath", "petSubSkillPool")
    self._petSubSkillUI = self._petSubSkillPool:SpawnObject("UIWidgetPetSubSkill")

    ---@type UICustomWidgetPool 宝宝技能UI widget pool
    self._petMultiSkillPool = self:GetUIComponent("UISelectObjectPath", "petMultiSkillPool")
    ---@type UIWidgetPetMultiActiveSkill
    self._petMultiSkillUI = self._petMultiSkillPool:SpawnObject("UIWidgetPetMultiActiveSkill")

    ---@type UICustomWidgetPool 宝宝装备精炼UI widget pool
    self._petEquipRefinePool = self:GetUIComponent("UISelectObjectPath", "petEquipRefinePool")
    ---@type UIWidgetPetEquipRefine 宝宝装备精炼UI
    self._petEquipRefineUI = self._petEquipRefinePool:SpawnObject("UIWidgetPetEquipRefine")

    self:_CloseActiveSkillTip()

    ---@type UIWidgetBattlePet
    self._curWidgetPet = nil
    self:SpawnChooseTargetUI()
    self:RegisterEvent()
    --generated end--
end
function UIWidgetSkillArea:RegisterEvent()
    self:AttachEvent(GameEventType.UIShowActiveSkillUI, self.OnUIShowActiveSkillUI)
    self:AttachEvent(GameEventType.UIShowMultiActiveSkillUI, self.OnUIShowMultiActiveSkillUI)
    self:AttachEvent(GameEventType.AutoFightCastSkill, self.OnCastSkill)
    self:AttachEvent(GameEventType.BattleUIRefreshActiveSkillCastButtonState, self._OnBattleUIRefreshActiveSkillCastButtonState)
    self:AttachEvent(GameEventType.SelectSubActiveSkill, self._OnSelectSubActiveSkill)
    self:AttachEvent(GameEventType.PickUPInvalidGridCancelActiveSkill, self.PickInvalidGridCancelPreview)
    self:AttachEvent(GameEventType.UICancelChooseTarget, self.HandleUICancelChooseTarget)
    self:AttachEvent(GameEventType.PickUPValidGridShowChooseTarget, self.ShowChooseTarget)
    self:AttachEvent(GameEventType.UIChooseTargetConfirm, self.HandleUIChooseTargetConfirm)
    self:AttachEvent(GameEventType.UIChooseTargetGray, self.HandleUIChooseTargetGray)
    self:AttachEvent(GameEventType.EnablePickUpSkillCast, self.EnablePickUpSkillCast)
    self:AttachEvent(GameEventType.OnClickWhenPickUp, self._CloseActiveSkillTip)
    self:AttachEvent(GameEventType.ShowActiveSkillChooseUI, self._OnShowActiveSkillChooseUI)
    self:AttachEvent(GameEventType.UIResetLastPreviewPetId, self.ResetLastPreviewPetId)
    self:AttachEvent(GameEventType.UISetLastPreviewPetId, self.SetPreviewPetId)
    self:AttachEvent(GameEventType.UISwitchActiveSkillUI, self.SwitchActiveSkillUI)
    self:AttachEvent(GameEventType.UICancelActiveSkillCast, self._CancelActiveSkill)
    self:AttachEvent(GameEventType.UIPetClickToSwitch, self.OnPetSwitchCallBack)
    self:AttachEvent(GameEventType.BattleUIShowHideSelectTeamPositionButton, self.ShowHideSelectTeamPositionButton)
    self:AttachEvent(GameEventType.BattleUISelectTargetTeamPosition, self.OnBattleUISelectTargetTeamPosition)
    self:AttachEvent(GameEventType.ClickPetHead, self.OnClickPetHead)
    self:AttachEvent(GameEventType.UIShowPetInfo, self.HandleUIShowPetInfo)
end
--设置数据
function UIWidgetSkillArea:SetData(uiBattle)
    --临时直接调用uibattle的方法，后续去掉，sjs_todo
    ---@type UIBattle
    self._uiBattle = uiBattle
    
end
function UIWidgetSkillArea:SpawnChooseTargetUI()
    ---选择技能目标的面板
    --local chooseTargetRoot = self:GetUIComponent("UISelectObjectPath", "ChooseTargetRoot")
    ---@type UIWidgetChooseTarget
    self._chooseTargetWidget = self.chooseTargetRoot:SpawnObject("UIWidgetChooseTarget")
end
--关闭主动技能描述和重置技能预览的宝宝id
function UIWidgetSkillArea:_CloseActiveSkillTip()
    if self._petSkillUI then
        self._petSkillUI:HideSelf()
        if self._petSkillUI._className == "UIWidgetPetSubSkill" then
            self._petSkillUI:ClearCurSkillID()
        else
            self._petSkillUI:ResetSkillCanCast()
        end
    end
    if self._petSubSkillUI then
        self._petSubSkillUI:HideSelf()
    end
    if self._petMultiSkillUI then
        self._petMultiSkillUI:ClearCurSkillID()
        self._petMultiSkillUI:HideSelf()
    end
    if self._petEquipRefineUI then
        self._petEquipRefineUI:HideSelf()
    end
    self:ResetLastPreviewPetId()
end

function UIWidgetSkillArea:ResetLastPreviewPetId()
    self._lastPreviewPetId = nil
end

function UIWidgetSkillArea:SetPreviewPetId(petId)
    self._lastPreviewPetId = petId
end

function UIWidgetSkillArea:GetPreviewPetId()
    return self._lastPreviewPetId
end
function UIWidgetSkillArea:GetCurPetActiveSkillId()
    return self._curPetActiveSkillId
end
function UIWidgetSkillArea:IsAutoFighting()
    return GameGlobal.GetUIModule(MatchModule):IsAutoFighting()
end
function UIWidgetSkillArea:ShowAutoFightForbiddenMsg()
    return GameGlobal.GetUIModule(MatchModule):ShowAutoFightForbiddenMsg()
end

function UIWidgetSkillArea:IsMoreFivePet()
    ---@type MatchEnterData
    local matchEnterData = self:GetModule(MatchModule):GetMatchEnterData()
    return (matchEnterData:GetMatchType() == MatchType.MT_MiniMaze) or (matchEnterData:GetMatchType() == MatchType.MT_EightPets)
end

--小秘境 柏乃技能ui特殊处理，点头像先隐藏发动区域，点位置后再显示
function UIWidgetSkillArea:SkillNeedHideActiveSkillUIInMiniMaze(skillId)
    local spePetSkillIDList = {302144,305144,312144,315144}
    if table.icontains(spePetSkillIDList,skillId) then
        return true
    else
        return false
    end
end


--
function UIWidgetSkillArea:OnUIShowActiveSkillUI(petWidget, skillId, maxPower, leftPower, canCast)
    self:ShowActiveSkillUI(petWidget, skillId, maxPower, leftPower, canCast)
    --柏乃 小秘境 特殊处理
    if self:IsMoreFivePet() then
        if self:SkillNeedHideActiveSkillUIInMiniMaze(skillId) then
            if self._petSkillUI then
                self._petSkillUI:HideSelf()
            end
        end
    end

    self:ShowPetEquipRefineUI(petWidget)
end
---@param uiDataArray UIDataActiveSkillUIInfo[]
function UIWidgetSkillArea:OnUIShowMultiActiveSkillUI(index,petWidget, uiDataArray, isVariantSkillList, lastClickIndex)
    self:ShowMultiActiveSkillUI(index, petWidget, uiDataArray, isVariantSkillList, lastClickIndex)
end
------------点击宝宝---------------------------------------------
---显示主动技能释放UI
---@param petWidget UIWidgetBattlePet
---@param skillId number
---@param leftPower number
---@param canCast boolean
function UIWidgetSkillArea:ShowActiveSkillUI(petWidget, skillId, maxPower, leftPower, canCast)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.PauseGuideWeakLine)

    local posGO = petWidget:GetActiveSkillUIPos()
    local cancelSkillPosGo = petWidget:GetCancelSkillUIPos()

    local petPstID = petWidget:GetPetPstID()

    self._curWidgetPet = petWidget
    self._curPetActiveSkillId = skillId
    self._curPetPstId = petPstID
    self._previewActiveSkillCheckPass = nil

    ---@type SkillConfigData
    local skillConfigData = ConfigServiceHelper.GetSkillConfigData(skillId, petPstID)

    local subSkillIDList = skillConfigData:GetSubSkillIDList()
    if #subSkillIDList == 0 then
        ---@type UIWidgetPetSkill
        self._petSkillUI = self._petSkillUIOri
        self._curWidgetPet:SetUseSubActiveSkillState(false)
    else
        ---@type UIWidgetPetSubSkill
        self._petSkillUI = self._petSubSkillUI
        self._curWidgetPet:SetUseSubActiveSkillState(true)
    end
    self._petSkillUI:SetUiPos(posGO.transform.position)
    self._petSkillUI:SetPetPstId(petPstID)
    --self._petSkillUI:SetPet(self._petDatas[petPstID])--sjs_todo 看起来没用到,拆分后_petDatas在UIWidgetPetArea中，先注掉
    --现在UIWidgetPetSkill中只负责发动不需要选格子的技能
    self._petSkillUI:ShowSelf()
    self._petSkillUI:Init(
        skillId,
        maxPower,
        leftPower,
        canCast,
        function(castSkillID, pickUpType)
            self:CancelActiveSkillSwitchTimer()
            self._petSkillUI:HideSelf()
            self._petEquipRefineUI:HideSelf()
            if self._petSkillUI._className == "UIWidgetPetSubSkill" then
                self._petSkillUI:ClearCurSkillID()
            end
            self:ShowHideCancelActiveSkillBtn(false)
            self:OnCastSkill(castSkillID, pickUpType, petPstID)
        end,
        petPstID
    )

    --self._activeSkillCancelBtn.interactable = true

    self._curPetActiveSkillId = self._petSkillUI:GetCurActiveSkillID()

    skillConfigData = ConfigServiceHelper.GetSkillConfigData(self._curPetActiveSkillId, petPstID)
    ---@type SkillPickUpType
    local pickUpType = skillConfigData:GetSkillPickType()
    self._pickUpType = pickUpType

    --默认关闭，在需要的时候打开
    self._chooseTargetWidget:ShowChooseTargetPanel(false)

    --选格子类型的技能，点头像直接开始预览，不需要再点发动按钮
    if pickUpType ~= SkillPickUpType.None then
        self._isCurPetSkillReady = canCast --暂存当前星灵主动技是否可发动
        self:_PreviewPickUpSkill(self._curPetActiveSkillId, pickUpType, petPstID, cancelSkillPosGo)
        self:ShowHideCancelActiveSkillBtn(false)
    else
        --直接发动类的技能需要点击空白取消
        self:ShowHideCancelActiveSkillBtn(true)
    end

    self:OnExclusivePetHeadMaskAlpha(BattleConst.ActiveSkillDarkAlpha, petPstID)--sjs_todo

    --播放语音
    local pm = GameGlobal.GetModule(PetAudioModule)
    pm:PlayPetAudio("StandBy", petWidget._petTemplateID)
end
--此函数和UI状态无关，可以直接调用
function UIWidgetSkillArea:OnCastSkill(castSkillID, pickUpType, petPstID)
    local petWidget = self._uiBattle:GetPetWidgetByPstID(petPstID)--sjs_todo

    --发动技能后，判断技能类型
    if pickUpType == SkillPickUpType.None then
        --播放技能音效
        GameGlobal.EventDispatcher():Dispatch(GameEventType.CastActiveSkill, castSkillID, petPstID)
        petWidget:ClearPower(castSkillID)
        ---发动后，重置头像半透
        self:OnExclusivePetHeadMaskAlpha(0, -1)--sjs_todo

        --播放语音
        local pm = GameGlobal.GetModule(PetAudioModule)
        pm:PlayPetAudio("Skill", petWidget._petTemplateID, true)
        self:ResetLastPreviewPetId()
    elseif pickUpType == SkillPickUpType.PickSwitchInstruction then
        --Log.fatal("[UIBattle] cast skill pick up type error:", pickUpType)
        self:EnablePickUpSkillCast(true)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActiveSkillPickUp, castSkillID, petPstID)
    else
        --Log.fatal("[UIBattle] cast skill pick up type error:", pickUpType)
        self:EnablePickUpSkillCast(false)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActiveSkillPickUp, castSkillID, petPstID)
    end
end
---@result boolean
function UIWidgetSkillArea:_OnBattleUIRefreshActiveSkillCastButtonState(result, reason)
    self:SetPickUpActiveBtnState(result)
    self._previewActiveSkillCheckPass = result
    self._activeSkillDisableReason = reason
end

function UIWidgetSkillArea:SetPickUpActiveBtnState(canCast)
    self._chooseTargetWidget:SetPickUpActiveBtnState(canCast)
end
--开始选格子预览
function UIWidgetSkillArea:_PreviewPickUpSkill(skillId, pickUpType, petPstID, cancelSkillPosGo)
    self:CancelActiveSkillSwitchTimer()

    --发动
    GameGlobal.EventDispatcher():Dispatch(GameEventType.CastActiveSkill, skillId, petPstID)
    --发动技能后，判断技能类型
    if pickUpType == SkillPickUpType.None then
        Log.fatal("[UIBattle] preview skill pickup type is none")
    else
        self:_OnShowActiveSkillChooseUI(skillId, pickUpType, petPstID, self._isCurPetSkillReady)
    end
end

function UIWidgetSkillArea:_OnShowActiveSkillChooseUI(skillId, pickUpType, petPstID, canCast)
    self._curPetActiveSkillId = skillId
    self._curPetPstId = petPstID
    self._pickUpType = pickUpType
    self._isCurPetSkillReady = canCast

    self._chooseTargetWidget:InitChooseTargetWidget(skillId,petPstID)
    self._chooseTargetWidget:SetChooseUIText(pickUpType)
end
--光灵主动技选择子技能ID
---@param skillID number
---@param canCast boolean
function UIWidgetSkillArea:_OnSelectSubActiveSkill(skillID, canCast)
    -- if skillID == self._curPetActiveSkillId then
    --     return
    -- end

    self._curPetActiveSkillId = skillID
    local petPstID = self._curWidgetPet:GetPetPstID()
    ---@type SkillConfigData
    local skillConfigData = ConfigServiceHelper.GetSkillConfigData(self._curPetActiveSkillId, petPstID)

    ---@type SkillPickUpType
    local pickUpType = skillConfigData:GetSkillPickType()
    self._pickUpType = pickUpType

    --选格子类型的技能，点头像直接开始预览，不需要再点发动按钮
    if pickUpType ~= SkillPickUpType.None then
        local cancelSkillPosGo = self._curWidgetPet:GetCancelSkillUIPos()

        self._isCurPetSkillReady = canCast
        self:_PreviewPickUpSkill(self._curPetActiveSkillId, pickUpType, petPstID, cancelSkillPosGo)
        self:ShowHideCancelActiveSkillBtn(false)
    else
        --直接发动类的技能需要点击空白取消
        self:ShowHideCancelActiveSkillBtn(true)
    end
end
function UIWidgetSkillArea:_CancelActiveSkill()
    self:CancelActiveSkillSwitchTimer()

    self:_CloseActiveSkillTip()
    self:ShowHideCancelActiveSkillBtn(false)

    self._curPetActiveSkillId = 0
    self._curPetPstId = 0
    self._isCurPetSkillReady = false
    self._curWidgetPet = nil
    self._previewActiveSkillCheckPass = nil

    self._chooseTargetWidget:ShowChooseTargetPanel(false)

    ---取消发动时，重置头像半透
    self:OnExclusivePetHeadMaskAlpha(0, -1)

    GameGlobal.EventDispatcher():Dispatch(GameEventType.TrapPowerVisible, true)
end
function UIWidgetSkillArea:ShowHideCancelActiveSkillBtn(bShow)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIShowHideCancelActiveSkillBtn, bShow)
end
function UIWidgetSkillArea:CancelActiveSkillSwitchTimer()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UICancelActiveSkillSwitchTimer)
end
function UIWidgetSkillArea:PickInvalidGridCancelPreview()
    self:_CancelActiveSkill()
end
function UIWidgetSkillArea:HandleUICancelChooseTarget()
    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.CancelActiveSkillCast,
        self._curPetActiveSkillId,
        self._curPetPstId
    )
    self:_CancelActiveSkill() --通过右下角按钮取消释放主动技，真正的取消
end
function UIWidgetSkillArea:OnExclusivePetHeadMaskAlpha(alpha, exclusivePetPstID)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIExclusivePetHeadMaskAlpha,
        alpha, exclusivePetPstID
    )
end
function UIWidgetSkillArea:ShowChooseTarget(show)
    self._previewActiveSkillCheckPass = true
    self._chooseTargetWidget:ShowChooseTargetPanel(show)
end
function UIWidgetSkillArea:SwitchActiveSkillUI()
    self:CancelActiveSkillSwitchTimer()
    if self._petSkillUI then
        self:_CloseActiveSkillTip()
    end
    --self._uibattle:FeatureOnSwitchActiveSkillUI()--sjs_todo
    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.StopPreviewActiveSkill,
        true,
        false,
        self._curPetActiveSkillId,
        self._curPetPstId
    )
end
function UIWidgetSkillArea:OnPetSwitchCallBack(go)
    if self:IsAutoFighting() and go then
        self:ShowAutoFightForbiddenMsg()
    else
        self:SwitchActiveSkillUI()
    end
end
function UIWidgetSkillArea:HandleUIChooseTargetConfirm()
    -- 技能有可能被换掉了
    ---@type SkillConfigData
    local skillConfigData = ConfigServiceHelper.GetSkillConfigData(self._curPetActiveSkillId, self._curPetPstId)
    self._curPetActiveSkillId = skillConfigData:GetID()

    --光灵主动技/机关主动技 按照不同的方式
    if skillConfigData:GetSkillType() == SkillType.Active then
        -- GameGlobal.EventDispatcher():Dispatch(GameEventType.CastPickUpSkill) --通知执行主动技
        local logicCanCast, log = BattleStatHelper.CheckActiveSkillCastCondition(self._curPetPstId, self._curPetActiveSkillId)
        if not logicCanCast then
            local cmd = ClientExceptionReportCommand.CreateCastPickupActiveException(self._curWidgetPet, log)
            cmd._dbgAutoFightInfo = self._dbgAutoFightInfo--消息改过后，需要加到msg里才有效 todo
            GameGlobal.EventDispatcher():Dispatch(GameEventType.ClientExceptionReport, cmd)
            if EDITOR then
                Log.exception(echo(cmd))
            end
            return
        end

        self:OnExclusivePetHeadMaskAlpha(0, -1) ---发动后，重置头像半透

        if self._curWidgetPet ~= nil then
            local pm = GameGlobal.GetModule(PetAudioModule) --播放语音
            pm:PlayPetAudio("Skill", self._curWidgetPet._petTemplateID, true)
            self._curWidgetPet:ClearPower(self._curPetActiveSkillId)
        end
        self._curWidgetPet = nil
    elseif skillConfigData:GetSkillType() == SkillType.TrapSkill then
        self._curWidgetPet = nil
    elseif skillConfigData:GetSkillType() == SkillType.FeatureSkill then
        self._curWidgetPet = nil
        self._uiBattle:FeatureOnChooseTargetConfirm()--sjs_todo
    end

    self:_CloseActiveSkillTip() --点击任何按钮都应该关闭tip

    self._curPetActiveSkillId = 0 --发动后，数据重置
    self._curPetPstId = 0
    self._isCurPetSkillReady = false
    self._previewActiveSkillCheckPass = nil

    self._petSkillUI:ShowCancelBtn(false)

    GameGlobal.EventDispatcher():Dispatch(GameEventType.CastPickUpSkill) --通知执行主动技
end

function UIWidgetSkillArea:HandleUIChooseTargetGray()
    if not self._curWidgetPet then
        return
    end
    
    local canCast, reason, forceTips = self._curWidgetPet:GetCanCastAndReason(self._curPetActiveSkillId)
    if forceTips then
        ToastManager.ShowToast(reason)
    else
        if (self._isCurPetSkillReady == false) and (not canCast) then
            ToastManager.ShowToast(reason)
        else
            local textKey = ActiveSkillCannotCastReasonText[self._activeSkillDisableReason]
            if textKey then
                local text = StringTable.Get(textKey)
                ToastManager.ShowToast(text)
            end
        end
    end
end
--非点选的取消遮罩按钮，因为层级原因不在这个widget里
function UIWidgetSkillArea:OnCancelActiveSkillBtnOnClick(go)
    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        { ui = "UIBattle", input = "CancelActiveSkillBtnOnClick", args = {} }
    )

    ---终止主动技预览计时器
    self:CancelActiveSkillSwitchTimer()

    ---头像恢复
    self:OnExclusivePetHeadMaskAlpha(0, -1)

    self:ShowHideCancelActiveSkillBtn(false)
    self:_CloseActiveSkillTip()

    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.CasterPreviewAnimatorExitPreview,
        self._curPetPstId,
        self._curPetActiveSkillId
    )

    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.StopPreviewActiveSkill,
        false,
        true,
        self._curPetActiveSkillId,
        self._curPetPstId
    )

    GameGlobal.EventDispatcher():Dispatch(GameEventType.PreClickPetHead, -1)
end
function UIWidgetSkillArea:GetPetSkillBtn()
    return self._petSkillUI and self._petSkillUI:GetPetSkillBtn()
end
function UIWidgetSkillArea:GetPetMultiSkillIndexBtn(index)
    return self._petMultiSkillUI and self._petMultiSkillUI:GetPetMultiSkillIndexBtn(index)
end
---主动技可发动
function UIWidgetSkillArea:EnablePickUpSkillCast(canCast)
    local canCastActive = canCast and self._isCurPetSkillReady and self._previewActiveSkillCheckPass
    self:SetPickUpActiveBtnState(canCastActive)
end

--柏乃 多列情况下ui遮挡处理，隐藏发动按钮
function UIWidgetSkillArea:ShowHideSelectTeamPositionButton(pstID, bShow)
    if self:IsMoreFivePet() then
        if self._petSkillUI then
            self._petSkillUI:HideSelf()
        end
    end
end
--柏乃 多列情况下ui遮挡处理，隐藏发动按钮 点击一次位置按钮后显示
function UIWidgetSkillArea:OnBattleUISelectTargetTeamPosition(pstID)
    if self:IsMoreFivePet() then
        if self._petSkillUI then
            self._petSkillUI:ShowSelf()
        end
    end
end


------------点击宝宝---------------------------------------------
---显示主动技能释放UI 多主动技
---@param petWidget UIWidgetBattlePet
---@param uiDataArray UIDataActiveSkillUIInfo[]
function UIWidgetSkillArea:ShowMultiActiveSkillUI(index,petWidget, uiDataArray, isVariantSkillList, lastClickIndex)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.PauseGuideWeakLine)

    local posGO = petWidget:GetActiveSkillUIPos()
    local cancelSkillPosGo = petWidget:GetCancelSkillUIPos()

    local petPstID = petWidget:GetPetPstID()

    self._curWidgetPet = petWidget
    --self._curPetActiveSkillId = skillId
    self._curPetPstId = petPstID
    self._previewActiveSkillCheckPass = nil

    self._curWidgetPet:SetUseSubActiveSkillState(false)
    -- local subSkillIDList = skillConfigData:GetSubSkillIDList()
    -- if #subSkillIDList == 0 then
    --     ---@type UIWidgetPetSkill
    --     self._petSkillUI = self._petSkillUIOri
    --     self._curWidgetPet:SetUseSubActiveSkillState(false)
    -- else
    --     ---@type UIWidgetPetSubSkill
    --     self._petSkillUI = self._petSubSkillUI
    --     self._curWidgetPet:SetUseSubActiveSkillState(true)
    -- end
    self._petMultiSkillUI:SetIsMoreFivePet( self:IsMoreFivePet())
    self._petMultiSkillUI:SetUiPos(posGO.transform.position)
    self._petMultiSkillUI:SetPetPstId(petPstID)
    --现在UIWidgetPetSkill中只负责发动不需要选格子的技能
    self._petMultiSkillUI:ShowSelf()
    self._petMultiSkillUI:Init(
        index,
        uiDataArray,
        function(castSkillID, pickUpType,ready)
            self._curPetActiveSkillId = castSkillID
            self._isCurPetSkillReady = ready
            self:CancelActiveSkillSwitchTimer()
            
            self._petMultiSkillUI:ClearCurSkillID()
            self._petMultiSkillUI:HideSelf()
            self:ShowHideCancelActiveSkillBtn(false)
            self:OnCastSkill(castSkillID, pickUpType, petPstID)
        end,
        isVariantSkillList,
        lastClickIndex
    )

    --默认关闭，在需要的时候打开
    self._chooseTargetWidget:ShowChooseTargetPanel(false)
    --self:ShowHideCancelActiveSkillBtn(true)
    -- --选格子类型的技能，点头像直接开始预览，不需要再点发动按钮
    -- if pickUpType ~= SkillPickUpType.None then
    --     self._isCurPetSkillReady = canCast --暂存当前星灵主动技是否可发动
    --     self:_PreviewPickUpSkill(self._curPetActiveSkillId, pickUpType, petPstID, cancelSkillPosGo)
    --     self:ShowHideCancelActiveSkillBtn(false)
    -- else
    --     --直接发动类的技能需要点击空白取消
    --     self:ShowHideCancelActiveSkillBtn(true)
    -- end

    self:OnExclusivePetHeadMaskAlpha(BattleConst.ActiveSkillDarkAlpha, petPstID)--sjs_todo

    --播放语音
    local pm = GameGlobal.GetModule(PetAudioModule)
    pm:PlayPetAudio("StandBy", petWidget._petTemplateID)
end
--多技能界面打开时还是waitinput 点其他头像关闭界面
function UIWidgetSkillArea:OnClickPetHead(castSkillPetPstID, energyReady, curSkillID)
    if self._curPetPstId and self._curPetPstId ~= castSkillPetPstID then
        if self._petMultiSkillUI then
            self._petMultiSkillUI:HideSelf()
        end
    end
end

---处理长按头像时的情况
function UIWidgetSkillArea:HandleUIShowPetInfo(petPstID, isShow)
    --如果主动技弹窗处于显示状态先关闭弹窗
    if isShow and self._curWidgetPet ~= nil then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.CancelActiveSkillCast,
            self._curPetActiveSkillId,
            self._curPetPstId
        )
        self:_CancelActiveSkill()
    end
end

---@param petWidget UIWidgetBattlePet
function UIWidgetSkillArea:ShowPetEquipRefineUI(petWidget)
    local petPstID = petWidget:GetPetPstID()
    
    ---检查是否需要显示
    ---@type BuffViewInstance
    local buffViewIns = nil
    ---@type BuffViewInstance[]
    local buffViewArray = InnerGameHelperRender.GetBuffViewByPetPstID(petPstID)
    for i, buffView in ipairs(buffViewArray) do
        if buffView:GetBuffEffectType() == BuffEffectType.ShowEquipRefineUI then
            buffViewIns = buffView
            break
        end
    end

    ---未激活，不显示
    if not buffViewIns then
        return
    end

    ---当前只处理单主动技的光灵显示 后续多主动也需要显示装备精炼时再做处理
    ---若是第五个光灵 则显示在主动技UI上方 否则显示在主动技UI下方
    ---若主动技过长 则需要另行特殊处理——————————TODO!!!!!!!
    local objPos = self._petSkillUI:GetEquipRefineDownPosObj()
    local isUp = false
    if InnerGameHelperRender.UICheckIsFifthPet(petPstID) then
        objPos = self._petSkillUI:GetEquipRefineUpPosObj()
        isUp = true
    end
    
    self._petEquipRefineUI:SetUIPos(objPos.transform.position, isUp)
    self._petEquipRefineUI:ShowSelf()
    self._petEquipRefineUI:Init(petPstID, buffViewIns)
end
