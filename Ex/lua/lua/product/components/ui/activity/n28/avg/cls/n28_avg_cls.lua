--region N28AVGData
---@class N28AVGData:Object
---@field componentId number 活动组件id
---@field actorLeader N28AVGActorLeader 主角
---@field actorPartners N28AVGActorPartner[] 伙伴
---@field dictStoryNode N28AVGStoryNode[] 结点字典 key-结点id value-AVStoryNode
---@field dictStoryIdNodeId number[] 结点字典 key-结点storyId value-结点id
---@field graph Digraph 结点的图
---@field lines N28AVGStoryLine[] 连线列表
---@field badges N28AVGBadgeInfo[] 徽章列表
---@field badgeStages N28AVGBadgeStage[] 徽章阶段列表
---@field endings N28AVGEnding[] 结局列表
---@field storyManager StoryManager 剧情管理器
---@field fstNodeId number 第1个结点id
---@field GetComponentInfoAVG function
_class("N28AVGData", Object)
N28AVGData = N28AVGData

function N28AVGData:Constructor()
    self.activityCampaign = UIActivityCampaign:New()
    self.dictBadgePos = {
        --徽章位置字典 key-徽章id value-徽章位置
        [1] = Vector2(-213, 162),
        [2] = Vector2(98, 162),
        [3] = Vector2(411, 162),
        [4] = Vector2(723, 162),
        [5] = Vector2(-55, -105),
        [6] = Vector2(256, -105),
        [7] = Vector2(564, -105)
    }
    self.notRemindJump = false --是否跳转提示脏数据
    self.uiName = "UIN28AVGStory"

    self.storyManager = nil

    self.optionPos = {
        Vector2(212, 333),
        Vector2(129, 143),
        Vector2(31, -50),
        Vector2(-64, -239)
    }
end

--region 组件
function N28AVGData:RequestCampaign(TT)
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    self.activityCampaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_N28,
        ECampaignN28ComponentID.ECAMPAIGN_N28_AVG_PHASE_2
    )
    return res
end
---@return AvgMinigameComponent AVG组件
function N28AVGData:GetComponentAVG()
    return self.activityCampaign:GetComponent(ECampaignN28ComponentID.ECAMPAIGN_N28_AVG_PHASE_2)
end
---@return AVGStoryComponentClientInfo AVG组件信息
function N28AVGData:GetComponentInfoAVG()
    return self.activityCampaign:GetComponentInfo(ECampaignN28ComponentID.ECAMPAIGN_N28_AVG_PHASE_2)
end

---组件是否开启
function N28AVGData:IsActiveOpen()
    ---@type AvgMinigameComponent
    local c = self:GetComponentAVG()
    if c and c:ComponentIsOpen() then
        return true
    end
    return false
end

---@param res AsyncRequestRes
function N28AVGData.CheckCode(res)
    local result = res:GetResult()
    if result == CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_SUCCESS then
        return true
    end
    local msg = StringTable.Get("str_activity_error_" .. result)
    ToastManager.ShowToast(msg)
    Log.warn("### ", msg)
    if
        result == CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_FINISHED or
            result == CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_NO_OPEN
     then
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIMain) --活动结束，切到主界面
    elseif result == CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_COMPONENT_CLOSE then
        CutsceneManager.ExcuteCutsceneIn_Shot()
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIActivityN28MainController) --AVG结束，切到N28活动主界面
    else
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIMain) --其他错误切到主界面
    end
    return false
end
--endregion

--region Init 配置数据
function N28AVGData:Init()
    self:InitActors()
    self:InitGraph()
    self:InitLines()
    self:InitBadge()
    self:InitEvidence()
    self:InitEnding()
end
function N28AVGData:InitActors()
    local cfg_component_avg_story_limit = self:GetCfgComponentAvgStoryLimit()
    local actorInfo = cfg_component_avg_story_limit.ActorInfo
    self.actorLeader = N28AVGActorLeader:New()
    self.actorLeader.icon = actorInfo[1].icon
    self.actorLeader.iconOption = actorInfo[1].iconOption
    self.actorLeader.min = cfg_component_avg_story_limit.MinBlood
    self.actorLeader.max = cfg_component_avg_story_limit.MaxBlood
    self.actorLeader.default = cfg_component_avg_story_limit.StartBlood

    self.actorPartners = {}
    if cfg_component_avg_story_limit.TeammateInitList then
        for i, s in ipairs(cfg_component_avg_story_limit.TeammateInitList) do
            local actor = N28AVGActorPartner:New()
            actor.icon = cfg_component_avg_story_limit.ActorInfo[i + 1].icon
            actor.iconOption = cfg_component_avg_story_limit.ActorInfo[i + 1].iconOption
            actor.min = cfg_component_avg_story_limit.TeammateMinList[i]
            actor.max = cfg_component_avg_story_limit.TeammateMaxList[i]
            actor.default = cfg_component_avg_story_limit.TeammateInitList[i]
            table.insert(self.actorPartners, actor)
        end
    end
    --初始证据
    self.defaultEvidences = cfg_component_avg_story_limit.StartEvidences
