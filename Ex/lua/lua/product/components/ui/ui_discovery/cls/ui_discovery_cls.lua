--region DiscoveryData 探索类
---@field sections DiscoverySection[] 部列表
---@class DiscoveryData:Object
_class("DiscoveryData", Object)
DiscoveryData = DiscoveryData

function DiscoveryData:Constructor()
    self.cell_size = Vector2.zero
    self.fairy_land_pos = Vector2.zero
    ---@type DiscoveryChapter[] dict
    self.chapters = {}
    ---@type MissionModule
    self._module = nil
    self.mapScale = 1
    self.row = 0
    self.col = 0
    ---@type Vector2[] dict
    self.chapter_begin_pos = {}
    self._curPosNodeId = 0 --风船当前位置所在的路点id
    ---@type ChapterAwardData
    self.chapterAwardData = ChapterAwardData:New() --章节奖励
    self.showUIStage = false --是否显示关卡界面
    self.next_chapter = {} --下一章节位置、id、所连接路点id
    self.sections = {}
end
---初始化路点信息
function DiscoveryData:Init(cfg_discovery)
    self._module = GameGlobal.GetModule(MissionModule)
    local v2 = cfg_discovery.cell_size
    self.cell_size.x = v2.x
    self.cell_size.y = v2.y
    self.row = cfg_discovery.row
    self.col = cfg_discovery.col
    v2 = cfg_discovery.fairy_land_pos
    self.fairy_land_pos.x = v2.x
    self.fairy_land_pos.y = v2.y
    --章节初始位置
    for k, v in pairs(cfg_discovery.chapterBeginPos) do
        self.chapter_begin_pos[k] = Vector2(v.pos.x, v.pos.y)
    end
    --下一章节信息
    for k, v in pairs(cfg_discovery.nextChapter) do
        self.next_chapter[k] = {pos = Vector2(v.pos.x, v.pos.y), chapterId = v.chapterId, lastNodeId = v.lastNode}
    end
    --章节数据
    local cfg_mission_chapter = table.cloneconf(Cfg["cfg_mission_chapter"]()) --？
    if not cfg_mission_chapter then
        Log.fatal("### DiscoveryData:Init cfg_mission_chapter is nil.")
    end
    self.chapters = {}
    local chapterId = 0
    local idx = 1
    local fullIdx = 0
    for k, v in pairs(cfg_mission_chapter) do
        local mainChapterId = v.MainChapterID --章节id
        local stageId = v.MissionID --关卡id
        local wayPointId = v.WayPointID --路点id
        --region 关卡
        local stage = DiscoveryStage:New()
        stage:Init(stageId, wayPointId)
        --endregion
        --region 路点
        local node = DiscoveryNode:New()
        local cfgNode = cfg_discovery.map_nodes[wayPointId]
        node:Init(wayPointId, cfgNode, v.Type)
        if v.Type == 1 then --主支有idx
            if chapterId ~= mainChapterId then
                chapterId = mainChapterId
                idx = 1
            else
                idx = idx + 1
            end
            fullIdx = fullIdx + 1
            node.idx = idx
            node.fullIdx = fullIdx
        end
        --endregion
        --region 章节
        if not self.chapters[mainChapterId] then --没有就new一个
            self.chapters[mainChapterId] = DiscoveryChapter:New()
            self.chapters[mainChapterId]:Init(mainChapterId)
        end
        --endregion
        table.insert(node.stages, stage) --存储成数组
        table.insert(self.chapters[mainChapterId].nodes, node)
    end
    --连线
    for chapterId, chapter in pairs(self.chapters) do
        for i, node in ipairs(chapter.nodes) do
            for j, line in ipairs(cfg_discovery.lines) do
                if node.id == line.s then
                    if not chapter.lines[line.s] then --一个路点可能有多个下线
                        chapter.lines[line.s] = {}
                    end
                    table.insert(chapter.lines[line.s], line.e)
                end
            end
        end
    end
    self:InitSections()
end

