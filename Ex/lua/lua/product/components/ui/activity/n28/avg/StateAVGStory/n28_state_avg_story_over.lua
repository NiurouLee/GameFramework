---@class N28StateAVGStoryOver : N28StateAVGStoryBase
_class("N28StateAVGStoryOver", N28StateAVGStoryBase)
N28StateAVGStoryOver = N28StateAVGStoryOver

function N28StateAVGStoryOver:OnEnter(TT, ...)
    self.key = "N28StateAVGStoryOverOnEnter"
    self:Init()
    local nodeId = self:NodeId()
    local node = self.data:GetNodeById(nodeId)
    AVGLog("------------Story end------------", nodeId, node.storyId)
    local nextNodeId = self:NextNodeId() --获取下一个结点id
    local com = self.data:GetComponentAVG()
    local res = AsyncRequestRes:New()
    if nextNodeId < -1 then
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIN28AVGMain)
    else
        self:HandleUpdateNodeData(TT, com, res, node.id, nextNodeId)
        if node:IsEnd() then --剧情结束，进入End界面
            GameGlobal.UIStateManager():ShowDialog("UIN28AVGEnding", node.endId, nodeId)
        else
            if nextNodeId < 0 then --下一个结点id为负，直接结束
                if GameGlobal.UIStateManager():IsShow("UIN28AVGEnding") then --如果目前打开结局界面
                    return
                else
                    GameGlobal.UIStateManager():SwitchState(UIStateType.UIN28AVGMain)
                end
            else
                GameGlobal.UIStateManager():CallUIMethod("UIN28AVGStory", "PlayFromBegain", nextNodeId)
            end
        end 
    end
end

function N28StateAVGStoryOver:OnExit(TT)
end

---@param com AvgMinigameComponent
---@param res AsyncRequestRes
function N28StateAVGStoryOver:HandleUpdateNodeData(TT, com, res, nodeId, nextNodeId)
    GameGlobal.UIStateManager():Lock(self.key)
    nextNodeId = nextNodeId < 0 and 0 or nextNodeId
    local avgStoryMissionInfo = self.data:GetServerNodeDataByNodeId(nextNodeId)
    if not avgStoryMissionInfo then
        avgStoryMissionInfo = AVGStoryMissionInfo:New()
        avgStoryMissionInfo.mission_id = nextNodeId
        avgStoryMissionInfo.end_formation_info = AVGStoryFormationInfo:New()
    end
    if not table.icontains(avgStoryMissionInfo.from_nodes, nodeId) then
        table.insert(avgStoryMissionInfo.from_nodes, nodeId) --塞nextNodeId的来源结点id
    end
    avgStoryMissionInfo.end_formation_info.leader_hp, avgStoryMissionInfo.end_formation_info.teammate_affinity =
        self:CalcCurData() --根据passSectionIds计算数据
    local nodeId = self:NodeId()
    local node = self.data:GetNodeById(nodeId)
    avgStoryMissionInfo.end_formation_info.evidence = table.shallowcopy(self:GetEvidenceDataInCache())
    local ret = com:HandleUpdateNodeData(TT, res, avgStoryMissionInfo, nodeId) --【请求】更新数据
    if N28AVGData.CheckCode(res) then
        self.data:Update()
    end
    GameGlobal.UIStateManager():UnLock(self.key)
end
