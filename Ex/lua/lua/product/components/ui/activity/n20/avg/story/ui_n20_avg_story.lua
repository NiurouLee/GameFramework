---@class UIN20AVGStory:UIController
---@field passSectionIds boolean[] 本Story中通过的有数据变化的对话id字典 key-【storyId_paragraphId_sectionIdx】 value-true/false
---@field selectedOptionIds boolean[] 本Story中选择过的选项id字典 key-【选项id】 value-true/false
---@field nextNodeId number 下一个结点。每次Init时初始化为默认配置的下一个结点id（End结点一般不配，则设为0）；选项有下一个结点的话，覆盖当前值；
---@field onDialogEndCallback function 对话结束回调
_class("UIN20AVGStory", UIController)
UIN20AVGStory = UIN20AVGStory

function UIN20AVGStory:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = self.mCampaign:GetN20AVGData()
    self.passSectionIds = {}
    self.selectedOptionIds = {}
    self.nextNodeId = 0
    self.onDialogEndCallback = nil

    self.colorInfluenceBG = {Color(0, 0, 0, 0.5), Color(0, 0, 0, 0)}
end

function UIN20AVGStory:OnShow(uiParams)
    local nodeId = uiParams[1]
    self:NodeId(nodeId)
    self._revertBGM = uiParams[4] ~= false
    self._debugMode = uiParams[5]
    self._ignoreBreak = uiParams[6]

    --region 剧情UI
    ---@type UnityEngine.RectTransform
    self._uiCanvasRect = self:GetUIComponent("RectTransform", "UICanvas")
    ---@type UnityEngine.GameObject 剧情根节点
    self._rootGameObject = self:GetGameObject("StoryRoot")
    ---@type UnityEngine.GameObject 对话框根节点
    self._dialogRootGameObject = self:GetGameObject("DialogRoot")
    ---@type UnityEngine.GameObject Mask模板
    self._maskTemplate = self:GetGameObject("MaskTemplate")
    self._maskTemplate:SetActive(false)
    ---@type UnityEngine.GameObject Mask横板模板
    self._maskHorizontalTemplate = self:GetGameObject("MaskHorizontalTemplate")
    self._maskHorizontalTemplate:SetActive(false)
    ---@type UnityEngine.GameObject SpineSliceMask模板
    self._spineSliceMaskTemplate = self:GetGameObject("SpineSliceMaskTemplate")
    self._spineSliceMaskTemplate:SetActive(false)
    ---@type UnityEngine.GameObject SpineSliceMask横版模板
    self._spineSliceHorizontalMaskTemplate = self:GetGameObject("SpineSliceHorizontalMaskTemplate")
    self._spineSliceHorizontalMaskTemplate:SetActive(false)
    ---@type UnityEngine.GameObject CircleMask圆形模板
    self._spineCircleMaskTemplate = self:GetGameObject("SpineCircleMaskTemplate")
    self._spineCircleMaskTemplate:SetActive(false)
    --endregion

    --region 黑边
    ---@type UnityEngine.GameObject
    self._topBlackSide = self:GetGameObject("Top")
    self._topBlackSide:SetActive(false)
    ---@type UnityEngine.GameObject
    self._bottomBlackSide = self:GetGameObject("Bottom")
    self._bottomBlackSide:SetActive(false)
    ---@type UnityEngine.GameObject
    self._leftBlackSide = self:GetGameObject("Left")
    self._leftBlackSide:SetActive(false)
    ---@type UnityEngine.GameObject
    self._rightBlackSide = self:GetGameObject("Right")
    self._rightBlackSide:SetActive(false)
    --endregion

    --region useless
    -- self._buttonRootGameObject = self:GetGameObject("useless")
    -- self._leftButtonRootGameObject = self:GetGameObject("useless")
    --endregion

    --region UI
    ---@type UICustomWidgetPool
    local poolLeader = self:GetUIComponent("UISelectObjectPath", "leader")
    ---@type UIN20AVGActor
    self.leader = poolLeader:SpawnObject("UIN20AVGActor")
    self.goAuto = self:GetGameObject("goAuto")
    ---@type UnityEngine.UI.Image
    self.imgAuto = self:GetUIComponent("Image", "btnAuto")
    self.btnReview = self:GetGameObject("btnReview")
    self.goShowHideUI = self:GetGameObject("goShowHideUI")
    self.btnNext = self:GetGameObject("btnNext")
    ---@type UnityEngine.UI.Image
    self.btnNextImg = self:GetUIComponent("Image", "btnNext")
    self.btnGraph = self:GetGameObject("btnGraph")
    self.btnExit = self:GetGameObject("btnExit")

    self.goOptions = self:GetGameObject("goOptions")
    self:ShowHideOption(false)
    ---@type UICustomWidgetPool
    self.poolOptions = self:GetUIComponent("UISelectObjectPath", "options")
    ---@type UICustomWidgetPool
    self.poolInfluence = self:GetUIComponent("UISelectObjectPath", "influence")

    self.ui = self:GetGameObject("ui")
    self.imgShowUI = self:GetGameObject("imgShowUI")
    self.imgShowUI:SetActive(false)
    --endregion

    ---@type UnityEngine.U2D.SpriteAtlas
    self._uiAtlas = self:GetAsset("UIStory.spriteatlas", LoadType.SpriteAtlas)

    ---@type UILocalizationText
    self.txtDebug = self:GetUIComponent("UILocalizationText", "txtDebug")
    if IsUnityEditor() then
        self.txtDebug.gameObject:SetActive(true)
    else
        self.txtDebug.gameObject:SetActive(false)
    end

    self:AttachEvent(GameEventType.AVGOnDialogEnd, self.AVGOnDialogEnd)
    self:AttachEvent(GameEventType.AVGShowOption, self.AVGShowOption)

    ---@type StateMachine
    self.fsm = StateMachineManager:GetInstance():CreateStateMachine("StateAVGStory", StateAVGStory)
    self.fsm:SetData(self)
    self.fsm:Init(StateAVGStory.Init)

    self:FlushData()
