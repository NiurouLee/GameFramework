---@class UIN28AVGStory:UIController
---@field passSectionIds boolean[] 本Story中通过的有数据变化的对话id字典 key-【storyId_paragraphId_sectionIdx】 value-true/false
---@field selectedOptionIds boolean[] 本Story中选择过的选项id字典 key-【选项id】 value-true/false
---@field nextNodeId number 下一个结点。每次Init时初始化为默认配置的下一个结点id（End结点一般不配，则设为0）；选项有下一个结点的话，覆盖当前值；
---@field onDialogEndCallback function 对话结束回调
_class("UIN28AVGStory", UIController)
UIN28AVGStory = UIN28AVGStory

function UIN28AVGStory:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = self.mCampaign:GetN28AVGData()
    self.passSectionIds = {}
    self.passSectionTimes = {}
    self.selectedOptionIds = {}
    self.showEvienceCountList = {}
    self.cacheUserEvidences = {}
    self.nextNodeId = 0
    self.onDialogEndCallback = nil

    self.colorInfluenceBG = {Color(0, 0, 0, 0.5), Color(0, 0, 0, 0)}
end

function UIN28AVGStory:OnShow(uiParams)
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
    ---@type UIN28AVGActor
    self.leader = poolLeader:SpawnObject("UIN28AVGActor")
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
    self.goOptionsAnim = self:GetUIComponent("Animation", "goOptions")
    self.goGainEvidence = self:GetGameObject("goGainEvidence")
    self.goShowEvidence = self:GetGameObject("goShowEvidence")
    self:ShowHideOption(false)
    ---@type UICustomWidgetPool
    self.poolOptions = self:GetUIComponent("UISelectObjectPath", "options")
    ---@type UICustomWidgetPool
    self.poolInfluence = self:GetUIComponent("UISelectObjectPath", "influence")
    ---@type UICustomWidgetPool
    self.poolGainEvidence = self:GetUIComponent("UISelectObjectPath", "gainEvidence")
    ---@type UICustomWidgetPool
    self.poolShowEvidence = self:GetUIComponent("UISelectObjectPath", "showEvidence")
    self.anim = self:GetUIComponent("Animation", "anim")

    self.btnEvidenceBook = self:GetGameObject("btnEvidenceBook")

    self.ui = self:GetGameObject("ui")
    self.imgShowUI = self:GetGameObject("imgShowUI")
    self.imgShowUI:SetActive(false)
    --endregion
    self.showEvidenceEff = self:GetGameObject("showEvidenceEff")
    self.jumpEff = self:GetGameObject("jumpEff")
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
    self:AttachEvent(GameEventType.AVGGainEvidence, self.AVGGainEvidence)
    self:AttachEvent(GameEventType.AVGShowEvdience, self.AVGShowEvdience)
    self:AttachEvent(GameEventType.AVGHideEvdienceBook, self.AVGHideEvdienceBook)
    self:AttachEvent(GameEventType.AVGStopAutoState, self.StopAutoState)

    ---@type StateMachine
    self.fsm = StateMachineManager:GetInstance():CreateStateMachine("N28StateAVGStory", N28StateAVGStory)
    self.fsm:SetData(self)
    self.fsm:Init(N28StateAVGStory.Init)

    self:FlushData()
end

function UIN28AVGStory:OnHide()
    if self._playAnimationTask then
        GameGlobal.TaskManager():KillTask(self._playAnimationTask)
        self._playAnimationTask = nil
        self:UnLock("UIN28AVGStory_ShowJumpAnim")
    end
    self:DetachEvent(GameEventType.AVGOnDialogEnd, self.AVGOnDialogEnd)
    self:DetachEvent(GameEventType.AVGShowOption, self.AVGShowOption)
    self:DetachEvent(GameEventType.AVGGainEvidence, self.AVGGainEvidence)
    self:DetachEvent(GameEventType.AVGShowEvdience, self.AVGShowEvdience)
    self:DetachEvent(GameEventType.AVGHideEvdienceBook, self.AVGHideEvdienceBook)
    self:DetachEvent(GameEventType.AVGStopAutoState, self.StopAutoState)
    self._storyManager:Destroy()
    self._storyManager = nil
    self.fsm:SetData(nil)
    StateMachineManager:GetInstance():DestroyStateMachine(self.fsm.Id)
    self.fsm = nil
