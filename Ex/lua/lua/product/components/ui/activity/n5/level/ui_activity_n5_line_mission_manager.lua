---@class UIActivityN5LineMissionManager:Object
_class("UIActivityN5LineMissionManager", Object)
UIActivityN5LineMissionManager = UIActivityN5LineMissionManager

function UIActivityN5LineMissionManager:Constructor()
    --- @type MissionModule
    self._missionModule = GameGlobal.GetModule(MissionModule)

    --- @type LineMissionComponentInfo
    self._componentInfo = nil

    -- 节点数据 <missionID, node>
    ---@type table<number, UIActivityMissionNodeInfo>
    self.nodes = {}

    -- 路径数据 <startNode, endNode>
    ---@type table<UIActivityMissionNodeInfo, UIActivityMissionNodeInfo>
    self.lines = {}

    -- cfg_component_line_mission_extra 配置中的布局信息
    self._lineExtraCfg = {}

    -- cfg_component_line_mission 配置中筛选使用范围内的数据
    self._lineCfg = {}

    -- cfg_component_line_mission 配置中解锁关系
    self._unlockCfg = {}

    -- 根据 ComponentInfo 中完成的关卡数据，计算出需要显示的关卡状态
    self._missionState = {}

    -- 滑动区域宽度
    self.totalWidth = 0
end

---@return table<number, UIActivityMissionNodeInfo>
function UIActivityN5LineMissionManager:GetNodes()
    return self.nodes
end

---@return table<UIActivityMissionNodeInfo, UIActivityMissionNodeInfo>
function UIActivityN5LineMissionManager:GetLines()
    return self.lines
end

function UIActivityN5LineMissionManager:GetTotalWidth()
    return self.totalWidth
end

function UIActivityN5LineMissionManager:GetScrollPos(missionId)
    if self._lineCfg[missionId] then
        return self._lineCfg[missionId].ScrollPos
    end
    return nil
end

function UIActivityN5LineMissionManager:GetLineExtraConfig()
    return self._lineExtraCfg
end

function UIActivityN5LineMissionManager:Init(componentInfo, componentId)
    self._componentInfo = componentInfo

    self:_MakeLineExtraConfig(componentId)
    self:_MakeLineConfig(componentId)
    self:_MakeUnlockConfig(self._lineCfg)

    self:Update()
end

function UIActivityN5LineMissionManager:Update()
    self:_UpdateMissionState(self._unlockCfg)
    self:_UpdateNodePos(self._lineCfg, self._missionState)

    self:_FillData_Nodes(self._lineCfg, self._missionState)
    self:_FillData_Lines(self.nodes, self._unlockCfg)
end

function UIActivityN5LineMissionManager:_MakeLineExtraConfig(componentId)
    local newConfig = {}
    local config = Cfg.cfg_component_line_mission_extra {ComponentID = componentId}
    if not config then
        newConfig._NodeWidthLeft = 330
        newConfig._NodeWidthRight = 330
        newConfig._MarginLeft = 300
        newConfig._MarginRight = 300
        newConfig._Scale = 1.3
    else
        for _, v in pairs(config) do
            newConfig._NodeWidthLeft = v.NodeWidthLeft or 0
            newConfig._NodeWidthRight = v.NodeWidthRight or 0
            newConfig._MarginLeft = v.MarginLeft or 0
            newConfig._MarginRight = v.MarginRight or 0
            newConfig._Scale = v.Scale or 1.0
        end
    end
    
    self._lineExtraCfg = newConfig
end

function UIActivityN5LineMissionManager:_MakeLineConfig(componentId)
    local newConfig = {}
    local config = Cfg.cfg_component_line_mission {ComponentID = componentId}
    for _, v in ipairs(config) do
        newConfig[v.CampaignMissionId] = v
    end
    self._lineCfg = newConfig
end

function UIActivityN5LineMissionManager:_MakeUnlockConfig(lineMission)
    local newConfig = {}
    for _, v in pairs(lineMission) do
        local prev = v.NeedMissionId
        if not newConfig[prev] then
            newConfig[prev] = {}
        end

        local curr = v.CampaignMissionId
        if not newConfig[curr] then
            newConfig[curr] = {}
        end

        table.insert(newConfig[prev], curr)
    end

    self._unlockCfg = newConfig
end