end
function N28AVGData:InitGraph()
    self.dictStoryNode = {}
    self.dictStoryIdNodeId = {}
    local cfg_component_avg_story_node = self:GetCfgComponentAvgStoryNode()
    self.graph = Digraph:New()
    for _, cfgv in pairs(cfg_component_avg_story_node) do
        local node = N28AVGStoryNode:New()
        node.id = cfgv.ID
        node.endId = cfgv.Ending or 0
        node.storyId = cfgv.StoryId
        if string.isnullorempty(cfgv.VisibleCondition) then
            node.hideVisibleCondition = nil
        else
            node.hideVisibleCondition = N28AVGCondition:New(cfgv.VisibleCondition, false) --默认false，隐藏
        end
        node.hideStartArchive = cfgv.StartArchive or {}
        node.hideStartEvidences = cfgv.StartEvidences or {}
        node.pos.x = cfgv.NodePos[1]
        node.pos.y = cfgv.NodePos[2]
        node.title = StringTable.Get(cfgv.Title)
        node.desc = StringTable.Get(cfgv.Desc)
        node.cg = cfgv.CG
        node.cgNode = cfgv.CGNode
        node.cgCanPlay = cfgv.CanplayCG
        node.cgCanplayCGNode = cfgv.CanplayCGNode
        node.hideEvidenceBook = cfgv.HideEvidenceBook
        self.dictStoryNode[cfgv.ID] = node
        self.dictStoryIdNodeId[node.storyId] = cfgv.ID
        --region 构造有向图的边
        local node = self.dictStoryNode[cfgv.ID]
        local nextNodeIds = cfgv.NextStory
        if nextNodeIds then
            node.defaultNextId = nextNodeIds[1]
            for _, nodeId in ipairs(nextNodeIds) do
                self.graph:AddEdge(cfgv.ID, nodeId)
            end
        else
            node.defaultNextId = -1
        end
        --endregion
    end
end
---用剧情配置初始化结点
function N28AVGData:InitNodes()
    local cfgSectionExcel = self:GetCfgComponentAvgStorySection()
    local cfgOptionExcel = self:GetCfgComponentAvgStoryManual()
    for id, node in pairs(self.dictStoryNode) do
        node:Init(cfgSectionExcel, cfgOptionExcel)
    end
end
function N28AVGData:InitLines()
    self.lines = {}
    local cfg_avg_line = self:GetCfgAvgLine()
    for _, cfgv in pairs(cfg_avg_line) do
        local cfgvPos = cfgv.Pos
        for eNodeId, t in pairs(cfgvPos) do
            local line = N28AVGStoryLine:New()
            line.sNodeId = cfgv.ID
            line.eNodeId = eNodeId
            line.posS = Vector2(t.s[1], t.s[2])
            line.posE = Vector2(t.e[1], t.e[2])
            if t.l then
                line.posLs = {}
                for index, lp in ipairs(t.l) do
                    local pos = Vector2(lp[1], lp[2])
                    table.insert(line.posLs, pos)
                end
            end
            table.insert(self.lines, line)
        end
    end
end

function N28AVGData:InitEvidence()
    self.allEvidences = {}
    local cfg_component_avg_evidence = self:GetCfgComponentAvgEvidence()
    for id, cfgv in pairs(cfg_component_avg_evidence) do
        local evidence = N28AVGEvidenceInfo:New()
        evidence.id = cfgv.ID
        evidence.type = cfgv.EvidenceType
        evidence.name = StringTable.Get(cfgv.EvidenceName)
        evidence.desc = StringTable.Get(cfgv.EvidenceIntro)
        evidence.icon = cfgv.EvidenceIcon
        if #self.allEvidences == 0 then
            self.allEvidences[1] = evidence
        else
            local insertID = 0
            for i = 1, #self.allEvidences do
                if self.allEvidences[i].id > evidence.id then
                    insertID = i
                    break
                end
            end
            insertID = insertID > 0 and insertID or #self.allEvidences + 1
            table.insert(self.allEvidences, insertID, evidence)
        end
    end
end