end

function UIN28AVGStory:InitStoryManager()
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

--刷新血量攻略度,律师笔记状态等数据
function UIN28AVGStory:FlushData(anim)
    local hp, strategies = self:CalcCurData()
    self.leader:Flush(0, hp, true)
end

-- 变化时播放动效
function UIN28AVGStory:PlayAnimHP(hpDelta)
    -- self.leader:PlayAnim(hpDelta)
    -- if hpDelta < 0 then
    --     UIWidgetHelper.PlayAnimation(self, "anim_effRedDown", "uieff_UIN28_Favorability_downan", 2000)
    -- end
end

function UIN28AVGStory:NodeId(nodeId)
    if nodeId then
        self.nodeId = nodeId
    else
        return self.nodeId
    end
end

---@return nil | number 设置/返回下一个结点id
function UIN28AVGStory:NextNodeId(nextNodeId)
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
function UIN28AVGStory:PassSectionId(sectionSign)
    if sectionSign then
        return self.passSectionIds[sectionSign]
    else
        return self.passSectionIds
    end
end

function UIN28AVGStory:PassSectionTimes(sectionSign)
    if sectionSign then
        return self.passSectionTimes[sectionSign]
    else
        return self.passSectionTimes
    end
end

--region 已经历的小节
---@param sectionSign string 对话签名【storyId_paragraphId_sectionIdx】
function UIN28AVGStory:SetPassSectionTimes(sectionSign)
    self.passSectionTimes[sectionSign] = self.passSectionTimes[sectionSign] or 0
    self.passSectionTimes[sectionSign] = self.passSectionTimes[sectionSign] + 1
end

function UIN28AVGStory:GetShowEvienceCount(manualID)
    return self.showEvienceCountList[manualID]
end

function UIN28AVGStory:SetShowEvienceCount(manualID)
    self.showEvienceCountList[manualID] = self.showEvienceCountList[manualID] or 0
    self.showEvienceCountList[manualID] = self.showEvienceCountList[manualID] + 1
end

function UIN28AVGStory:ClearShowEvienceCount()
    self.showEvienceCountList = {}
end

--初始化证据存档缓存
function UIN28AVGStory:CopyEvidenceDataInCache()
    local nodeId = self:NodeId()
    local node = self.data:GetNodeById(nodeId)
    self.cacheUserEvidences = table.shallowcopy(node:GetEvidenceData())
end

--改变存档中证据
function UIN28AVGStory:ChangeEvidenceDataInCache(eid, isAdd)
    if isAdd then
        table.insert(self.cacheUserEvidences, eid)
    else
        table.removev(self.cacheUserEvidences, eid)
    end
end

--取缓存
function UIN28AVGStory:GetEvidenceDataInCache()
    if self._debugMode and #self.cacheUserEvidences == 0 then
        for _, v in pairs(self.data.allEvidences) do
            table.insert(self.cacheUserEvidences, v.id) 
        end
    end 
    return self.cacheUserEvidences
end

---@param sectionSign string 对话签名【storyId_paragraphId_sectionIdx】
function UIN28AVGStory:SetPassSectionId(sectionSign, b)
    if b then
        self:SetPassSectionTimes(sectionSign)
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

function UIN28AVGStory:ClearPassSectionIds()
    self.passSectionIds = {}
    self.passSectionTimes = {}
    self:FlushData(true)
end

function UIN28AVGStory:InitEvidenceBookShowStatus()
    --律师笔记
    local node = self.data:GetNodeById(self.nodeId)
    self.isNodeShowEvidenceBook = node.hideEvidenceBook == 1
    self.btnEvidenceBook:SetActive(self.isNodeShowEvidenceBook)
end

--endregion

--region 已选择的选项
function UIN28AVGStory:SelectedOptionId(optionId)
    if optionId then
        return self.selectedOptionIds[optionId]
    else
        return self.selectedOptionIds
    end
end

---@param optionId number 选项id
function UIN28AVGStory:SetSelectedOptionId(optionId, b)
    if b then
        self.selectedOptionIds[optionId] = true
    else
        self.selectedOptionIds[optionId] = nil
    end
end

