--
---@class UIWidgetFeaturePersonaSkill : UICustomWidget
_class("UIWidgetFeaturePersonaSkill", UICustomWidget)
UIWidgetFeaturePersonaSkill = UIWidgetFeaturePersonaSkill
--初始化
function UIWidgetFeaturePersonaSkill:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIWidgetFeaturePersonaSkill:InitWidget()
    --允许模拟输入
    self.enableFakeInput = true
    --generated--
    self._imageNormalGo = self:GetGameObject("ImageNormal")
    self._imageWarningGo = self:GetGameObject("ImageWarning")
    ---@type UnityEngine.UI.Image
    self._uIWidgetFeaturePersonaSkill = self:GetUIComponent("Image", "UIWidgetFeaturePersonaSkill")

    ---@type UnityEngine.GameObject
    self._skillInfoGenGo = self:GetGameObject("SkillInfoGen")

    ---@type UICustomWidgetPool 技能UI widget pool
    self._skillPool = self:GetUIComponent("UISelectObjectPath", "SkillInfoGen")
    ---@type UIWidgetFeaturePersonaSkillInfo 技能UI
    self._skillUI = self._skillPool:SpawnObject("UIWidgetFeaturePersonaSkillInfo")
    ---@type UILocalizationText
    self._powerText = self:GetUIComponent("UILocalizationText", "power")
    self._powerTextGo = self:GetGameObject("power")

    self.alreadyCastActiveImage = self:GetGameObject("AlreadyCastActiveImage")
    self.alreadyCastActiveImage:SetActive(false)
    self._cdGO = self:GetGameObject("CdArea")
    self._cdGO:SetActive(true)

    self._skillInfoGenGo:SetActive(false)
    ---@type UIBattle
    self._uiBattle = nil
    self._switchTimeEvent = nil
    self._switchTimeLength = 100 --切换头像的延迟时间

    self:AttachEvent(GameEventType.PersonaPowerChange, self.OnPersonaPowerChange)
    self:AttachEvent(GameEventType.AutoFightCastPersonaSkill, self.OnAutoFightCastPersonaSkill)
    self:AttachEvent(GameEventType.OnClickWhenPickUp, self.OnClickWhenPickUp)
    self:AttachEvent(GameEventType.UICancelChooseTarget, self.OnChooseTargetCancel)
    self:AttachEvent(GameEventType.PickUPInvalidGridCancelActiveSkill, self.OnPickInvalidGridCancel)
    self._power = 0
    self._ready = 1

    
    self:OnPersonaPowerChange(FeatureType.PersonaSkill,0,1)
    --generated end--
end
function UIWidgetFeaturePersonaSkill:IsAutoFighting()
    return GameGlobal.GetUIModule(MatchModule):IsAutoFighting()
end
function UIWidgetFeaturePersonaSkill:OnPersonaPowerChange(featureType,power, ready)
    if not (FeatureType.PersonaSkill == featureType) then
        return
    end
    if power <= 0 then
        power = 0
    end
    if self._power == 0 then
        self._cdGO:SetActive(power ~= 0)
    end

    if self._ready == 1 or self._power == 0 then
        self.alreadyCastActiveImage:SetActive(false)
    end
    if ready then
        if self._ready ~= ready then
            self._ready = ready
        end
        if ready == 1 then
            self._cdGO:SetActive(false)
        end
    end
    if self._power ~= power then
        self._power = power
    end
    self._powerText:SetText(power)

    self:_RefreshStateBg()
end
function UIWidgetFeaturePersonaSkill:_RefreshStateBg()
    self._imageNormalGo:SetActive(self._ready ~= 1)
    self._imageWarningGo:SetActive(self._ready == 1)
end
function UIWidgetFeaturePersonaSkill:SetUIBattle(uiBattle)
    self._uiBattle = uiBattle
end
function UIWidgetFeaturePersonaSkill:GetUIBattle()
    return self._uiBattle
end
--设置数据
---@param personaSkillInitData FeatureEffectParamPersonaSkill
function UIWidgetFeaturePersonaSkill:SetData(personaSkillInitData)
    self._featureInitData = personaSkillInitData
    self._skillID = self._featureInitData:GetPersonaSkillID()
    self._skillConfigData = ConfigServiceHelper.GetSkillConfigData(self._skillID)
    ---@type SkillConfigData
    local skillConfigData = self._skillConfigData
    self._maxPower = skillConfigData:GetSkillTriggerParam()