function N28AVGData:InitBadge()
    self.badges = {}
    local cfg_component_avg_story_badge = self:GetCfgComponentAvgStoryBadge()
    for id, cfgv in pairs(cfg_component_avg_story_badge) do
        local badge = N28AVGBadgeInfo:New()
        badge.id = cfgv.ID
        badge.itemId = cfgv.BadgeID or 0
        badge.name = StringTable.Get(cfgv.Name)
        badge.desc = StringTable.Get(cfgv.Desc)
        badge.icon = cfgv.Icon
        if #self.badges == 0 then
            self.badges[1] = badge
        else
            local insertID = 0
            for i = 1, #self.badges do
                if self.badges[i].id > badge.id then
                    insertID = i
                    break
                end
            end
            insertID = insertID > 0 and insertID or #self.badges + 1
            table.insert(self.badges, insertID, badge)
        end
        --table.insert(self.badges, badge)
    end
    --设置坐标
    for i = 1, #self.badges do
        self.badges[i].pos = self.dictBadgePos[i]
    end
    --徽章阶段
    self.badgeStages = {}
    local cfg_component_avg_story_badge_reward = self:GetCfgComponentAvgStoryBadgeReward()
    for id, cfgv in pairs(cfg_component_avg_story_badge_reward) do
        local stage = N28AVGBadgeStage:New()
        stage.id = cfgv.ID
        stage.count = cfgv.StageCount
        for _, tAward in ipairs(cfgv.Reward) do
            local ra = RoleAsset:New()
            ra.assetid = tAward[1]
            ra.count = tAward[2]
            table.insert(stage.awards, ra)
        end
        table.insert(self.badgeStages, stage)
    end
end
function N28AVGData:InitEnding()
    self.endings = {}
    local cfg_component_avg_story_ending = self:GetCfgComponentAvgStoryEnding()
    for id, cfgv in pairs(cfg_component_avg_story_ending) do
        local ending = N28AVGEnding:New()
        ending.id = cfgv.ID
        ending.itemIdGift = cfgv.AcceptableCGGift or 0
        ending.itemId = cfgv.AcceptableCG or 0
        ending.cg = cfgv.CG
        ending.cgEnding = cfgv.EndingCG
        ending.cgCollectTab = cfgv.CollectTab
        ending.cgCollect = cfgv.CollectCG
        ending.title = StringTable.Get(cfgv.Title)
        ending.desc = StringTable.Get(cfgv.Desc)
        ending.getConditionDesc = StringTable.Get(cfgv.GetConditionDesc)
        --region 奖励
        ending.awards = {}
        local cfgGift = Cfg.cfg_item_gift[cfgv.AcceptableCGGift]
        if cfgGift then
            local itemList = cfgGift.ItemList
            if itemList and table.count(itemList) > 0 then
                for index, idCount in ipairs(itemList) do
                    local ra = RoleAsset:New()
                    ra.assetid = idCount[1]
                    ra.count = idCount[2]
                    table.insert(ending.awards, ra)
                end
            end
        end
        --endregion
        ending.isBE = cfgv.IsBE
        table.insert(self.endings, ending)
    end
    table.sort(
        self.endings,
        function(a, b)
            return a.id < b.id
        end
    )
end
--endregion

--region Update 服务器数据
function N28AVGData:Update()
    self:UpdateActors()
    self:UpdateGraph()
    self:UpdateBadge()
    self:UpdateEnding()
end
function N28AVGData:UpdateActors()
end
function N28AVGData:UpdateGraph()
    for _, node in pairs(self.dictStoryNode) do
        if node:IsHide() then --隐藏结点只有 Complete CanPlay 和 nil 三种状态
            if node:IsComplete() then
                node.state = N28AVGStoryNodeState.Complete
            else
                if node:IsSatisfyVisible() then
                    node.state = N28AVGStoryNodeState.CanPlay --结点未完成，但有更新数据，可打
                else
                    node.state = nil --结点未完成，亦未更新数据，可见不可打或不可见
                end
            end
        else
            if node:IsComplete() then
                node.state = N28AVGStoryNodeState.Complete
            else
                local serverNodeInfo = self:GetServerNodeDataByNodeId(node.id)
                if serverNodeInfo then
                    node.state = N28AVGStoryNodeState.CanPlay --结点未完成，但有更新数据，可打
                else
                    node.state = nil --结点未完成，亦未更新数据，可见不可打或不可见
                end
            end
        end
    end
    for id, node in pairs(self.dictStoryNode) do
        if node:IsHide() then
        else
            if node.state then
            else --对可见不可打或不可见的结点进行二次细分
                local nodeIds = self.graph:Indegree(id)
                if nodeIds then
                    for _, nodeId in ipairs(nodeIds) do
                        local nodeIndegree = self:GetNodeById(nodeId)
                        if nodeIndegree and nodeIndegree.state == N28AVGStoryNodeState.Complete then --如果入度结点有完成的，可见不可打
                            node.state = N28AVGStoryNodeState.CantPlay
                            break
                        end
                    end
                end
            end
        end
    end
end
function N28AVGData:UpdateBadge()
end
function N28AVGData:UpdateEnding()
end
--endregion