function UIN28AVGStory:ClearSelectedOptionIds()
    self.selectedOptionIds = {}
end

--endregion

---计算当前数据
---@return number, number[] 当前主角血量，当前队员攻略度数组
function UIN28AVGStory:CalcCurData()
    --1.取初始值
    local nodeId = self:NodeId()
    local node = self.data:GetNodeById(nodeId)
    local hp, strategies = node:StartData()
    --2.计算结果
    local node = self.data:GetNodeById(nodeId)
    local passSectionTimes = self:PassSectionTimes()
    if passSectionTimes then
        for sign, b in pairs(passSectionTimes) do
            if b then
                local tNumbers = N28AVGData.Sign2Numbers(sign)
                local storyId = tNumbers[1]
                local paragraphId = tNumbers[2]
                local sectionIdx = tNumbers[3]
                local paragraph = node:GetParagraphByParagraphId(paragraphId)
                local dialog = paragraph:GetDialogBySectionIdx(sectionIdx)
                local vc = dialog:ValueChange()
                if vc then
                    for index, value in ipairs(vc) do
                        if index == 1 then
                            for i = 1, b do
                                hp = hp + value
                            end
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
function UIN28AVGStory:OnUpdate(deltaTimeMS)
    if self.fsm then
        self.fsm:OnUpdate(deltaTimeMS)
    end
end

---由State驱动的Update
function UIN28AVGStory:UpdateDriveByState(deltaTimeMS)
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
function UIN28AVGStory:_EndStory()
    GameGlobal.UIStateManager():SetBlackSideVisible(true) --恢复黑边
    self.fsm:ChangeState(N28StateAVGStory.BECheck, self._storyManager._auto or false) --故事结束检测BE
end

--endregion

function UIN28AVGStory:SetBlackSideSize(width, height)
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
function UIN28AVGStory:GetCanvasSize()
    return self._uiCanvasRect.sizeDelta.x, self._uiCanvasRect.sizeDelta.y
end

--endregion

--region AVGOnDialogEnd
function UIN28AVGStory:AVGOnDialogEnd()
    self.fsm:ChangeState(N28StateAVGStory.BECheck, self._storyManager._auto or false) --每次对话结束都检测BE
end

---@param onDialogEndCallback function
function UIN28AVGStory:SetAVGOnDialogEnd(onDialogEndCallback)
    self.onDialogEndCallback = onDialogEndCallback ---设置对话结束回调
end

--endregion

--region AVGShowOption
function UIN28AVGStory:AVGShowOption()
    self.fsm:ChangeState(N28StateAVGStory.Option)
end

function UIN28AVGStory:AVGGainEvidence(eventCfg, uiDialog)
    self.fsm:ChangeState(N28StateAVGStory.GainEvidence, eventCfg, uiDialog)
end

function UIN28AVGStory:AVGShowEvdience(eventCfg, trackData, uiDialog)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIN28AVGStoryShowEvidence)
    self.fsm:ChangeState(N28StateAVGStory.ShowEvidence, eventCfg, trackData,  uiDialog)
end

function UIN28AVGStory:StopAutoState()
    self.fsm:ChangeState(N28StateAVGStory.Play)
end

function UIN28AVGStory:AVGHideEvdienceBook(eventCfg, uiDialog)
    local flag = eventCfg.Params[1] == 1
    self.btnEvidenceBook:SetActive(flag)
    self.isNodeShowEvidenceBook = flag
    if flag then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIN28AVGStoryEvidenceBook)
        local guideModule = GameGlobal.GetModule(GuideModule)
        if guideModule:IsGuideProcess(118005) then
            self._storyManager:ForceJumpStop(true)
            if uiDialog:GetAuto(1) then
                uiDialog:SetAuto(false, 1)
            end
            GameGlobal.TaskManager():StartTask(
            function(TT)
                YIELD(TT)
                self._storyManager:ForceJumpStop(false)
            end)
        end
    end
end

function UIN28AVGStory:ShowJumpAnim(callback)
    self:Lock("UIN28AVGStory_ShowJumpAnim")
    self.jumpEff:SetActive(true)
    local anim = self.jumpEff:GetComponent("Animation")
    self._playAnimationTask = GameGlobal.TaskManager():StartTask(
        function(TT)
            anim:Play("uieff_UIN28AVGStory_star")
            YIELD(TT, 567)
            callback()
            YIELD(TT, 100)
            anim:Play("uieff_UIN28AVGStory_star_out")
            YIELD(TT, 333)
            self.jumpEff:SetActive(false)
            self:UnLock("UIN28AVGStory_ShowJumpAnim")
        end
    )
