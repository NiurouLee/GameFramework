---@class N28StateAVGStoryShowEvidence : N28StateAVGStoryBase
_class("N28StateAVGStoryShowEvidence", N28StateAVGStoryBase)
N28StateAVGStoryShowEvidence = N28StateAVGStoryShowEvidence

function N28StateAVGStoryShowEvidence:OnEnter(TT, ...)
    self:Init()
    self.eventCfg, self.trackData, self.uiDialog = table.unpack({...})
    self.manualID = self.eventCfg.Params[1]
    self.poolShowEvidence = self.ui.poolShowEvidence
    self:ShowHideButtonAuto(false)
    self:ShowHideButtonShowHideUI(false)
    self:ShowHideButtonNext(false)
    self:ShowHideButtonEvidenceBook(false)
    self:ShowHideShowEvidence(true)
    self.storyManager = self.data:StoryManager()
    self:FlushEvidence()
end

function N28StateAVGStoryShowEvidence:Init()
    N28StateAVGStoryBase.Init(self)
    --编辑器通用缺省id
    self.defaultID = 9999
end

function N28StateAVGStoryShowEvidence:OnExit(TT)
    self:ShowHideButtonAuto(true)
    self:ShowHideButtonShowHideUI(true)
    self:ShowHideButtonNext(true)
    self:ShowHideButtonEvidenceBook(true)
    self:ShowHideShowEvidence(false)
end

function N28StateAVGStoryShowEvidence:FlushEvidence()
    local nodeId = self:NodeId()
    local node = self.data:GetNodeById(nodeId)
    local curEvidences = self:GetEvidenceDataInCache()
    --提示文本
    local manualCfg = self:GetEvidenceManualCfg(self.manualID)
    self:SetShowEvienceCount(self.manualID)
    local idx = self:GetShowEvienceCount(self.manualID)
    idx = idx > #manualCfg.HintText and #manualCfg.HintText or idx
    local hint = manualCfg.HintText[idx]
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N28AVGShowPanel)
    local ui = self.poolShowEvidence:SpawnObject("UIN28AVGStoryShowEvidence")
    ui:Flush(hint, curEvidences, function(eid)
        --举证
        self:ShowEvidence(eid)
    end)
end

function N28StateAVGStoryShowEvidence:ShowEvidence(eid)
    --跳转段落
    local data = self:GetSelectData(eid)
    self:SaveShowEvidence(self.manualID, eid)
    self.storyManager:SetNextParagraphID(data.NextParagraphID)
    if data.NextNodeID and data.NextNodeID ~= self.defaultID then
        self:NextNodeId(data.NextNodeID) --设置下一个结点
    end
    --播放动效
    local manualCfg = self:GetEvidenceManualCfg(self.manualID)
    local hasShowEff = false
    local cfg = manualCfg.CorrectEvidence or {}
    for _, v in pairs(cfg) do
        if v == eid then
            --选择举证特效的选项
            hasShowEff = true
        end
    end
    if hasShowEff then
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N28AVGShowEvidence)
        self.ui.anim:Play("uieff_UIN28AVGStory_ShowEvidence_in")
        GameGlobal.TaskManager():StartTask(
            function(TT)
                local key = "N28StateAVGStoryShowEvidenceEff"
                GameGlobal.UIStateManager():Lock(key)
                self:ShowHideShowEvidenceEff(true)
                YIELD(TT, 2000)
                self:ShowHideShowEvidenceEff(false)
                self.uiDialog:DoNextAVGEvent()
                self.fsm:ChangeState(StateAVGStory.Play) 
                GameGlobal.UIStateManager():UnLock(key)
            end,
            self
        )
    else
        self.uiDialog:DoNextAVGEvent()
        self.fsm:ChangeState(StateAVGStory.Play) 
    end
end

function N28StateAVGStoryShowEvidence:GetSelectData(eid)
    local defaultData = nil
    for _, v in pairs(self.trackData) do
        if v.EvidenceID == eid then
            return v
        end
        --缺省id
        if v.EvidenceID == self.defaultID then
            defaultData = v
        end
    end
    return defaultData
end

function N28StateAVGStoryShowEvidence:GetEvidenceManualCfg(mid)
    local evidenceManualCfg = Cfg.cfg_component_avg_evidence_manual{ID = mid}
    if evidenceManualCfg then
        return evidenceManualCfg[1]
    end
    return {}
end

function N28StateAVGStoryShowEvidence:SaveShowEvidence(manualId, eid)
    GameGlobal.TaskManager():StartTask(
        function(TT)
            local key = "N28StateAVGStoryShowEvidenceSave"
            GameGlobal.UIStateManager():Lock(key)
            local com = self.data:GetComponentAVG()
            local res = AsyncRequestRes:New()
            local ret = com:HandleShowEvidence(TT, res, manualId, eid) --【请求】保存证据
            if N28AVGData.CheckCode(res) then
                Log.debug("N28StateAVGStoryShowEvidence success")
            else
                Log.fatal("### HandleManualChoose failed.")
            end
            GameGlobal.UIStateManager():UnLock(key)
        end,
        self
    )
end

