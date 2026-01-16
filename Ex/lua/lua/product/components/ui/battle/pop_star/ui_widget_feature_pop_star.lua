---@class UIWidgetFeaturePopStar : UICustomWidget
_class("UIWidgetFeaturePopStar", UICustomWidget)
UIWidgetFeaturePopStar = UIWidgetFeaturePopStar

--初始化
function UIWidgetFeaturePopStar:OnShow(uiParams)
    self:InitWidget()
end

function UIWidgetFeaturePopStar:GetFeatureType()
    return FeatureType.PopStar
end

--获取ui组件
function UIWidgetFeaturePopStar:InitWidget()
    --generated--
    ---@type UnityEngine.UI.Image
    self._imgFeaturePopStar = self:GetUIComponent("Image", "UIWidgetFeaturePopStar")

    self._imageNormalGo = self:GetGameObject("ImageNormal")
    self._imageWarningGo = self:GetGameObject("ImageWarning")

    ---@type UnityEngine.GameObject
    self._skillInfoGenGo = self:GetGameObject("SkillInfoGen")
    self._skillInfoGenGo:SetActive(false)

    ---@type UICustomWidgetPool 技能UI widget pool
    self._skillPool = self:GetUIComponent("UISelectObjectPath", "SkillInfoGen")
    ---@type UIWidgetFeaturePersonaSkillInfo 技能UI
    self._skillUI = self._skillPool:SpawnObject("UIWidgetFeaturePersonaSkillInfo")

    ---@type UILocalizationText
    self._powerText = self:GetUIComponent("UILocalizationText", "power")
    self._powerTextGo = self:GetGameObject("power")

    ---@type UIBattle
    self._uiBattle = nil
    self._switchTimeEvent = nil
    self._switchTimeLength = 100 --切换头像的延迟时间

    self:AttachEvent(GameEventType.PersonaPowerChange, self.OnPersonaPowerChange)
    self:AttachEvent(GameEventType.OnClickWhenPickUp, self.OnClickWhenPickUp)
    self:AttachEvent(GameEventType.UICancelChooseTarget, self.OnChooseTargetCancel)
    self:AttachEvent(GameEventType.UIChooseTargetGray, self.HandleUIChooseTargetGray)
    self:AttachEvent(GameEventType.PickUPInvalidGridCancelActiveSkill, self.OnPickInvalidGridCancel)
    self._power = 0
    self._ready = 0

    self:OnPersonaPowerChange(self:GetFeatureType(), self._power, self._ready)
    --generated end--
end

function UIWidgetFeaturePopStar:OnPersonaPowerChange(featureType, power, ready)
    if not (self:GetFeatureType() == featureType) then
        return
    end

    if power <= 0 then
        power = 0
    end

    if ready then
        if self._ready ~= ready then
            self._ready = ready
        end
    end
    if self._power ~= power then
        self._power = power
    end

    self._powerText:SetText(self._power)
    self:_RefreshStateBg()
end

function UIWidgetFeaturePopStar:_RefreshStateBg()
    self._imageNormalGo:SetActive(self._ready ~= 1)
    self._imageWarningGo:SetActive(self._ready == 1)
end

function UIWidgetFeaturePopStar:SetUIBattle(uiBattle)
    self._uiBattle = uiBattle
end

function UIWidgetFeaturePopStar:GetUIBattle()
    return self._uiBattle
end

--设置数据
---@param popStarInitData FeatureEffectParamPopStar
function UIWidgetFeaturePopStar:SetData(popStarInitData)
    self._featureInitData = popStarInitData
    self._skillID = self._featureInitData:GetMasterSkillID()
    self._skillConfigData = ConfigServiceHelper.GetSkillConfigData(self._skillID)
end

--按钮点击
function UIWidgetFeaturePopStar:UIWidgetFeaturePopStarOnClick(go)
    self:OnClickUI()
end