function UIActivityN5LineMissionManager:_UpdateMissionState(unlockMission)
    ---@type table<number, cam_mission_info> 完成的关卡数据<missionID, cam_mission_info>
    local missionClear = self._componentInfo.m_pass_mission_info

    local newConfig = {}
    for k, v in pairs(unlockMission) do
        if k == 0 or missionClear[k] then
            -- 已通关关卡更新状态
            if k ~= 0 then
                if not newConfig[k] then
                    newConfig[k] = {}
                end
                local count = 0
                local tb = {}
                count, tb = self._missionModule:ParseStarInfo(missionClear[k].star)
                newConfig[k].State = DiscoveryStageState.Nomal
                newConfig[k].StarCount = count
            end

            -- 解锁后续关卡
            -- 后续关卡已通关的情况，如果之前已经更新过状态，则 not newConfig[vv] 的判断不会进入
            -- 如果之前没有更新过状态，之后会更新时会修改到正确的状态
            for _, vv in ipairs(v) do
                if not newConfig[vv] then
                    newConfig[vv] = {}
                    newConfig[vv].State = DiscoveryStageState.CanPlay
                    newConfig[vv].StarCount = 0
                end
            end
        end
    end

    self._missionState = newConfig
end

function UIActivityN5LineMissionManager:_UpdateNodePos(lineMission, missionState)
    local minPosX = nil
    local maxPosX = nil
    for k, v in pairs(lineMission) do
        if missionState[k] then
            if not minPosX or not maxPosX then
                minPosX, maxPosX = v.MapPosX, v.MapPosX
            end
            minPosX = math.min(minPosX, v.MapPosX) -- 配置中最左侧 Node 的位置
            maxPosX = math.max(maxPosX, v.MapPosX) -- 配置中最右侧 Node 的位置
        end
    end

    if not minPosX or not maxPosX then
        return
    end

    local marginLeft = self._lineExtraCfg._MarginLeft + self._lineExtraCfg._NodeWidthLeft
    local marginRight = self._lineExtraCfg._MarginRight + self._lineExtraCfg._NodeWidthRight

    local allNodeWidth = maxPosX - minPosX -- 配置中包含了所有 Node 的宽度
    local totalWidth = allNodeWidth + marginLeft + marginRight -- 包含左右边距的宽度
    local firstNodePosX = marginLeft - totalWidth / 2 -- 居中显示，最左侧 Node 的坐标实际位置

    for k, v in pairs(lineMission) do
        v.PosX = v.MapPosX - minPosX + firstNodePosX
        v.PosY = v.MapPosY
        v.ScrollPos = Vector2(-(v.PosX + (totalWidth / 2)), 0) -- 滑动列表拖拽位置
    end

    self.totalWidth = totalWidth
end

function UIActivityN5LineMissionManager:_FillData_Nodes(lineMission, missionState)
    local newConfig = {}
    local config = Cfg.cfg_campaign_mission {}
    for _, v in pairs(config) do
        local id = v.CampaignMissionId
        if lineMission[id] then
            local state = nil
            local starCount = 0
            ---@type DiscoveryStageState
            if missionState[id] then
                state = missionState[id].State
                starCount = missionState[id].StarCount
            end

            local newNode = UIActivityMissionNodeInfo:New()
            newNode:Init(
                id,
                lineMission[id].PosX,
                lineMission[id].PosY,
                v.Name,
                v.Title,
                v.Type,
                lineMission[id].WayPointType == 4, -- S 关卡
                state,
                starCount
            )
            newConfig[id] = newNode
        end
    end

    self.nodes = newConfig
end

function UIActivityN5LineMissionManager:_FillData_Lines(campaignMission, unlockMission)
    local newConfig = {}
    for k, v in pairs(unlockMission) do
        if k ~= 0 and not campaignMission[k].isSLevel then
            for _, vv in ipairs(v) do
                if not campaignMission[vv].isSLevel then
                    table.insert(newConfig, {campaignMission[k], campaignMission[vv]})
                end
            end
        end
    end

    self.lines = newConfig
end

function UIActivityN5LineMissionManager:GetScrollSpliter()
    local posxs = {}
    for _, v in pairs(self.nodes) do
        posxs[#posxs + 1] = v.pos.x
    end
    table.sort(posxs)
    --28个路点按位置从左到右排序，取第11、12、20、21作为背景图分割点
    --return posxs[11], posxs[12], posxs[20], posxs[21]
    return posxs[5], posxs[6], posxs[10], posxs[11]
end
function UIActivityN5LineMissionManager:GetScrollSpliterVec()
    local posxs = {}
    for _, v in pairs(self.nodes) do
        posxs[#posxs + 1] = v.pos.x
    end
    table.sort(posxs)
    --28个路点按位置从左到右排序，取第11、12、20、21作为背景图分割点
    --return posxs[11], posxs[12], posxs[20], posxs[21]
    return {posxs[11], posxs[12]}
end