end
--按钮点击
function UIWidgetFeaturePersonaSkill:UIWidgetFeaturePersonaSkillOnClick(go)
    if self:IsAutoFighting() then
        return
    end
    local canCastSkill = true
    if canCastSkill then
        ---只有在局内是等待输入的时候，才能显示主动技弹框
        local coreGameStateID = GameGlobal:GetInstance():CoreGameStateID()
        local enableInput = GameGlobal:GetInstance():IsInputEnable()

        if coreGameStateID == GameStateID.WaitInput and enableInput == true then
            --GameGlobal.EventDispatcher():Dispatch(GameEventType.UISetLastPreviewPetId, self.petPstID)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.PreClickPetHead, self._skillID)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.HideCanMoveArrow)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickPersonaSkill, FeatureType.PersonaSkill, self._skillID)
            self:ShowPersonaSkillUI()
        elseif coreGameStateID == GameStateID.PreviewActiveSkill or coreGameStateID == GameStateID.PickUpActiveSkillTarget
        then
            if self._switchTimeEvent == nil then
                GameGlobal.EventDispatcher():Dispatch(GameEventType.UISwitchActiveSkillUI)
                --切换预览
                self:ShowPersonaSkillUI()
                
                Log.notice("preclickhead persona skill", self._skillID)
                ---先通知战斗，记录一次技能ID
                GameGlobal.EventDispatcher():Dispatch(GameEventType.PreClickPetHead, self._skillID)
                GameGlobal.EventDispatcher():Dispatch(GameEventType.HideCanMoveArrow)
                --通知战斗，切换预览
                self._switchTimeEvent = GameGlobal.Timer():AddEvent(
                    self._switchTimeLength,
                    function()
                        GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickPersonaSkill, FeatureType.PersonaSkill, self._skillID)
                        self._switchTimeEvent = nil
                        Log.notice("preview persona skill", self._skillID)
                    end
                )

                --GameGlobal.EventDispatcher():Dispatch(GameEventType.UISetLastPreviewPetId, self.petPstID)
            else
                Log.notice("still in switch", self._skillID)
            end
        end
    end
    
end
------------点击宝宝---------------------------------------------
---显示主动技能释放UI
---@param petWidget UIWidgetBattlePet
---@param skillId number
---@param leftPower number
---@param canCast boolean
function UIWidgetFeaturePersonaSkill:ShowPersonaSkillUI()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIFeatureSkillInfoShow,true,FeatureType.PersonaSkill)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UICancelActiveSkillCast)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.PauseGuideWeakLine)
    ---@type SkillConfigData
    local skillConfigData = self._skillConfigData
    local canCast = (self._ready == 1)
    local castCb = function(castSkillID, pickUpType)
        self:OnCastSkill(castSkillID, pickUpType)
    end
    local cancelCb = function()
        self:OnCancelSkill()
    end
    self._skillUI:Init(
        FeatureType.PersonaSkill,
        self._skillID,
        self._maxPower,
        self._power,
        canCast,
        castCb,
        cancelCb
    )
    ---@type SkillPickUpType
    local pickUpType = skillConfigData:GetSkillPickType()
    self._pickUpType = pickUpType

    --选格子类型的技能，点头像直接开始预览，不需要再点发动按钮
    if pickUpType ~= SkillPickUpType.None then
        self._isCurPetSkillReady = canCast --暂存当前星灵主动技是否可发动
        self:_PreviewPickUpSkill(self._skillID, pickUpType)
        --self.cancelActiveSkillBtn:SetActive(false)
        self._skillUI:ShowCancelBtn(false)
    else
        --直接发动类的技能需要点击空白取消
        --self.cancelActiveSkillBtn:SetActive(true)
        self._skillUI:ShowCancelBtn(true)
    end

    --播放语音
    -- local pm = GameGlobal.GetModule(PetAudioModule)
    -- pm:PlayPetAudio("StandBy", petWidget._petTemplateID)

    self._skillInfoGenGo:SetActive(true)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickUI2ClosePreviewMonster)