function DiscoveryData:InitSections()
    self.sections = {}
    for chapterId, chapter in pairs(self.chapters) do
        local stage = chapter:Get1stStage()
        if stage then
            local sectionId = stage.sectionId
            if not self.sections[sectionId] then
                self.sections[sectionId] = DiscoverySection:New()
                self.sections[sectionId].id = sectionId
                self.sections[sectionId].index_name = StringTable.Get("str_chapter_section_index_" .. sectionId)
                self.sections[sectionId].name = StringTable.Get("str_chapter_section_name_" .. sectionId)
                local betweenChapters = Cfg.cfg_global["ui_discovery_between_chapters"].ArrayValue
                self.sections[sectionId].isBetween = table.icontains(betweenChapters, sectionId) or false
                self.sections[sectionId].icon = Cfg.cfg_discovery_section[sectionId].icon
            end
            if not self.sections[sectionId].chapterIds[chapterId] then
                self.sections[sectionId].chapterIds[chapterId] = true
            end
        end
    end
end

---获取所有章节的列表
---@return DiscoveryChapter[]
function DiscoveryData:GetChapters()
    return self.chapters
end
---获取可见章节的列表
---@return DiscoveryChapter[]
function DiscoveryData:GetVisibleChapters()
    local dict = {}
    if self.chapters then
        for k, v in pairs(self.chapters) do
            if v:State() then
                dict[k] = v
            end
        end
    end
    return dict
end
---@return DiscoveryChapter[] 获取sectionId部中可见章节的列表
function DiscoveryData:GetVisibleChaptersOfSection(sectionId)
    local vChapters = {}
    if self.chapters then
        for k, chapter in pairs(self.chapters) do
            if chapter:GetSectionId() == sectionId and chapter:State() then
                table.insert(vChapters, chapter)
            end
        end
    end
    return vChapters
end

---@param passStages mission_info[] 通关关卡列表
---@param canActiveStages mission_info[] 可激活关卡列表
---更新路点信息
function DiscoveryData:Update(passStages, canActiveStages)
    for k, v in pairs(self.chapters) do
        v:UpdateState()
    end
end

---@public
---@param stageId number 所需查询的关卡id
---@return DiscoveryNode 结点信息
function DiscoveryData:GetNodeDataByStageId(stageId)
    for _, chapter in pairs(self.chapters) do
        for _, node in ipairs(chapter.nodes) do
            for _, stage in ipairs(node.stages) do
                if stage.id == stageId then
                    return node
                end
            end
        end
    end
    return nil
end
function DiscoveryData:GetCanMoveNodeDataByStageId(stageId)
    local node = self:GetNodeDataByStageId(stageId)
    local stage = node:GetStageById(stageId)
    if not stage.state then
        local nodeT = self:GetCanPlayNode()
        return nodeT
    else
        return node
    end
end

---@public
---@param nodeId number 所需查询的结点id
---@return DiscoveryNode 结点信息
function DiscoveryData:GetNodeDataByNodeId(nodeId)
    for _, chapter in pairs(self.chapters) do
        for _, node in ipairs(chapter.nodes) do
            if node.id == nodeId then
                return node
            end
        end
    end
    return nil
end

---@public
---@param nodeId number 所需查询的结点id
---@return Vector2 结点位置
function DiscoveryData:GetPosByNodeId(nodeId, isV3)
    local node = self:GetNodeDataByNodeId(nodeId)
    if node then
        return isV3 and Vector3(node.pos.x, node.pos.y) or node.pos
    end
    return isV3 and Vector3.zero or Vector2.zero
end

---@public
---@return DiscoveryStage[]
---获取可观看剧情的关卡列表
function DiscoveryData:GetCanReviewStorys()
    local stages = {}
    for _, chapter in pairs(self.chapters) do
        for _, node in ipairs(chapter.nodes) do
            if node:State() == DiscoveryStageState.Nomal then
                local stage = node.stages[1]
                if stage:IsThereStory() then --有剧情的才加入数组
                    table.insert(stages, stage)
                end
            end
        end
    end
    return stages
end

