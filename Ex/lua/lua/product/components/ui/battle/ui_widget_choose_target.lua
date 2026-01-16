--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    从UIBattle里拆出来的主动技点选面板
    定位是只处理点选面板相关的UI操作，并不在意当前的Caster是机关还是光灵
**********************************************************************************************
]] --------------------------------------------------------------------------------------------

_class("UIWidgetChooseTarget", UICustomWidget)
---@class UIWidgetChooseTarget:UICustomWidget
UIWidgetChooseTarget = UIWidgetChooseTarget

function UIWidgetChooseTarget:Constructor()
    self:AttachEvent(GameEventType.RefreshPickUpNum, self.RefreshPickUpNum)
    self:AttachEvent(GameEventType.ChangePickUpText, self.ChangePickUpText)
end

function UIWidgetChooseTarget:OnShow()
    --允许模拟输入
    self.enableFakeInput = true

    self._curActiveSkillID = -1
    self._curPetPstID = -1

    ---主动技选择
    self._chooseTargetPanel = self:GetGameObject("ChooseTargetPanel")
    self._choosehlg = self:GetGameObject("hlg")
    self._chooseColOrRow = self:GetGameObject("colOrRow")
    self._chooseRotate = self:GetGameObject("rotate")
    self._chooseSwitch = self:GetGameObject("switch")
    self._chooseDirection = self:GetGameObject("direction")

    self._chooseDirText = self:GetUIComponent("UILocalizationText", "DirectionText")
    self._chooseDirText:SetText(StringTable.Get("str_battle_choose_dir"))

    self._chooseConfimText = self:GetUIComponent("UILocalizationText", "ActiveSkillConfigText")
    self._chooseConfimText:SetText(StringTable.Get("str_common_cancel"))

    self._choosePreText = self:GetUIComponent("UILocalizationText", "PreText")
    self._choosePreText:SetText(StringTable.Get("str_battle_choose_select"))
    
    self._chooseNumText = self:GetUIComponent("UILocalizationText", "SelectTargetNumText")
    self._chooseNumText:SetText("0")
    --主动取消按钮
    ---@type UnityEngine.UI.Button
    self._activeSkillCancelBtn = self:GetUIComponent("Button", "btnActiveSkillCancel")
    self._activeSkillCancelBtn.interactable = true
    --主动技确认按钮
    ---@type UnityEngine.UI.Button
    self._btnConfirmActiveSkill = self:GetUIComponent("Button", "btnActiveSkillConfirm")
    self._btnConfirmActiveSkillGO = self:GetGameObject("btnActiveSkillConfirm")
    self._btnConfirmActiveSkill.interactable = false
    self._btnConfirmActiveSkillGO:SetActive(false)
    ---@type UnityEngine.UI.Button
    self._btnConfirmActiveSkillGray = self:GetUIComponent("Button", "btnActiveSkillConfirmGray")
    self._btnConfirmActiveSkillGrayGO = self:GetGameObject("btnActiveSkillConfirmGray")
    self._btnConfirmActiveSkillGrayGO:SetActive(true)
    self._btnConfirmActiveSkillGray.interactable = true

    self._btnconfirmText = self:GetUIComponent("UILocalizationText", "ConfirmText")
    self._btnconfirmText:SetText(StringTable.Get("str_battle_confirm_cast"))

    self._btnconfirmTextGray = self:GetUIComponent("UILocalizationText", "GrayConfirmText")
    self._btnconfirmText:SetText(StringTable.Get("str_battle_confirm_cast"))
end

function UIWidgetChooseTarget:OnHide()

end

function UIWidgetChooseTarget:InitChooseTargetWidget(skillID,petPstID)
    self._curActiveSkillID = skillID
    self._curPetPstID = petPstID
end

function UIWidgetChooseTarget:ShowChooseTargetPanel(isShow)
    self._chooseTargetPanel:SetActive(isShow)
end

----@param state SkillPickUpTextStateType
function UIWidgetChooseTarget:ChangePickUpText(state)
    if state == SkillPickUpTextStateType.Rotate or state == SkillPickUpTextStateType.Switch or
        state == SkillPickUpTextStateType.ChooseDir or state == SkillPickUpTextStateType.ColOrRow
    then
        self._choosehlg:SetActive(false)
    else
        self._choosehlg:SetActive(true)
    end
    self._chooseColOrRow:SetActive(state == SkillPickUpTextStateType.ColOrRow)
    self._chooseRotate:SetActive(state == SkillPickUpTextStateType.Rotate)
    self._chooseSwitch:SetActive(state == SkillPickUpTextStateType.Switch)
    self._chooseDirection:SetActive(state == SkillPickUpTextStateType.ChooseDir)

    if state == SkillPickUpTextStateType.Normal then
        self._chooseDirText:SetText(StringTable.Get("str_battle_choose_point"))
    elseif state == SkillPickUpTextStateType.Tel then
        self._chooseDirText:SetText(StringTable.Get("str_battle_choose_monster_tel_pos"))
    elseif state == SkillPickUpTextStateType.Direction then
        self._chooseDirText:SetText(StringTable.Get("str_battle_choose_dir"))
    elseif state == SkillPickUpTextStateType.Target then
        self._chooseDirText:SetText(StringTable.Get("str_battle_choose_target"))
    end

    --播放选中格子/方向音效
    ---AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)