function N28AVGData:GetComponentId()
    if not self.componentId then
        local c = self:GetComponentAVG()
        self.componentId = c:GetComponentCfgId()
    end
    return self.componentId
end

--region cfg
---cfg_component_avg_story_badge
function N28AVGData:GetCfgComponentAvgStoryBadge()
    local cId = self:GetComponentId()
    local cfg = Cfg.cfg_component_avg_story_badge {ComponentID = cId}
    return cfg
end

--region cfg
---cfg_component_avg_story_badge
function N28AVGData:GetCfgComponentAvgEvidence()
    local cId = self:GetComponentId()
    local cfg = Cfg.cfg_component_avg_evidence {ComponentID = cId}
    return cfg
end

---cfg_component_avg_story_badge_reward
function N28AVGData:GetCfgComponentAvgStoryBadgeReward()
    local cId = self:GetComponentId()
    local cfg = Cfg.cfg_component_avg_story_badge_reward {ComponentID = cId}
    return cfg
end
---cfg_component_avg_story_ending
function N28AVGData:GetCfgComponentAvgStoryEnding()
    local cId = self:GetComponentId()
    local cfg = Cfg.cfg_component_avg_story_ending {ComponentID = cId}
    return cfg
end
---cfg_component_avg_story_limit
function N28AVGData:GetCfgComponentAvgStoryLimit()
    local cId = self:GetComponentId()
    local cfg = Cfg.cfg_component_avg_story_limit {ComponentID = cId}
    if cfg then
        return cfg[1]
    end
end
---cfg_component_avg_story_manual
function N28AVGData:GetCfgComponentAvgStoryManual()
    local cId = self:GetComponentId()
    local cfg = Cfg.cfg_component_avg_story_manual {ComponentID = cId}
    return cfg
end
---cfg_component_avg_story_node
function N28AVGData:GetCfgComponentAvgStoryNode()
    local cId = self:GetComponentId()
    local cfg = Cfg.cfg_component_avg_story_node {ComponentID = cId}
    return cfg
end
---cfg_component_avg_story_section
function N28AVGData:GetCfgComponentAvgStorySection()
    local cId = self:GetComponentId()
    local cfg = Cfg.cfg_component_avg_story_section {ComponentID = cId}
    return cfg
end
---cfg_avg_line
function N28AVGData:GetCfgAvgLine()
    local cId = self:GetComponentId()
    local cfg = Cfg.cfg_avg_line {ComponentID = cId}
    return cfg
end
--endregion

---获取第1个结点
function N28AVGData:FirstNodeId()
    if not self.fstNodeId then
        for id, node in pairs(self.dictStoryNode) do
            if self.graph:IndegreeCount(id) == 0 and not node:IsHide() then --入度为0且不是隐藏结点的结点即为第1个结点
                self.fstNodeId = node.id
                break
            end
        end
    end
    return self.fstNodeId
end
---当前所处结点id
function N28AVGData:CurNodeId()
    local info = self:GetComponentInfoAVG()
    local curNodeId = info.cur_node_id
    if curNodeId == 0 then --确保当前结点id是实际结点id
        curNodeId = self:FirstNodeId()
    end
    return curNodeId
end
---@return N28AVGStoryNode 当前所处结点
function N28AVGData:CurNode()
    local nodeId = self:CurNodeId()
    local node = self:GetNodeById(nodeId)
    return node
end
---@param id number 结点id
---@return N28AVGStoryNode 结点
function N28AVGData:GetNodeById(id)
    if not id then
        Log.fatal("### node id is nil.")
    end
    local node = self.dictStoryNode[id]
    return node
end
---@param storyId number 结点storyId
---@return N28AVGStoryNode 结点
function N28AVGData:GetNodeByStoryId(storyId)
    local nodeId = self.dictStoryIdNodeId[storyId]
    if not nodeId then
        Log.fatal("### no corresponding nodeId. storyId=", storyId)
    end
    local node = self:GetNodeById(nodeId)
    return node
end
---@param endId number 结局结点endId
---@return N28AVGStoryNode 结点
function N28AVGData:GetNodeByEndId(endId)
    for id, node in pairs(self.dictStoryNode) do
        if node.endId == endId then
            return node
        end
    end
end

---玩到一半
function N28AVGData:OnTheWay()
    local nodeId = self:CurNodeId()
    if nodeId == self:FirstNodeId() then
        return false
    end
    return true
end

--region New Red
function N28AVGData:HasNew()
    local hasNewNode = self:HasNewNode()
    local hasNewBadge = self:HasNewBadge()
    local hasNewEvidence = self:HasNewEvidence()
    local hasNewCG = self:HasNewCG()
    return hasNewNode or hasNewBadge or hasNewCG or hasNewEvidence