---根据关卡id获取该关卡的剧情信息
---@param stageId number 关卡id
---@param storyType StoryTriggerType 剧情触发类型
function DiscoveryData:GetStoryByStageIdStoryType(stageId, storyType)
    local node = self:GetNodeDataByStageId(stageId)
    if node then
        return node.stages[1].story:GetStoryByStoryType(storyType)
    end
    return nil
end

---@param stageId number 关卡ID
---@return DiscoveryChapter
---根据关卡ID获取章节信息
function DiscoveryData:GetChapterByStageId(stageId)
    if stageId == 0 then --如果关卡id为0，则默认设为第一关
        return self:Get1stChapter()
    end
    for _, chapter in pairs(self.chapters) do
        for _, node in ipairs(chapter.nodes) do
            for _, stage in ipairs(node.stages) do
                if stage.id == stageId then
                    return chapter
                end
            end
        end
    end
end

---获取第一章
function DiscoveryData:Get1stChapter()
    for k, v in pairs(self.chapters) do
        return v
    end
end
---获取最后一章
---@return DiscoveryChapter
function DiscoveryData:GetLastChapter()
    local last = nil
    for k, v in pairs(self.chapters) do
        last = v
    end
    return last
end

---@return DiscoveryChapter
---根据章节id获取章节信息
function DiscoveryData:GetChapterByChapterId(chapterId)
    return self.chapters[chapterId]
end

---@return DiscoveryChapter, DiscoveryNode
---获取可激活的[主线]关卡所在章节和路点
---优先活动路点
function DiscoveryData:GetCanPlayChapterNode()
    for _, chapter in pairs(self.chapters) do
        local node = chapter:Get1stCanPlayNode()
        if node then
            return chapter, node
        end
    end
end

--获取最后一个 CanPlay 或 Nomal 的路点，即最后一个可打路点
---@return DiscoveryNode
function DiscoveryData:GetCanPlayNode()
    local nodeT
    for _, chapter in pairs(self.chapters) do
        for _, node in ipairs(chapter.nodes) do
            if node:State() then
                nodeT = node
            end
        end
    end
    return nodeT
end

--region 风船位置
---@return DiscoveryNode 获取当前要聚焦的路点
function DiscoveryData:GetCurPosNode()
    if self._curPosNodeId == 0 then --如果_curPosNodeId为0，则返回第一章第一个路点
        local fstChapter = self:Get1stChapter()
        local fstNode = fstChapter:Get1stNode()
        return fstNode
    end
    if self._curPosNodeId < 0 then --如果_curPosNodeId为负，则返回第一章第一个路点
        self._curPosNodeId = 0
        return self:GetCurPosNode()
    end
    local node = self:GetNodeDataByNodeId(self._curPosNodeId)
    return node
end
---@param nodeId number 设置当前路点
function DiscoveryData:SetCurPosNodeId(nodeId)
    if nodeId < 0 then
        return
    end
    self._curPosNodeId = nodeId
end
---@return DiscoveryChapter
---获取当前位置的章节
function DiscoveryData:GetCurPosChapter()
    local node = self:GetCurPosNode()
    if node then
        return node:GetChapter()
    end
end