end

function UIWidgetChooseTarget:SetChooseUIText(pickUpType)
    ---@type SkillConfigData
    local skillConfigData = ConfigServiceHelper.GetSkillConfigData(self._curActiveSkillID, self._curPetPstID)
    local pickUpParam = skillConfigData:GetSkillPickParam()
    local pickUpCount = pickUpParam[1]
    self._choosePreText:SetText(StringTable.Get("str_battle_choose_select"))
    if pickUpType == SkillPickUpType.Instruction 
        or pickUpType == SkillPickUpType.PickAndTeleportInst 
        or pickUpType == SkillPickUpType.PickDiffPowerInstruction 
        or pickUpType == SkillPickUpType.Akexiya
        or pickUpType == SkillPickUpType.Yeliya
        or pickUpType == SkillPickUpType.Hati
    then
        self._chooseNumText:SetText(tostring(pickUpCount))
        self._chooseDirText:SetText(StringTable.Get("str_battle_choose_point"))
    elseif pickUpType == SkillPickUpType.DirectionInstruction then
        self._chooseNumText:SetText(tostring(pickUpCount))
        self._chooseDirText:SetText(StringTable.Get("str_battle_choose_dir"))
    elseif pickUpType == SkillPickUpType.ColorInstruction then
        self._chooseNumText:SetText(tostring(pickUpCount))
        self._chooseDirText:SetText(StringTable.Get("str_battle_choose_color"))
    elseif pickUpType == SkillPickUpType.PickAndDirectionInstruction or pickUpType == SkillPickUpType.PickOnePosAndRotate or
        pickUpType == SkillPickUpType.LineAndDirectionInstruction or pickUpType == SkillPickUpType.PickAndDirectionInstruction2
    then
        self._chooseNumText:SetText(tostring(1))
        self._chooseDirText:SetText(StringTable.Get("str_battle_choose_point"))
    elseif pickUpType == SkillPickUpType.PickDirOrSelf then
        self._chooseNumText:SetText(tostring(pickUpCount))
        self._chooseDirText:SetText(StringTable.Get("str_battle_choose_point_or_dir"))
    elseif pickUpType == SkillPickUpType.LinkLine then
        self._choosePreText:SetText(StringTable.Get("str_battle_choose_link"))
        self._chooseNumText:SetText(tostring(pickUpCount))
        self._chooseDirText:SetText(StringTable.Get("str_battle_choose_point"))
    elseif pickUpType == SkillPickUpType.PickUpGridTogether then
        self._chooseNumText:SetText(tostring("1"))
        self._chooseDirText:SetText(StringTable.Get("str_battle_choose_point"))
    end
end

function UIWidgetChooseTarget:RefreshPickUpNum(canPickUpNum)
    self._chooseNumText:SetText(canPickUpNum)
    --播放选中格子/方向音效
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)
end

function UIWidgetChooseTarget:SetPickUpActiveBtnState(canCastState)
    self._btnConfirmActiveSkill.interactable = canCastState
    self._btnConfirmActiveSkillGO:SetActive(canCastState)
    self._btnConfirmActiveSkillGrayGO:SetActive(not canCastState)
    self._btnConfirmActiveSkillGray.interactable = not canCastState
end

---处理点击取消按钮，发送事件给UIBattle
function UIWidgetChooseTarget:BtnActiveSkillCancelOnClick()
    if BattleStatHelper.GetAutoFightStat() then
        return
    end
    self:HandleActiveSkillCancel()
end
function UIWidgetChooseTarget:HandleActiveSkillCancel()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UICancelChooseTarget)

    self:SetPickUpActiveBtnState(false) --每次取消释放主动技之后让发动按钮不可用，不然第一个宝宝放完技能后第二个宝宝可以不选格子就放技能
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundCancel) --播放取消按钮音效
end

---点击确认按钮，发送事件给UIBattle
function UIWidgetChooseTarget:BtnActiveSkillConfirmOnClick()
    if BattleStatHelper.GetAutoFightStat() then
        return
    end

    self:HandleActiveSkillConfirm()
end

---点击灰色确认按钮，发送事件给UIBattle
function UIWidgetChooseTarget:BtnActiveSkillConfirmGrayOnClick()
    if BattleStatHelper.GetAutoFightStat() then
        return
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIChooseTargetGray)
end

function UIWidgetChooseTarget:HandleActiveSkillConfirm()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIChooseTargetConfirm)

    self:ShowChooseTargetPanel(false)

    --每次放完主动技之后让发动按钮不可用，不然第一个宝宝放完技能后第二个宝宝可以不选格子就放技能
    self:SetPickUpActiveBtnState(false)
end