function UIWidgetFeaturePopStar:OnClickUI()
    ---只有在局内是等待输入的时候，才能显示主动技弹框
    local coreGameStateID = GameGlobal:GetInstance():CoreGameStateID()
    local enableInput = GameGlobal:GetInstance():IsInputEnable()

    if coreGameStateID == GameStateID.WaitInput and enableInput == true then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.PreClickPetHead, self._skillID)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickPersonaSkill, self:GetFeatureType(), self._skillID)
        self:ShowPersonaSkillUI()
    elseif coreGameStateID == GameStateID.PreviewActiveSkill or
        coreGameStateID == GameStateID.PickUpActiveSkillTarget then
        if self._switchTimeEvent == nil then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.UISwitchActiveSkillUI)

            --切换预览
            self:ShowPersonaSkillUI()

            ---先通知战斗，记录一次技能ID
            GameGlobal.EventDispatcher():Dispatch(GameEventType.PreClickPetHead, self._skillID)
            --通知战斗，切换预览
            self._switchTimeEvent = GameGlobal.Timer():AddEvent(
                self._switchTimeLength,
                function()
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickPersonaSkill, self:GetFeatureType(),
                        self._skillID)
                    self._switchTimeEvent = nil
                    Log.notice("preview persona skill", self._skillID)
                end
            )
        else
            Log.notice("still in switch", self._skillID)
        end
    end
end

---显示技能释放UI
function UIWidgetFeaturePopStar:ShowPersonaSkillUI()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIFeatureSkillInfoShow, true, self:GetFeatureType())
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

    self._skillUI:Init(self:GetFeatureType(), self._skillID, nil, self._power, canCast, castCb, cancelCb)
    ---@type SkillPickUpType
    local pickUpType = skillConfigData:GetSkillPickType()
    self._pickUpType = pickUpType

    --选格子类型的技能，点头像直接开始预览，不需要再点发动按钮
    if pickUpType ~= SkillPickUpType.None then
        self._isCurPetSkillReady = canCast
        self:_PreviewPickUpSkill(self._skillID, pickUpType)
        self._skillUI:ShowCancelBtn(false)
    else
        --直接发动类的技能需要点击空白取消
        self._skillUI:ShowCancelBtn(true)
    end

    self._skillInfoGenGo:SetActive(true)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickUI2ClosePreviewMonster)
end

---隐藏技能信息界面
function UIWidgetFeaturePopStar:HidePersonaSkillUI()
    self._skillInfoGenGo:SetActive(false)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIFeatureSkillInfoShow, false, self:GetFeatureType())
end

--此函数和UI状态无关，可以直接调用
function UIWidgetFeaturePopStar:OnCastSkill(castSkillID, pickUpType)
    --发动技能后，判断技能类型
    if pickUpType == SkillPickUpType.None then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.CastPersonaSkill, castSkillID)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UIResetLastPreviewPetId)
    elseif pickUpType == SkillPickUpType.PickSwitchInstruction then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, true)
        local petPstID = 0
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActiveSkillPickUp, castSkillID, petPstID)
    else
        GameGlobal.EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, false)
        local petPstID = 0
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActiveSkillPickUp, castSkillID, petPstID)
    end
    self:HidePersonaSkillUI()
end

function UIWidgetFeaturePopStar:OnCancelSkill()
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

function UIWidgetFeaturePopStar:OnSwitchActiveSkillUI()
    self:HidePersonaSkillUI()
end

function UIWidgetFeaturePopStar:OnChooseTargetConfirm()
    if self._skillID > 0 and self._uiBattle:GetCurPetActiveSkillId() == self._skillID then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UIResetLastPreviewPetId)
        self:HidePersonaSkillUI()
    end
end

function UIWidgetFeaturePopStar:OnChooseTargetCancel()
    self:HidePersonaSkillUI()
end

function UIWidgetFeaturePopStar:OnPickInvalidGridCancel()
    self:HidePersonaSkillUI()
end

function UIWidgetFeaturePopStar:OnClickWhenPickUp()
    self:HidePersonaSkillUI()
end

--开始选格子预览
function UIWidgetFeaturePopStar:_PreviewPickUpSkill(skillId, pickUpType)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UICancelActiveSkillSwitchTimer)

    --发动
    GameGlobal.EventDispatcher():Dispatch(GameEventType.CastPersonaSkill, skillId)
    --发动技能后，判断技能类型
    if pickUpType == SkillPickUpType.None then
        Log.fatal("[UIWidgetFeaturePopStar] preview skill pickup type is none")
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

function UIWidgetFeaturePopStar:HandleUIChooseTargetGray()
    if self._skillID > 0 and self._uiBattle:GetCurPetActiveSkillId() == self._skillID then
        local bReady = (self._ready == 1)
        if not bReady then
            ToastManager.ShowToast(StringTable.Get("str_n31_popstar_battle_cast_skill_count_not_enough"))
        end
    end
end