---@param enterFlag number
---1-定位到当前可打路点，如从大厅界面探索进时
---2-定位到param所对应的章节的第一个可打路点，该章已通关则定位到该章第一个路点，如选择章节列表时
---3-定位到param所对应的关卡id所对应的的路点，并且打开关卡详情，如点击背包物品的掉落来源按钮时
---4-处理对局整理后解锁的是下一章的情况，让风船在下一章第一关之前，而不是当前章最后一个路点位置，如对局胜利后
---5-定位到param所对应的关卡id所对应的的路点
---6-？
---7-活动开启时，从活动入口、探索、切章节，以及从活动对局进入大地图
---@param param any enterFlag为2时表示章节id，enterFlag为3时表示关卡id 5.用于新手引导第一关直接跳到第二关 强制设置下路点
---根据大地图入口设置风船位置
function DiscoveryData:UpdatePosByEnter(enterFlag, param)
    if enterFlag == 1 then
        local canPlayChapter, canPlayNode = self:GetCanPlayChapterNode()
        if canPlayChapter and canPlayNode then
            self:SetCurPosNodeId(canPlayNode.id)
        else --已通关，定位到最后一章的第一个路点
            local module = GameGlobal.GetModule(MissionModule)
            local stageId = module:GetCurMissionID()
            local chapter = self:GetChapterByStageId(stageId)
            if not chapter then
                chapter = self:GetLastChapter()
            end
            local fstNode = chapter:Get1stNode()
            self:SetCurPosNodeId(fstNode.id)
        end
    elseif enterFlag == 2 then
        local chapterId = param
        local chapter = self:GetChapterByChapterId(chapterId)
        local node = chapter:Get1stCanPlayNode() --该章第一个可打的主线路点
        if node then
            self:SetCurPosNodeId(node.id)
        else
            local fstNode = chapter:Get1stNode()
            self:SetCurPosNodeId(fstNode.id)
        end
    elseif enterFlag == 3 then
        local stageId = param
        local node = self:GetNodeDataByStageId(stageId)
        self:SetCurPosNodeId(node.id)
        self.showUIStage = true
    elseif enterFlag == 4 then
        local canPlayChapter, canPlayNode = self:GetCanPlayChapterNode()
        if canPlayChapter and canPlayNode then
            local fstNode = canPlayChapter:Get1stNode()
            if fstNode.id == canPlayNode.id then --当激活的路点是章节首路点
                if canPlayNode:IsFirstShow() then --当激活路点是首次出现
                    self:SetCurPosNodeId(canPlayNode.id)
                end
            end
        end
    elseif enterFlag == 5 then
        local stageId = param
        local node = self:GetNodeDataByStageId(stageId)
        self:SetCurPosNodeId(node.id)
    elseif enterFlag == 6 then
        local stageId = param
        local node = self:GetCanMoveNodeDataByStageId(stageId)
        self:SetCurPosNodeId(node.id)
        self.showUIStage = true
    elseif enterFlag == 7 then
        local stageId = param
        local grassData = GameGlobal.GetModule(CampaignModule):GetGraveRobberData()
        if stageId then
            local nodeGrass = grassData:GetNodeByStageId(stageId)
            local chapter = self:GetChapterByChapterId(nodeGrass.chapterId)
            local node = chapter:Get1stNode()
            self:SetCurPosNodeId(node.id)
            grassData:SaveGrassNodeFirst(nodeGrass)
        else
            local canPlayGrassNode = grassData:GetCanPlayNode()
            local chapter = self:GetChapterByChapterId(canPlayGrassNode.chapterId)
            local canPlayMainNode = chapter:Get1stNode()
            self:SetCurPosNodeId(canPlayMainNode.id)
            grassData:SaveGrassNodeFirst(canPlayGrassNode)
        end
    elseif enterFlag == 8 then
        --困难关路点
        self._isDiff = true
        ---@type UIDiffMissionModule
        local uiDiffModule = GameGlobal.GetUIModule(DifficultyMissionModule)
        uiDiffModule:SetMoveNodePos(param)
    elseif enterFlag == 9 then
        self._showDiffStage = true
        self._showNodeID = param
        --困难关路点
        self._isDiff = true
        ---@type UIDiffMissionModule
        local uiDiffModule = GameGlobal.GetUIModule(DifficultyMissionModule)
        uiDiffModule:SetMoveNodePos(param)
    end
end
--endregion
function DiscoveryData:GetDiffNodeInfo()
    if self._isDiff then
        self._isDiff = false
        return true
    end
    return false
end
---@param enterFlag number 见DiscoveryData:UpdatePosByEnter()
---统一进大地图方法，经过loading
function DiscoveryData.EnterStateUIDiscovery(enterFlag, param)
    local module = GameGlobal.GetModule(MissionModule)
    local data = module:GetDiscoveryData()
    data:UpdatePosByEnter(enterFlag, param)
    --GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Discovery_Enter)
    CutsceneManager.ExcuteCutsceneIn(
            UIStateType.UIMain,
            function()
                GameGlobal.UIStateManager():SwitchState(UIStateType.UIDiscovery)
            end
        )
end