end
function N28AVGData:HasNewNode()
    for id, node in pairs(self.dictStoryNode) do
        if node:IsHide() and node:IsSatisfyVisible() and node:IsHideNew() then
            return true
        end
    end
    return false
end
function N28AVGData:HasNewEvidence()
    for id, evidence in ipairs(self.allEvidences) do
        if evidence:HasNew() then
            return true
        end
    end
    return false
end
function N28AVGData:HasNewBadge()
    for index, badge in ipairs(self.badges) do
        if badge:HasNew() then
            return true
        end
    end
    return false
end
function N28AVGData:HasNewCG()
    for index, ending in ipairs(self.endings) do
        if ending:HasNew() then
            return true
        end
    end
    return false
end

function N28AVGData:HasRed()
    local hasRedBadge = self:HasRedBadge()
    local hasRedCG = self:HasRedCG()
    return hasRedBadge or hasRedCG
end
function N28AVGData:HasRedBadge()
    for index, badgeStage in ipairs(self.badgeStages) do
        if badgeStage:HasRed() then
            return true
        end
    end
    return false
end
function N28AVGData:HasRedCG()
    for index, ending in ipairs(self.endings) do
        if ending:HasRed() then
            return true
        end
    end
    return false
end
--endregion

---根据索引获取角色，优先取队友，所获nil则返回主角
---@return N28AVGActor
function N28AVGData:GetActorByIndex(index)
    local actor = self.actorPartners[index]
    if actor then
        return actor
    end
    return self.actorLeader
end

---End是否达成
function N28AVGData:IsEndReach(endId)
    local info = self:GetComponentInfoAVG()
    if table.icontains(info.conplated_ending_ids, endId) then
        return true
    end
end

---@return N28AVGBadgeInfo
function N28AVGData:GetBadgeById(id)
    for index, badge in ipairs(self.badges) do
        if id == badge.id then
            return badge
        end
    end
end
---@return N28AVGBadgeStage
function N28AVGData:GetBadgeStageById(id)
    for index, badgeStage in ipairs(self.badgeStages) do
        if id == badgeStage.id then
            return badgeStage
        end
    end
end
---@return N28AVGEnding
function N28AVGData:GetEndingById(id)
    for index, ending in ipairs(self.endings) do
        if id == ending.id then
            return ending
        end
    end
end

---时间戳转化成yyyy.MM.DD hh:mm
function N28AVGData:Timestamp2Str(timestamp)
    local t = UICommonHelper.Time2Day(timestamp)
    local year = os.date("%Y", timestamp)
    local month = os.date("%m", timestamp)
    local day = os.date("%d", timestamp)
    local hour = os.date("%H", timestamp)
    local min = os.date("%M", timestamp)
    local str = year .. "." .. month .. "." .. day .. " " .. hour .. ":" .. min
    return str
end
--根据storyId, paragraphId, sectionIdx构造key
---@param list number[]| string[] 拼接的数/文本
function N28AVGData.Sign(list)
    local key = table.concat(list, "_")
    return key
end
---@param sign string XX_YY_ZZ
---@return number[]
function N28AVGData.Sign2Numbers(sign)
    if type(sign) ~= "string" then
        Log.fatal("invalid param.", sign)
    end
    local strs = string.split(sign, "_")
    local t = {}
    for index, str in ipairs(strs) do
        local n = tonumber(str)
        table.insert(t, n)
    end
    return t
end

---@return AVGStoryMissionInfo 根据结点id获取服务器结点数据
function N28AVGData:GetServerNodeDataByNodeId(nodeId)
    local info = self:GetComponentInfoAVG()
    local serNodeData = info.mission_datas[nodeId]
    return serNodeData
end

---@return StoryManager
function N28AVGData:StoryManager(storyManager)
    if storyManager then
        self.storyManager = storyManager
    else
        return self.storyManager
    end
end

---@param optionId number 选项唯一id
function N28AVGData:IsSelectedOption(optionId)
    local info = self:GetComponentInfoAVG()
    if table.icontains(info.choosed_manual_ids, optionId) then
        return true
    end
end

---@return number, numer[] 当前主角血量，队员攻略度, 证据
function N28AVGData:CalcCurData()
    if GameGlobal.UIStateManager():IsShow(self.uiName) then
        local hp, strategies = GameGlobal.UIStateManager():CallUIMethod(self.uiName, "CalcCurData")
        return hp, strategies
    end
    return 0, {}
end

--endregion

--region N28AVGActor 角色
---@class N28AVGActor:Object
---@field icon string 角色头像
---@field iconOption string 剧情选项的角色头像
---@field min number 下限
---@field max number 上限
---@field default number 默认值
---@field isLeader boolean 是否主角
_class("N28AVGActor", Object)
N28AVGActor = N28AVGActor