end

function UIN20AVGStory:OnHide()
    self:DetachEvent(GameEventType.AVGOnDialogEnd, self.AVGOnDialogEnd)
    self:DetachEvent(GameEventType.AVGShowOption, self.AVGShowOption)
    self._storyManager:Destroy()
    self._storyManager = nil
    self.fsm:SetData(nil)
    StateMachineManager:GetInstance():DestroyStateMachine(self.fsm.Id)
    self.fsm = nil
end

function UIN20AVGStory:InitStoryManager()
    local node = self.data:GetNodeById(self.nodeId)
    if not node then
        AVGLog("no node. nodeId", self.nodeId)
        return
    end
    local storyId = node.storyId
    self._storyManager =
        StoryManager:New(
        self,
        storyId,
        self._revertBGM,
        self._ignoreBreak
    )
    self._entityInfo = nil
    self._storyManager:Init(self._debugMode, self._entityInfo)
    self.data:StoryManager(self._storyManager)
end

--刷新血量攻略度等数据
function UIN20AVGStory:FlushData()
    local hp, strategies = self:CalcCurData()
    self.leader:Flush(0, hp)
end

-- 变化时播放动效
function UIN20AVGStory:PlayAnimHP(hpDelta)
    self.leader:PlayAnim(hpDelta)
    if hpDelta < 0 then
        UIWidgetHelper.PlayAnimation(self, "anim_effRedDown", "uieff_UIN20_Favorability_downan", 2000)
    end
end

function UIN20AVGStory:NodeId(nodeId)
    if nodeId then
        self.nodeId = nodeId
    else
        return self.nodeId
    end
end

---@return nil | number 设置/返回下一个结点id
function UIN20AVGStory:NextNodeId(nextNodeId)
    if nextNodeId then
        if nextNodeId ~= 0 then --非0才能设置成功
            self.nextNodeId = nextNodeId
        end
    else
        return self.nextNodeId
    end
end