---@return boolean
function DiscoveryData:IsChapterReachUnlockTime(chapterId)
    local chapter = self:GetChapterByChapterId(chapterId)
    local isUnlock = chapter:IsReachUnlockTime()
    return isUnlock
end

---@return DiscoverySection
function DiscoveryData:GetDiscoverySectionBySectionId(sectionId)
    for _, section in pairs(self.sections) do
        if sectionId == section.id then
            return section
        end
    end
end
---@return DiscoverySection
function DiscoveryData:GetDiscoverySectionByChapterId(chapterId)
    for _, section in pairs(self.sections) do
        for cId, b in pairs(section.chapterIds) do
            if chapterId == cId then
                return section
            end
        end
    end
end
---@return DiscoverySection
function DiscoveryData:GetDiscoveryLastSection()
    local len = table.count(self.sections)
    local last = self.sections[len]
    return last
end
--endregion

--region DiscoverySection 部类
---@class DiscoverySection:Object
_class("DiscoverySection", Object)
DiscoverySection = DiscoverySection

function DiscoverySection:Constructor()
    self.id = 0 --部id
    self.index_name = "" --部索引名
    self.name = "" --部名
    self.chapterIds = {} --该部的章节Id列表 k=chapterId v=是否解锁
    self.isBetween = false --是否间章部
    self.icon = "" --图标

    self.data = GameGlobal.GetModule(MissionModule):GetDiscoveryData()
end

---@return DiscoveryStageState, number 状态，章节id
function DiscoverySection:State()
    local completeCount = 0
    for chapterId, b in pairs(self.chapterIds) do
        local chapter = self.data:GetChapterByChapterId(chapterId)
        if chapter then
            local state = chapter:State()
            if state == DiscoveryStageState.CanPlay then
                return DiscoveryStageState.CanPlay, chapterId
            elseif state == DiscoveryStageState.Nomal then
                completeCount = completeCount + 1
            end
        end
    end
    if completeCount == table.count(self.chapterIds) then
        return DiscoveryStageState.Nomal
    end
    return nil
end
--endregion

--region DiscoveryChapter 章节类
---@class DiscoveryChapter:Object
_class("DiscoveryChapter", Object)
DiscoveryChapter = DiscoveryChapter

function DiscoveryChapter:Constructor()
    self.id = 0 --章节id——不同于关卡id
    self.index_name = "" --章节索引名——第N章
    self.index_name_en = "" --章节索引英文名——Chapter N
    self.name = "" --章节名
    self.name_en = "" --章节英文名
    ---@type DiscoveryNode[]
    self.nodes = {} --该章节的路点列表
    self.lines = {} --该章节的路径字典 key=线头路点id value=线尾路点id
end

function DiscoveryChapter:Init(id)
    self.id = id
    self.index_name = StringTable.Get("str_chapter_idx_" .. id)
    self.index_name_en = StringTable.Get("str_chapter_idx_" .. id .. "_en")
    self.name = StringTable.Get("str_chapter_" .. id)
    self.name_en = StringTable.Get("str_chapter_" .. id .. "_en")
end

---更新路点状态
function DiscoveryChapter:UpdateState()
    for _, node in ipairs(self.nodes) do
        node:UpdateState()
    end
end

---@return boolean
---判断该章节主线是否通关
function DiscoveryChapter:IsComplete()
    local totalCount = 0
    local passCount = 0
    for _, node in ipairs(self.nodes) do
        if node.type == DiscoveryNodeType.Main then
            totalCount = totalCount + 1
            if node:State() == DiscoveryStageState.Nomal then
                passCount = passCount + 1
            end
        end
    end
    return totalCount == passCount
end
--全部三星通关
function DiscoveryChapter:IsThreeComplete()
    local three = true
    for _, node in ipairs(self.nodes) do
        if node.type == DiscoveryNodeType.Main or node.type == DiscoveryNodeType.Branch then
            local stages = node.stages
            if next(stages) then
                for i = 1, #stages do
                    local stage = stages[i]
                    if stage.type ~= DiscoveryStageType.Plot and not stage:HasPassThreeStar() then
                        three = false
                        return three
                    end
                end
            end
        end
    end
    return three