function N28AVGActor:Constructor()
    self.icon = ""
    self.iconOption = ""
    self.min = 0
    self.max = 0
    self.default = 0
    self.isLeader = false

    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = self.mCampaign:GetN28AVGData()
end
-------------------------------------------------
---@class N28AVGActorLeader:N28AVGActor 主角
_class("N28AVGActorLeader", N28AVGActor)
N28AVGActorLeader = N28AVGActorLeader

function N28AVGActorLeader:Constructor()
    self.isLeader = true
end
-------------------------------------------------
---@class N28AVGActorPartner:N28AVGActor 队友
---@field index number 队友在队伍中的索引
_class("N28AVGActorPartner", N28AVGActor)
N28AVGActorPartner = N28AVGActorPartner

function N28AVGActorPartner:Constructor()
    self.index = 0
end
--endregion

--region N28AVGEvidenceInfo
---@class N28AVGEvidenceInfo:Object
---@field id number 证据(只在收藏中使用) id
---@field type number 证据组 id
---@field name string 证据标题
---@field desc string 证据描述
---@field icon number 证据图标
_class("N28AVGEvidenceInfo", Object)
N28AVGEvidenceInfo = N28AVGEvidenceInfo

function N28AVGEvidenceInfo:Constructor()
    self.id = 0
    self.type = 0
    self.name = ""
    self.desc = ""
    self.icon = ""
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = self.mCampaign:GetN28AVGData()
end

function N28AVGEvidenceInfo:HasNew()
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local info = self.data:GetComponentInfoAVG()
    local key = "N28AVGEvidenceInfo" .. pstId .. self.id
    if table.icontains(info.gained_evidence, self.id) and LocalDB.GetInt(key, 0) ~= 1 then
        return true
    end
    return false
end

function N28AVGEvidenceInfo:SetNew()
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = "N28AVGEvidenceInfo" .. pstId .. self.id
    LocalDB.SetInt(key, 1)
end

function N28AVGEvidenceInfo:HasGot()
    local info = self.data:GetComponentInfoAVG()
    if table.icontains(info.gained_evidence, self.id) then
        return true
    end
    return false
end

--endregion

--region N28AVGBadgeInfo
---@class N28AVGBadgeInfo:Object
---@field id number 徽章 id
---@field itemId number 徽章是个道具，其对应的道具id
---@field name number 徽章名
---@field desc number 徽章描述
---@field icon number 徽章图标
---@field pos Vector2 徽章位置
_class("N28AVGBadgeInfo", Object)
N28AVGBadgeInfo = N28AVGBadgeInfo

function N28AVGBadgeInfo:Constructor()
    self.id = 0
    self.itemId = 0
    self.name = ""
    self.desc = ""
    self.icon = ""
    self.pos = Vector2.zero

    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = self.mCampaign:GetN28AVGData()
end

---徽章是否已获取，徽章对应的道具数＞0就表示该徽章已获取
function N28AVGBadgeInfo:HasGot()
    local mRole = GameGlobal.GetModule(RoleModule)
    local count = mRole:GetAssetCount(self.itemId)
    return count > 0
end
---是否有新获得徽章
function N28AVGBadgeInfo:HasNew()
    local mItem = GameGlobal.GetModule(ItemModule)
    local items = mItem:GetItemByTempId(self.itemId)
    for _, item in pairs(items) do
        if item:IsNewOverlay() then
            return true
        end
    end
    return false
end
--endregion

--region N28AVGBadgeStage 徽章阶段类
---@class N28AVGBadgeStage:Object
---@field id number 阶段id
---@field count number 该阶段对应的获取徽章数
---@field awards RoleAsset[] 该阶段奖励
_class("N28AVGBadgeStage", Object)
N28AVGBadgeStage = N28AVGBadgeStage

function N28AVGBadgeStage:Constructor()
    self.id = 0
    self.count = 0
    self.awards = {}

    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = self.mCampaign:GetN28AVGData()
end

---徽章阶段奖励icon，为第1个奖励图标
function N28AVGBadgeStage:AwardIcon()
    local award = self.awards[1]
    local cfgv = Cfg.cfg_item[award.assetid]
    local icon = cfgv.Icon
    return icon
end
function N28AVGBadgeStage:AwardCount()
    local award = self.awards[1]
    return award.count
end

---@return N28AVGAwardState 奖励领取状态
function N28AVGBadgeStage:State()
    local info = self.data:GetComponentInfoAVG()
    if table.icontains(info.accepted_badge_rewards, self.id) then
        return N28AVGAwardState.Got
    else
        local hasGotBadgeCount = 0 --已获取徽章数
        for index, badge in ipairs(self.data.badges) do
            if badge:HasGot() then
                hasGotBadgeCount = hasGotBadgeCount + 1
            end
        end
        if hasGotBadgeCount >= self.count then
            return N28AVGAwardState.CanGet
        end
    end