end
---隐藏技能信息界面
function UIWidgetFeaturePersonaSkill:HidePersonaSkillUI()
    self._skillInfoGenGo:SetActive(false)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIFeatureSkillInfoShow,false,FeatureType.PersonaSkill)
end
--此函数和UI状态无关，可以直接调用
function UIWidgetFeaturePersonaSkill:OnCastSkill(castSkillID, pickUpType)
    --发动技能后，判断技能类型
    if pickUpType == SkillPickUpType.None then
        --播放技能音效
        GameGlobal.EventDispatcher():Dispatch(GameEventType.CastPersonaSkill, castSkillID)
        self:ClearPower()
        -- ---发动后，重置头像半透
        -- self:OnExclusivePetHeadMaskAlpha(0, -1)

        -- --播放语音
        -- local pm = GameGlobal.GetModule(PetAudioModule)
        -- pm:PlayPetAudio("Skill", petWidget._petTemplateID, true)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UIResetLastPreviewPetId)
        self:HidePersonaSkillUI()
    elseif pickUpType == SkillPickUpType.PickSwitchInstruction then
        Log.fatal("[UIWidgetFeaturePersonaSkill] cast skill pick up type error:", pickUpType)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, true)
        local petPstID = 0
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActiveSkillPickUp, castSkillID, petPstID)
        self:HidePersonaSkillUI()
    else
        Log.fatal("[UIWidgetFeaturePersonaSkill] cast skill pick up type error:", pickUpType)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, false)
        local petPstID = 0
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActiveSkillPickUp, castSkillID, petPstID)
        self:HidePersonaSkillUI()
    end
end
--释放技能后清空能能量槽
function UIWidgetFeaturePersonaSkill:ClearPower()
    --self:OnPersonaPowerChange(self._maxPower,0)
    --self:OnPersonaPowerChange(self._maxPower,0)
    --普通光灵
    self._power = 0
    self._ready = 0
    --self.powerFull:SetActive(false)
    self.alreadyCastActiveImage:SetActive(true)
    self:_RefreshStateBg()
end
function UIWidgetFeaturePersonaSkill:OnCancelSkill()
    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.StopPreviewActiveSkill,
        false,
        true,
        self._skillID,
        -1
    )
    GameGlobal.EventDispatcher():Dispatch(GameEventType.PreClickPetHead, -1)
    
    self:HidePersonaSkillUI()
end
function UIWidgetFeaturePersonaSkill:OnSwitchActiveSkillUI()
    self:HidePersonaSkillUI()
end
function UIWidgetFeaturePersonaSkill:OnChooseTargetConfirm()
    if self._skillID > 0 and self._uiBattle:GetCurPetActiveSkillId() == self._skillID then
        self:ClearPower()
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UIResetLastPreviewPetId)
        self:HidePersonaSkillUI()
    end
end
function UIWidgetFeaturePersonaSkill:OnChooseTargetCancel()
    self:HidePersonaSkillUI()
end
function UIWidgetFeaturePersonaSkill:OnPickInvalidGridCancel()
    self:HidePersonaSkillUI()
end
function UIWidgetFeaturePersonaSkill:OnAutoFightCastPersonaSkill(featureType)
    if not featureType then--最开始没有这个参数
        self:OnCastSkill(self._skillID,SkillPickUpType.None)
    end
end
function UIWidgetFeaturePersonaSkill:OnClickWhenPickUp()
    self:HidePersonaSkillUI()
end

--开始选格子预览
function UIWidgetFeaturePersonaSkill:_PreviewPickUpSkill(skillId, pickUpType)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UICancelActiveSkillSwitchTimer)

    --发动
    GameGlobal.EventDispatcher():Dispatch(GameEventType.CastPersonaSkill, skillId)
    --发动技能后，判断技能类型
    if pickUpType == SkillPickUpType.None then
        Log.fatal("[UIWidgetFeaturePersonaSkill] preview skill pickup type is none")
    else
        local petPstID = 0
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowActiveSkillChooseUI,
            skillId,
            pickUpType,
            petPstID,
            self._isCurPetSkillReady
        )
    end
end