end
---@return DiscoveryNode
---获取本章第一个路点
function DiscoveryChapter:Get1stNode()
    for _, node in ipairs(self.nodes) do
        if node.idx == 1 then
            return node
        end
    end
end

---@return DiscoveryStage
---获取本章第一关
function DiscoveryChapter:Get1stStage()
    local node = self:Get1stNode()
    if node then
        for _, stage in ipairs(node.stages) do
            return stage
        end
    end
end

---@return DiscoveryNode
---获取本章主线第一个可挑战路点
function DiscoveryChapter:Get1stCanPlayNode()
    for _, node in ipairs(self.nodes) do
        if node.type == DiscoveryNodeType.Main and node:State() == DiscoveryStageState.CanPlay then
            return node
        end
    end
end

---@return DiscoveryNode
---获取本章的状态：CanPlay-该章有可打路点；Nomal-该章已通关；nil-该章未激活，不可见
function DiscoveryChapter:State()
    if self:IsReachUnlockTime() then --到达解锁时间
        local completeCount = 0
        for _, node in ipairs(self.nodes) do
            local state = node:State()
            if state == DiscoveryStageState.CanPlay then
                return DiscoveryStageState.CanPlay
            elseif state == DiscoveryStageState.Nomal then
                completeCount = completeCount + 1
            end
        end
        if completeCount == table.count(self.nodes) then
            return DiscoveryStageState.Nomal
        end
    end
    return nil
end

---获取nodeId的前置路点
function DiscoveryChapter:PrevNode(nodeId)
    local prevStageId = 0
    local node = self:GetNodeByNodeId(nodeId)
    if node then
        local fstNode = self:Get1stNode()
        if fstNode.id == node.id then --该章第一个路点没有前置路点
            return nil
        end
        for istage, vstage in ipairs(node.stages) do
            prevStageId = tonumber(vstage.prevStageId[1])
            break
        end
    end
    ---@type DiscoveryData
    local data = self:GetDiscoveryData()
    local node = data:GetNodeDataByStageId(prevStageId)
    return node
end

---@return DiscoveryData
function DiscoveryChapter:GetDiscoveryData()
    ---@type MissionModule
    local module = GameGlobal.GetModule(MissionModule)
    return module:GetDiscoveryData()
end

---@return DiscoveryNode
---根据路点ID获取路点信息
function DiscoveryChapter:GetNodeByNodeId(nodeId)
    for _, node in ipairs(self.nodes) do
        if node.id == nodeId then
            return node
        end
    end
end
---本章节的部
function DiscoveryChapter:GetSectionId()
    local stage = self:Get1stStage()
    return stage.sectionId
end

---是否已达解锁时间
function DiscoveryChapter:IsReachUnlockTime()
    local cfg = Cfg.cfg_global["ui_chapter_unlock_time"].TableValue
    if not cfg then
        return false
    end
    local unlockTimestamp = cfg[self.id] or 0
    local nowTimestamp = UICommonHelper.GetNowTimestamp()
    local isUnlock = nowTimestamp > unlockTimestamp
    return isUnlock
end

--endregion

--region 路点类----------------------------------------------------
---@class DiscoveryNode:Object
---@field stages DiscoveryStage[] 关卡列表
_class("DiscoveryNode", Object)
DiscoveryNode = DiscoveryNode

function DiscoveryNode:Constructor()
    self.id = 0 --路点id
    self.idx = 0 --该路点是该章主线的第几个路点
    self.fullIdx = 0 --该路点是所有主线的第几个路点
    self.name = ""
    self.monstercg = ""
    self.pos = Vector2.zero --结点坐标
    self.stages = {} --保存结点的所有关卡
    self.type = DiscoveryNodeType.Main --路点是主线/支线
    --
    self._missionModule = GameGlobal.GetModule(MissionModule)
end

function DiscoveryNode:Init(id, nodeV, type)
    if not nodeV then
        Log.fatal("### no waypoint in cfg_discovery. WayPointID=", id)
    end
    self.id = id
    self.pos.x = nodeV.pos.x
    self.pos.y = nodeV.pos.y
    local cfgv = Cfg.cfg_waypoint[id]
    if cfgv then
        self.monstercg = cfgv.MonsterCG
        self.name = StringTable.Get(cfgv.Name)
    end
    if type == 1 then
        self.type = DiscoveryNodeType.Main
    elseif type == 2 then
        self.type = DiscoveryNodeType.Branch
    end