--region 已经历的小节
---@param sectionSign string 对话签名【storyId_paragraphId_sectionIdx】
function UIN20AVGStory:PassSectionId(sectionSign)
    if sectionSign then
        return self.passSectionIds[sectionSign]
    else
        return self.passSectionIds
    end
end

---@param sectionSign string 对话签名【storyId_paragraphId_sectionIdx】
function UIN20AVGStory:SetPassSectionId(sectionSign, b)
    if b then
        self.passSectionIds[sectionSign] = true
    else
        self.passSectionIds[sectionSign] = nil
    end
    if IsUnityEditor() then
        local signStr = ""
        for sign, b in pairs(self.passSectionIds) do
            if b then
                signStr = signStr .. sign .. ";"
            end
        end
        AVGLog("------------passSectionIds changed------------", signStr)
    end
end

function UIN20AVGStory:ClearPassSectionIds()
    self.passSectionIds = {}
    self:FlushData()
end

--endregion

--region 已选择的选项
function UIN20AVGStory:SelectedOptionId(optionId)
    if optionId then
        return self.selectedOptionIds[optionId]
    else
        return self.selectedOptionIds
    end
end

---@param optionId number 选项id
function UIN20AVGStory:SetSelectedOptionId(optionId, b)
    if b then
        self.selectedOptionIds[optionId] = true
    else
        self.selectedOptionIds[optionId] = nil
    end
end

function UIN20AVGStory:ClearSelectedOptionIds()
    self.selectedOptionIds = {}
end

--endregion

---计算当前数据
---@return number, number[] 当前主角血量，当前队员攻略度数组
function UIN20AVGStory:CalcCurData()
    --1.取初始值
    local nodeId = self:NodeId()
    local node = self.data:GetNodeById(nodeId)
    local hp, strategies = node:StartData()
    --2.计算结果
    local node = self.data:GetNodeById(nodeId)
    local passSectionIds = self:PassSectionId()
    if passSectionIds then
        for sign, b in pairs(passSectionIds) do
            if b then
                local tNumbers = N20AVGData.Sign2Numbers(sign)
                local storyId = tNumbers[1]
                local paragraphId = tNumbers[2]
                local sectionIdx = tNumbers[3]
                local paragraph = node:GetParagraphByParagraphId(paragraphId)
                local dialog = paragraph:GetDialogBySectionIdx(sectionIdx)
                local vc = dialog:ValueChange()
                if vc then
                    for index, value in ipairs(vc) do
                        if index == 1 then
                            hp = hp + value
                        else
                            local indexPartner = index - 1
                            if strategies and strategies[indexPartner] then
                                strategies[indexPartner] = strategies[indexPartner] + value
                            end
                        end
                    end
                end
            end
        end
    end
    --3.Clamp数值
    local minHP, maxHP = self.data.actorLeader.min, self.data.actorLeader.max
    hp = Mathf.Clamp(hp, minHP, maxHP)
    for index, _ in ipairs(strategies) do
        local partner = self.data.actorPartners[index]
        local minStrategy, maxStrategy = partner.min, partner.max
        strategies[index] = Mathf.Clamp(strategies[index], minStrategy, maxStrategy)
    end
    return hp, strategies
end

--region Update
function UIN20AVGStory:OnUpdate(deltaTimeMS)
    if self.fsm then
        self.fsm:OnUpdate(deltaTimeMS)
    end
end

---由State驱动的Update
function UIN20AVGStory:UpdateDriveByState(deltaTimeMS)
    if not self._storyManager then
        return
    end
    self._storyManager:Update(deltaTimeMS)
    if self._storyManager:IsEnd() then
        self:_EndStory()
        return
    end
end

---story结束处理
---@private
function UIN20AVGStory:_EndStory()
    GameGlobal.UIStateManager():SetBlackSideVisible(true) --恢复黑边
    self.fsm:ChangeState(StateAVGStory.BECheck, self._storyManager._auto or false) --故事结束检测BE
end

--endregion