end

function UIN28AVGStory:SetBtnEvidenceBookActive(flag)
    if not self.isNodeShowEvidenceBook and flag then
        return
    end
    self.btnEvidenceBook:SetActive(flag)
end

function UIN28AVGStory:ShowHideOption(isShow)
    self.goOptions:SetActive(isShow)
    self.btnNextImg.raycastTarget = (not isShow)
end

function UIN28AVGStory:ShowHideGainEvidence(isShow)
    self.goGainEvidence:SetActive(isShow)
end

function UIN28AVGStory:ShowHideShowEvidence(isShow)
    self.goShowEvidence:SetActive(isShow)
end

function UIN28AVGStory:ShowHideShowEvidenceEff(isShow)
    self.showEvidenceEff:SetActive(isShow)
end

function UIN28AVGStory:ShowHideJumpBtn(isShow)
    self.btnNextImg.raycastTarget = isShow
end

--endregion

function UIN28AVGStory:IsAuto()
    local isAuto = self._storyManager._auto
    return isAuto
end

---从开nodeId结点始播放剧情
---@param nodeId number 结点id
function UIN28AVGStory:PlayFromBegain(nodeId)
    if self._storyManager._storyEntityList then
        for index, storyEntity in ipairs(self._storyManager._storyEntityList) do
            local go = storyEntity._gameObject
            UnityEngine.GameObject.Destroy(go)
        end
    end
    self._storyManager:Destroy()
    self:NodeId(nodeId) --设置当前结点
    self.fsm:ChangeState(N28StateAVGStory.Init)
end

--region OnClick
function UIN28AVGStory:BgOnClick(go)
    Log.fatal("### bgOnClick")
end

function UIN28AVGStory:BtnAutoOnClick(go)
    if self:IsAuto() then
        self.fsm:ChangeState(N28StateAVGStory.Play)
    else
        self.fsm:ChangeState(N28StateAVGStory.Auto)
    end
end

function UIN28AVGStory:BtnReviewOnClick(go)
    self:ShowDialog("UIN28AVGReview")
end

function UIN28AVGStory:BtnEvidenceBookOnClick(go)
    local evidenceListCache = self:GetEvidenceDataInCache()
    --排序
    table.sort(evidenceListCache, function(v1, v2)
        return v1 < v2
    end)
    self:ShowDialog("UIN28AVGStoryEvidenceBook", evidenceListCache)
end

function UIN28AVGStory:BtnShowHideUIOnClick(go)
    self._storyManager:HideUI(true)
    self.ui:SetActive(false)
    self.imgShowUI:SetActive(true)
end

function UIN28AVGStory:ImgShowUIOnClick(go)
    self._storyManager:HideUI(false)
    self.ui:SetActive(true)
    self.imgShowUI:SetActive(false)
end

function UIN28AVGStory:BtnNextOnClick(go)
    self.fsm:ChangeState(N28StateAVGStory.Next)
end

function UIN28AVGStory:BtnGraphOnClick(go)
    self:ShowDialog("UIN28AVGGraph", true)
end

function UIN28AVGStory:BtnExitOnClick(go)
    PopupManager.Alert(
        "UICommonMessageBox",
        PopupPriority.Normal,
        PopupMsgBoxType.OkCancel,
        "",
        StringTable.Get("str_avg_n28_exit_plot_hint"),
        function()
            self:SwitchState(UIStateType.UIN28AVGMain)
        end
    )
end

--endregion

--region N28StateAVGStory
local N28StateAVGStory = {
    Init = 0,
    Play = 1, --普通播放
    Auto = 2, --自动播放
    Next = 3, --快进到下一个关键点
    Option = 4, --选项状态
    GainEvidence = 5, --获取证据状态
    ShowEvidence = 6, --举证状态
    BECheck = 7, --BE检测阶段
    Over = 8 --一个故事结点结束
}
_enum("N28StateAVGStory", N28StateAVGStory)
--endregion