end
--是否有未领取奖励
function N28AVGBadgeStage:HasRed()
    local state = self:State()
    return state == N28AVGAwardState.CanGet
end
--endregion

--region N28AVGEnding
---@class N28AVGEnding:Object
---@field id number 结局id
---@field itemIdGift number 未领取奖励的CG是个礼包道具，与itemId同时获得
---@field itemId number 已领取奖励的CG是个道具，与itemIdGift同时获得
---@field cg string CG图
---@field cgEnding string 结局界面CG图
---@field cgCollect string 收藏界面CG图
---@field title number CG标题
---@field desc number CG描述
---@field getConditionDesc string 获取条件描述
---@field awards RoleAsset[] 奖励
---@field isBE boolean 是否BE
_class("N28AVGEnding", Object)
N28AVGEnding = N28AVGEnding

function N28AVGEnding:Constructor()
    self.id = 0
    self.itemIdGift = 0
    self.itemId = 0
    self.cg = ""
    self.cgEnding = ""
    self.cgCollect = ""
    self.title = ""
    self.desc = ""
    self.getConditionDesc = ""
    self.awards = {}
    self.isBE = false
end

---@return N28AVGAwardState
function N28AVGEnding:AwardState()
    local mRole = GameGlobal.GetModule(RoleModule)
    local countGift = mRole:GetAssetCount(self.itemIdGift)
    if countGift > 0 then --有CG礼包，表示可领奖
        return N28AVGAwardState.CanGet
    else --无CG礼包，表示已领奖或不可领
        local count = mRole:GetAssetCount(self.itemId)
        if count > 0 then --有CG道具，表示已领奖
            return N28AVGAwardState.Got
        end
    end
end
---是否已获取
function N28AVGEnding:HasGot()
    local state = self:AwardState()
    return state == N28AVGAwardState.Got
end
---是否有未领取奖励
function N28AVGEnding:HasRed()
    local state = self:AwardState()
    return state == N28AVGAwardState.CanGet
end
--是否有新获得CG
function N28AVGEnding:HasNew()
    local mItem = GameGlobal.GetModule(ItemModule)
    local items = mItem:GetItemByTempId(self.itemId)
    for _, item in pairs(items) do
        if item:IsNewOverlay() then
            return true
        end
    end
    return false
end

---@return number | nil CG 获取时间戳
function N28AVGEnding:GetTimestamp()
    if self.isBE then --BE没有获取CG
        return 0
    end
    local mItem = GameGlobal.GetModule(ItemModule)
    local items = mItem:GetItemByTempId(self.itemId)
    if items and table.count(items) > 0 then
        for key, item in pairs(items) do
            local ts = item:GetGainTime() --道具的获取时间即为CG获取时间
            return ts
        end
    end
    return 0
end
--endregion

--- @class N28AVGAwardState
---@field CanGet number 可领取
---@field Got ConditionType 已领取
local N28AVGAwardState = {
    CanGet = 1,
    Got = 2
}
_enum("N28AVGAwardState", N28AVGAwardState)

--region N28AVGCondition 条件
---@class N28AVGCondition:Object
---@field bt BehaviourTree 条件树
---@field default boolean bt为nil时IsSatisfy()默认返回值
_class("N28AVGCondition", Object)
N28AVGCondition = N28AVGCondition

function N28AVGCondition:Constructor(strCondition, default)
    self.hasCondition = true
    local mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = mCampaign:GetN28AVGData()
    self.bt = self:ParseCondition(strCondition)
    self.default = default or false
end

---@return boolean 本条件是否满足
function N28AVGCondition:IsSatisfy()
    if self.bt then
        local b = BTConditionManager:GetInstance():IsSatisfy(self.bt)
        return b
    end
    return self.default
end

function N28AVGCondition:GetHasCondition()
    return self.hasCondition
end

---解析条件
---@param strCondition string 条件字符串
---@return BehaviourTree
function N28AVGCondition:ParseCondition(strCondition)
    if string.isnullorempty(strCondition) then
        self.hasCondition = false
        Log.warn("### strCondition is nil.")
        return
    end
    local bt = nil
    local charAnd, charOr = "&", "|"
    local indexAnd, ph = string.find(strCondition, charAnd)
    local indexOr, ph = string.find(strCondition, charOr)
    if indexAnd and indexAnd > 0 then
        local nodes = {}
        local strs = string.split(strCondition, charAnd)
        for index, str in ipairs(strs) do
            local btNode = self:ParseConditionSpecific(str)
            table.insert(nodes, btNode)
        end
        bt = BTConditionManager:GetInstance():BuildBTAnd(nodes)
    elseif indexOr and indexOr > 0 then
        local nodes = {}
        local strs = string.split(strCondition, charOr)
        for index, str in ipairs(strs) do
            local btNode = self:ParseConditionSpecific(str)
            table.insert(nodes, btNode)
        end
        bt = BTConditionManager:GetInstance():BuildBTOr(nodes)
    else
        local btNode = self:ParseConditionSpecific(strCondition)
        bt = BTConditionManager:GetInstance():BuildBTSingle(btNode)
    end
    return bt