end

--更新结点状态
function DiscoveryNode:UpdateState()
    for i, v in ipairs(self.stages) do
        local passStage = self._missionModule:GetPassMissionById(v.id)
        local canActiveSatge = self._missionModule:GetCanActiveMissionById(v.id)
        if passStage then
            local starCount, completeStarList = self._missionModule:ParseStarInfo(passStage.star)
            v:UpdateStar(starCount)
            v:UpdateCondition(completeStarList)
            v:UpdateState(DiscoveryStageState.Nomal)
        end
        if canActiveSatge then
            v:UpdateStar(0)
            v:UpdateState(DiscoveryStageState.CanPlay)
        end
    end
    if self.id then
        Log.debug("###[DiscoveryNode] UpdateState pass mission id : ",self.id)
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.DiscoveryNodeStateChange, self.id)
end

---@public
---@return DiscoveryStageState
---当前结点的状态
function DiscoveryNode:State()
    if self.stages then
        local passCount = 0
        local canActiveCount = 0
        for i, v in ipairs(self.stages) do
            if v.state == DiscoveryStageState.Nomal then
                passCount = passCount + 1
            elseif v.state == DiscoveryStageState.CanPlay then
                canActiveCount = canActiveCount + 1
            end
        end
        if passCount > 0 then --只要有一个关卡通关，该路点就是通关状态
            return DiscoveryStageState.Nomal
        end
        if canActiveCount > 0 then --只要有一个可激活关卡，该路点就是可挑战状态
            return DiscoveryStageState.CanPlay
        end
    end
    return nil --否则就是未激活状态，不可见
end

---玩家等级是否达到
function DiscoveryNode:LevelReach()
    for i, v in ipairs(self.stages) do
        return v:LevelReach()
    end
end

---@public
---@return DiscoveryStageType
---获取关卡类型：普通战斗关，Boss战斗关，剧情关
function DiscoveryNode:GetStageType()
    for i, v in ipairs(self.stages) do
        return v.type
    end
end

--获取当前可以玩的关卡列表
---@return DiscoveryStage[]
function DiscoveryNode:GetCanPlayStages()
    local stages = {}
    for i, v in ipairs(self.stages) do
        if v.state then
            table.insert(stages, v) --数组
        end
    end
    return stages
end

---@public
---@return DiscoveryStage
---根据关卡id获取关卡数据
function DiscoveryNode:GetStageById(stageId)
    if self.stages and #self.stages > 0 then
        for i, v in ipairs(self.stages) do
            if v.id == stageId then
                return v
            end
        end
    end
    return nil
end

---@return boolean 是否是第一次显示
function DiscoveryNode:IsFirstShow()
    local playerPrefsKey = self:GetFirstShowKey()
    local isFirst = UnityEngine.PlayerPrefs.GetInt(playerPrefsKey, 0)
    return isFirst == 0
end
function DiscoveryNode:SaveIsFirstShow()
    local playerPrefsKey = self:GetFirstShowKey()
    UnityEngine.PlayerPrefs.SetInt(playerPrefsKey, 1)
end
function DiscoveryNode:GetFirstShowKey()
    local playerPrefsKey = self:GetPstId() .. "DiscoveryNodeIsFirstShow" .. self.id
    return playerPrefsKey
end
---@private
function DiscoveryNode:GetPstId()
    local roleModule = GameGlobal.GetModule(RoleModule)
    return roleModule:GetPstId()
end

---获取该路点对应的章节
function DiscoveryNode:GetChapter()
    if self.stages then
        for i, v in ipairs(self.stages) do
            return v:GetChapter()
        end
    end
end
--endregion

--- @class DiscoveryNodeType
local DiscoveryNodeType = {
    Main = 1, --主线
    Branch = 2 --支线
}
_enum("DiscoveryNodeType", DiscoveryNodeType)
