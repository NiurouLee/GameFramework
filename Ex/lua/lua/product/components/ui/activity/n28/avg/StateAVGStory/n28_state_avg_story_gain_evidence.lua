---@class N28StateAVGStoryGainEvidence : N28StateAVGStoryBase
_class("N28StateAVGStoryGainEvidence", N28StateAVGStoryBase)
N28StateAVGStoryGainEvidence = N28StateAVGStoryGainEvidence

function N28StateAVGStoryGainEvidence:OnEnter(TT, ...)
    self:Init()
    self.eventCfg, self.uiDialog = table.unpack({...})
    self.poolGainEvidence = self.ui.poolGainEvidence
    self:ShowHideButtonAuto(false)
    self:ShowHideButtonShowHideUI(false)
    self:ShowHideButtonNext(false)
    self:ShowHideGainEvidence(true)
    self.storyManager = self.data:StoryManager()
    self:FlushEvidence()
end

function N28StateAVGStoryGainEvidence:OnExit(TT)
    self:ShowHideButtonAuto(true)
    self:ShowHideButtonShowHideUI(true)
    self:ShowHideButtonNext(true)
    self:ShowHideGainEvidence(false)
end

function N28StateAVGStoryGainEvidence:Init()
    N28StateAVGStoryBase.Init(self)
    --获取证据索引
    self.curEvienceIdx = 1
end

function N28StateAVGStoryGainEvidence:FlushEvidence()
    self.evidenceIDList = self.eventCfg.Params
    local evidenceID = self.evidenceIDList[self.curEvienceIdx]
    local evidenceCfg = self:GetEvidenceCfg(evidenceID)
    -- local nodeId = self:NodeId()
    -- local node = self.data:GetNodeById(nodeId)
    local curEvidences = self:GetEvidenceDataInCache()
    local isAdd = self.eventCfg.Type == N28StateAVGEvent.AddEvidence
    local sameTypeEvidenceID = nil
    local hasEvidence = false
    for _, eid in pairs(curEvidences) do
        local cfg = self:GetEvidenceCfg(eid)
        --同类证据
        if cfg.EvidenceType == evidenceCfg.EvidenceType then
            sameTypeEvidenceID = cfg.ID
        end
        --已经存在证据
        if cfg.ID == evidenceCfg.ID then
            hasEvidence = true
        end
    end
    --判断状态
    self._gainEvidenceState = self:CheckAVGEvidenceGainState(isAdd, hasEvidence, sameTypeEvidenceID)
    --存到缓存
    self:SaveEvidenceDataToCache(sameTypeEvidenceID, evidenceID)
    --刷新UI(只有升级和新获得才会显示UI)
    local isNewGet = self._gainEvidenceState == N28StateAVGEvidenceGainState.New
    if isNewGet or self._gainEvidenceState == N28StateAVGEvidenceGainState.LevelUp then
        local ui = self.poolGainEvidence:SpawnObject("UIN28AVGStoryGainEvidence")
        GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIN28AVGStoryGainEvidence)
        local guideModule = GameGlobal.GetModule(GuideModule)
        local isGuiding = guideModule:IsGuideProcess(118003)
        if isGuiding then
            self.storyManager:ForceJumpStop(true)
        end
        local lastEvidenceCfg = isNewGet and nil or self:GetEvidenceCfg(sameTypeEvidenceID)
        ui:Flush(evidenceCfg, (self.uiDialog._auto and not isGuiding), isNewGet, lastEvidenceCfg, function()
            self:HandleNextEvidence()
        end)
    else
        self:HandleNextEvidence()
    end
end

function N28StateAVGStoryGainEvidence:HandleNextEvidence()
    if self.curEvienceIdx < #self.evidenceIDList then
        --处理同时获取多个证据
        self.curEvienceIdx = self.curEvienceIdx + 1
        --中间有动效
        self:FlushEvidence()
    else     
        self.uiDialog:DoNextAVGEvent()
        self.fsm:ChangeState(StateAVGStory.Play)
    end
    self.storyManager:ForceJumpStop(false)
end

function N28StateAVGStoryGainEvidence:CheckAVGEvidenceGainState(isAdd, hasEvidence, sameTypeEvidenceID)
    local curEvidenceGainState = N28StateAVGEvidenceGainState.None
    if isAdd then
        if hasEvidence then
            curEvidenceGainState = N28StateAVGEvidenceGainState.Duplicate
        elseif sameTypeEvidenceID then
            curEvidenceGainState = N28StateAVGEvidenceGainState.LevelUp
        else
            curEvidenceGainState = N28StateAVGEvidenceGainState.New
        end   
    else
        if hasEvidence then
            curEvidenceGainState = N28StateAVGEvidenceGainState.Delete
        else
            curEvidenceGainState = N28StateAVGEvidenceGainState.Duplicate
        end 
    end
    return curEvidenceGainState
end

function N28StateAVGStoryGainEvidence:SaveEvidenceDataToCache(sameTypeEvidenceID, evidenceID)
    if self._gainEvidenceState == N28StateAVGEvidenceGainState.LevelUp then
        self:ChangeEvidenceDataInCache(sameTypeEvidenceID, false)
        self:ChangeEvidenceDataInCache(evidenceID, true)  
        self:SaveEvidence(evidenceID)
    elseif self._gainEvidenceState == N28StateAVGEvidenceGainState.New then
        self:ChangeEvidenceDataInCache(evidenceID, true)
        self:SaveEvidence(evidenceID)   
    elseif self._gainEvidenceState == N28StateAVGEvidenceGainState.Delete then
        self:ChangeEvidenceDataInCache(evidenceID, false)    
    end
end

function N28StateAVGStoryGainEvidence:GetEvidenceCfg(eid)
    local evidenceCfg = Cfg.cfg_component_avg_evidence{ID = eid}
    if evidenceCfg then
        return evidenceCfg[1]
    end
    return {}
end

--这里只记录历史获得过的证据，用于收藏
function N28StateAVGStoryGainEvidence:SaveEvidence(eid)
    GameGlobal.TaskManager():StartTask(
        function(TT)
            local key = "N28StateAVGStoryGainEvidenceSave"
            GameGlobal.UIStateManager():Lock(key)
            local com = self.data:GetComponentAVG()
            local res = AsyncRequestRes:New()
            local ret = com:HandleGainEvidence(TT, res, eid) --【请求】保存证据
            if N28AVGData.CheckCode(res) then
                Log.debug("N28StateAVGStoryGainEvidence success")
            else
                Log.fatal(
                    "### N28StateAVGStoryGainEvidence failed. "
                )
            end
            GameGlobal.UIStateManager():UnLock(key)
        end,
        self
    )
end

--region N28StateAVGEvidenceGainState
local N28StateAVGEvidenceGainState = {
    New = 0,        --新类型证据获取
    LevelUp = 1,    --证据类型升级
    Delete = 2,     --证据删除
    Duplicate = 3,  --重复获取或已经删除
    None = 4        --无效状态
}
_enum("N28StateAVGEvidenceGainState", N28StateAVGEvidenceGainState)
--endregion