end
---@return BehaviourNode
function N28AVGCondition:ParseConditionSpecific(strConditionSingle)
    local charComma = ","
    local strs = string.split(strConditionSingle, charComma)
    local conditionId = ""
    local params = {}
    for index, str in ipairs(strs) do
        if index == 1 then
            conditionId = str
        elseif index == 2 or index == 3 then
            --活动id，组件枚举值
        else
            table.insert(params, str)
        end
    end
    local funcName = "ParseConditionSpecific" .. conditionId
    local func = self[funcName]
    if not func then
        Log.fatal("### no function names: ", funcName)
        return
    end
    local node = func(self, params)
    return node
end
---1230 CT_CampaignAVGHPCompare————血量满足大小条件【1230,组件id,ComparisonOperationType（int）,主角血量（int）】
---@return BehaviourNode
function N28AVGCondition:ParseConditionSpecific1230(strConditionParams)
    local comparisionType = tonumber(strConditionParams[1])
    local hpParam = tonumber(strConditionParams[2])
    local node =
        ComparisonOperationNode:New(
        nil,
        comparisionType,
        function()
            local hp, strategies = self.data:CalcCurData()
            return hp
        end,
        function()
            return hpParam
        end
    )
    return node
end
---1231 CT_CampaignAVGAffinityCompare——亲密度判断【1231,组件id,角色索引（int）,ComparisonOperationType（int）,角色攻略度（int）】
---@return BehaviourNode
function N28AVGCondition:ParseConditionSpecific1231(strConditionParams)
    local indexPartner = tonumber(strConditionParams[1])
    local comparisionType = tonumber(strConditionParams[2])
    local strategyParam = tonumber(strConditionParams[3])
    local node =
        ComparisonOperationNode:New(
        nil,
        comparisionType,
        function()
            local hp, strategies = self.data:CalcCurData()
            local strategy = strategies[indexPartner] or 0
            return strategy
        end,
        function()
            return strategyParam
        end
    )
    return node
end
---1232 CT_CampaignAVGChooseManual———本结点内是否选择过某选项【1232,组件id,选项id列表】
---@return BehaviourNode
function N28AVGCondition:ParseConditionSpecific1232(strConditionParams)
    local optionIds = {}
    for index, str in ipairs(strConditionParams) do
        local optionId = tonumber(str)
        table.insert(optionIds, optionId)
    end
    local node =
        self:NewConditionNode(
        function()
            if not GameGlobal.UIStateManager():IsShow("UIN28AVGStory") then
                return false
            end
            local selectedOptionIds = GameGlobal.UIStateManager():CallUIMethod("UIN28AVGStory", "SelectedOptionId")
            for index, optionId in ipairs(optionIds) do
                if not selectedOptionIds[optionId] then
                    return false
                end
            end
            return true
        end
    )
    return node
end
---1233 CT_CampaignAVGChooseDialog———生涯内是否选择过某选项【1233,组件id,选项id列表】
---@return BehaviourNode
function N28AVGCondition:ParseConditionSpecific1233(strConditionParams)
    local optionIds = {}
    for index, str in ipairs(strConditionParams) do
        local optionId = tonumber(str)
        table.insert(optionIds, optionId)
    end
    local node =
        self:NewConditionNode(
        function()
            for index, optionId in ipairs(optionIds) do
                if not self.data:IsSelectedOption(optionId) then
                    return false
                end
            end
            return true
        end
    )
    return node
end
---1234 CT_CampaignAVGComplateEnding——是否完成过某结局【1234,组件id,结局id列表】
---@return BehaviourNode
function N28AVGCondition:ParseConditionSpecific1234(strConditionParams)
    local endIds = {}
    for index, str in ipairs(strConditionParams) do
        local endId = tonumber(str)
        table.insert(endIds, endId)
    end
    local node =
        self:NewConditionNode(
        function()
            for index, endId in ipairs(endIds) do
                if not self.data:IsEndReach(endId) then
                    return false
                end
            end
            return true
        end
    )
    return node
end
function N28AVGCondition:NewConditionNode(func)
    local node = ConditionNode:New(nil, func)
    return node
end
--endregion

function AVGLog(...)
    if IsUnityEditor() then
        Log.fatal("### [AVG]", ...)
    end
end