function UIN20AVGStory:SetBlackSideSize(width, height)
    self._topBlackSide:GetComponent("RectTransform").sizeDelta = Vector2(0, height)
    self._bottomBlackSide:GetComponent("RectTransform").sizeDelta = Vector2(0, height)
    self._topBlackSide:SetActive(height > 0)
    self._bottomBlackSide:SetActive(height > 0)
    self._leftBlackSide:GetComponent("RectTransform").sizeDelta = Vector2(width, 0)
    self._rightBlackSide:GetComponent("RectTransform").sizeDelta = Vector2(width, 0)
    self._leftBlackSide:SetActive(width > 0)
    self._rightBlackSide:SetActive(width > 0)
end

--region Get
function UIN20AVGStory:GetCanvasSize()
    return self._uiCanvasRect.sizeDelta.x, self._uiCanvasRect.sizeDelta.y
end

--endregion

--region AVGOnDialogEnd
function UIN20AVGStory:AVGOnDialogEnd()
    self.fsm:ChangeState(StateAVGStory.BECheck, self._storyManager._auto or false) --每次对话结束都检测BE
end

---@param onDialogEndCallback function
function UIN20AVGStory:SetAVGOnDialogEnd(onDialogEndCallback)
    self.onDialogEndCallback = onDialogEndCallback ---设置对话结束回调
end

--endregion

--region AVGShowOption
function UIN20AVGStory:AVGShowOption()
    self.fsm:ChangeState(StateAVGStory.Option)
end

function UIN20AVGStory:ShowHideOption(isShow)
    self.goOptions:SetActive(isShow)
    self.btnNextImg.raycastTarget = (not isShow)
end

--endregion

function UIN20AVGStory:IsAuto()
    local isAuto = self._storyManager._auto
    return isAuto
end

---从开nodeId结点始播放剧情
---@param nodeId number 结点id
function UIN20AVGStory:PlayFromBegain(nodeId)
    if self._storyManager._storyEntityList then
        for index, storyEntity in ipairs(self._storyManager._storyEntityList) do
            local go = storyEntity._gameObject
            UnityEngine.GameObject.Destroy(go)
        end
    end
    self._storyManager:Destroy()
    self:NodeId(nodeId) --设置当前结点
    self.fsm:ChangeState(StateAVGStory.Init)
end

--region OnClick
function UIN20AVGStory:bgOnClick(go)
    Log.fatal("### bgOnClick")
end

function UIN20AVGStory:btnAutoOnClick(go)
    if self:IsAuto() then
        self.fsm:ChangeState(StateAVGStory.Play)
    else
        self.fsm:ChangeState(StateAVGStory.Auto)
    end
end

function UIN20AVGStory:btnReviewOnClick(go)
    self:ShowDialog("UIN20AVGReview")
end

function UIN20AVGStory:btnShowHideUIOnClick(go)
    self._storyManager:HideUI(true)
    self.ui:SetActive(false)
    self.imgShowUI:SetActive(true)
end

function UIN20AVGStory:imgShowUIOnClick(go)
    self._storyManager:HideUI(false)
    self.ui:SetActive(true)
    self.imgShowUI:SetActive(false)
end

function UIN20AVGStory:btnNextOnClick(go)
    self.fsm:ChangeState(StateAVGStory.Next)
end

function UIN20AVGStory:btnGraphOnClick(go)
    self:ShowDialog("UIN20AVGGraph", true)
end

function UIN20AVGStory:btnExitOnClick(go)
    PopupManager.Alert(
        "UICommonMessageBox",
        PopupPriority.Normal,
        PopupMsgBoxType.OkCancel,
        "",
        StringTable.Get("str_avg_n20_exit_plot_hint"),
        function()
            self:SwitchState(UIStateType.UIN20AVGMain)
        end
    )
end

--endregion

--region StateAVGStory
StateAVGStory = {
    Init = 0,
    Play = 1, --普通播放
    Auto = 2, --自动播放
    Next = 3, --快进到下一个关键点
    Option = 4, --选项状态
    BECheck = 5, --BE检测阶段
    Over = 6 --一个故事结点结束
}
--endregion
