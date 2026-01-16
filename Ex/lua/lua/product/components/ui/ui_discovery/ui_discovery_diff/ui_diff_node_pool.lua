---@class UIDiffNodePool:UICustomWidget
_class("UIDiffNodePool", UICustomWidget)
UIDiffNodePool = UIDiffNodePool

function UIDiffNodePool:Constructor()
    self.mMission = self:GetModule(MissionModule)
    self.data = self.mMission:GetDiscoveryData()
end

function UIDiffNodePool:OnShow()
    self.chapter = self:GetGameObject("chapter")
    self.section = self:GetGameObject("section")
    ---@type UICustomWidgetPool
    self._normalNodesPool = self:GetUIComponent("UISelectObjectPath", "Normal")
    ---@type UICustomWidgetPool
    self._bossNodesPool = self:GetUIComponent("UISelectObjectPath", "Boss")
    ---@type UICustomWidgetPool
    self._plotNodesPool = self:GetUIComponent("UISelectObjectPath", "Plot")
    ---@type UICustomWidgetPool
    self._notReachNodesPool = self:GetUIComponent("UISelectObjectPath", "NotReach")
    ---@type UICustomWidgetPool
    self._nextChapterPool = self:GetUIComponent("UISelectObjectPath", "NextChapter")
    ---@type UICustomWidgetPool
    self.nSectionPool = self:GetUIComponent("UISelectObjectPath", "nSection")
    ---@type UICustomWidgetPool
    self.GrassPool = self:GetUIComponent("UISelectObjectPath", "Grass")
end
---@param nodes DiffMissionNode[]
function UIDiffNodePool:SetData(nodes,chapter)
    self._chapter = chapter
    local plot = {}
    local norm = {}
    local boss = {}
    local next = {}
    for i = 1, #nodes do
        local node = nodes[i]
        if node:Next() then
            table.insert(next,node)
        else
            if node:Type() == 1 then
                table.insert(norm,node)
            elseif node:Type() == 2 then
                table.insert(boss,node)
            end
        end
    end

    self._normalNodesPool:SpawnObjects("UIDiffNodeNorm", #norm)
    self._bossNodesPool:SpawnObjects("UIDiffNodeBoss", #boss)
    self._plotNodesPool:SpawnObjects("UIDiffNodePlot", #plot)
    self._nextChapterPool:SpawnObjects("UIDiffNodeNext", #next)
    ---@type UIDiffNodeNorm[]
    local normalNodes = self._normalNodesPool:GetAllSpawnList()
    ---@type UIDiffNodeBoss[]
    local bossNodes = self._bossNodesPool:GetAllSpawnList()
    local plotNodes = self._plotNodesPool:GetAllSpawnList()
    local nextNodes = self._nextChapterPool:GetAllSpawnList()

    for i = 1, #normalNodes do
        local item = normalNodes[i]
        local data = norm[i]
        item:SetData(data,function(node)
            self:NodeItemClick(node)
        end)
    end
    for i = 1, #bossNodes do
        local item = bossNodes[i]
        local data = boss[i]
        item:SetData(data,function(node)
            self:NodeItemClick(node)
        end)
    end
    for i = 1, #plotNodes do
        local item = plotNodes[i]
        local data = plot[i]
        item:SetData(data,function(node)
            self:NodeItemClick(node)
        end)
    end
    for i = 1, #nextNodes do
        local item = nextNodes[i]
        local data = next[i]
        item:SetData(data,function(node)
            self:NodeItemClick(node)
        end)
    end
end
function UIDiffNodePool:NodeItemClick(node)
    local pos = node:Pos()
    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.DiscoveryCameraMove,
        pos,
        -1,
        false,
        function()
            if node:Next() then
                --打开下一章节
                ---@type UIDiffMissionModule
                local uiModule = GameGlobal.GetUIModule(DifficultyMissionModule)
                local diffCid = node:ChapterID()
                local nextChapterID = uiModule:GetNextChapterID(diffCid)
                --如果有下一章
                if nextChapterID then
                    --检查下一张的开启状态
                    local nextChapter = uiModule:GetChapterData(nextChapterID)
                    if nextChapter then
                        --先检查主线全部三星
                        local missionid = nextChapter:MissionChapterID()
                        local missionModule = self:GetModule(MissionModule)
                        local data = missionModule:GetDiscoveryData()
                        local c = data:GetChapterByChapterId(missionid)
                        local complete = c:IsThreeComplete()
                        if not complete then
                            local missionChapterName = c.name
                            local tips = StringTable.Get("str_diff_mission_main_chapter_lock",missionChapterName)
                            ToastManager.ShowToast(tips)
                            return
                        end

                        --再检查下一章开启
                        if nextChapter:Lock() == DiffMissionChapterStatus.Lock then
                            local diffChapterName = StringTable.Get(nextChapter:Name())
                            local tips = StringTable.Get("str_diff_mission_diff_chapter_lock",diffChapterName)
                            ToastManager.ShowToast(tips)
                            return
                        end
                    end

                    uiModule:JumpNextChapter(nextChapterID)
                end
            else
                if node:Type() == 1 then
                    self:ShowDialog("UIDiffStage",self._chapter,node)
                elseif node:Type() == 2 then
                    self:ShowDialog("UIDiffStage",self._chapter,node)
                end
            end
        end
    )
end
function UIDiffNodePool:OnHide()
end
