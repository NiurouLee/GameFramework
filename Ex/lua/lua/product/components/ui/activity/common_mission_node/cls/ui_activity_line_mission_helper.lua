--[[
    快速设置 LineMission 辅助类
]]
---@class UIActivityLineMissionHelper:Object
_class("UIActivityLineMissionHelper", Object)
UIActivityLineMissionHelper = UIActivityLineMissionHelper

function UIActivityLineMissionHelper:Constructor()
end

-- 获取线性关中 node 和 line 的配置
---@param component LineMissionComponent
function UIActivityLineMissionHelper.GetMissionCfgs(component)
    local cmpID = component:GetComponentCfgId() 
    local missionCfgs_temp = Cfg.cfg_component_line_mission { ComponentID = cmpID }
    --所有配置,以id为索引
    local missionCfgs = {}
    for _, cfg in pairs(missionCfgs_temp) do
        missionCfgs[cfg.CampaignMissionId] = cfg
    end
    return missionCfgs
end

-- 获取线性关中 node 和 line 的通用逻辑
---@param component LineMissionComponent
function UIActivityLineMissionHelper.GetNodeLineInfo(component, missionCfgs)
    local componentInfo = component:GetComponentInfo()

    --所有关卡的解锁关系
    local unlockInfo = {}
    local firstMissionID = nil
    for _, cfg in pairs(missionCfgs) do
        if unlockInfo[cfg.NeedMissionId] == nil then
            unlockInfo[cfg.NeedMissionId] = {}
        end
        unlockInfo[cfg.NeedMissionId][cfg.CampaignMissionId] = cfg
        if cfg.NeedMissionId == 0 then
            firstMissionID = cfg.CampaignMissionId
        end
    end
    local showMission = {}
    local levelCount, lineCount = 0, 0
    if next(componentInfo.m_pass_mission_info) then
        for missionID, passInfo in pairs(componentInfo.m_pass_mission_info) do
            if not showMission[missionID] then
                showMission[missionID] = missionCfgs[missionID]
                levelCount = levelCount + 1
            end
            if unlockInfo[missionID] then
                for id, cfg in pairs(unlockInfo[missionID]) do
                    if not showMission[id] then
                        showMission[id] = missionCfgs[id]
                        levelCount = levelCount + 1
                    end
                    --S关和第1关不需要连线
                    if cfg.WayPointType ~= 4 and cfg.NeedMissionId ~= 0 then
                        lineCount = lineCount + 1
                    end
                end
            end
        end
    else
        --没有通关信息则显示第一关
        showMission[firstMissionID] = missionCfgs[firstMissionID]
        levelCount = 1
    end

    return levelCount, lineCount, showMission
end

function UIActivityLineMissionHelper.CalcContentWidth(component, showMission, safeAreaSize_x)
    local cmpID = component:GetComponentCfgId() 
    local extra_cfg = Cfg.cfg_component_line_mission_extra { ComponentID = cmpID }
    local extra_width = extra_cfg[1].MarginRight

    local right = -99999999
    for _, cfg in pairs(showMission) do
        right = math.max(right, cfg.MapPosX)
    end
    --滚动列表总宽度=最右边路点+右边距
    local width = math.abs(right + extra_width)
    width = math.max(safeAreaSize_x, width)
    return width
end

function UIActivityLineMissionHelper.EnterStage_Story(campaign, component, stageId, callback)
    --剧情关
    local missionCfg = Cfg.cfg_campaign_mission[stageId]
    local titleId = StringTable.Get(missionCfg.Title)
    local titleName = StringTable.Get(missionCfg.Name)
    ---@type MissionModule
    local missionModule = GameGlobal.GameLogic():GetModule(MissionModule)
    local storyId = missionModule:GetStoryByStageIdStoryType(stageId, StoryTriggerType.Node)
    if not storyId then
        Log.exception("配置错误,找不到剧情,关卡id:", stageId)
        return
    end

    GameGlobal.UIStateManager():ShowDialog(
        "UIActivityPlotEnter",
        titleId,
        titleName,
        storyId,
        function()
            UIActivityLineMissionHelper.PlotEndCallback(campaign, component, stageId, callback)
        end
    )
end

function UIActivityLineMissionHelper.PlotEndCallback(campaign, component, stageId, callback)
    component:Start_HandleCompleteStoryMission(stageId, function(res, award)
        if not res:GetSucc() then
            campaign._campaign_module:CheckErrorCode(res.m_result, campaign._id, nil, nil)
        else
            if table.count(award) ~= 0 then
                GameGlobal.UIStateManager():ShowDialog("UIGetItemController", award, callback)
            else
                if callback then
                    callback()
                end
            end
        end
    end)
end

function UIActivityLineMissionHelper.EnterStage_Battle(campaign, component, stageId, isReview)
    --战斗关
    local missionCfg = Cfg.cfg_campaign_mission[stageId]
    local autoFightShow = UIActivityLineMissionHelper._CheckSerialAutoFightShow(missionCfg.Type, stageId)
    local pointComponent = campaign:GetComponentByType(CampaignComType.E_CAMPAIGN_COM_ACTION_POINT, 1)
    GameGlobal.UIStateManager():ShowDialog(
        "UIActivityLevelStageNew",
        stageId,
        component:GetComponentInfo().m_pass_mission_info[stageId],
        component,
        autoFightShow,
        pointComponent, --行动点组件
        isReview,  --活动回顾 隐藏顶条
        isReview --活动回顾 隐藏挑战按钮上的体力图标
    )
end

function UIActivityLineMissionHelper._CheckSerialAutoFightShow(stageType, stageId)
    local autoFightShow = false
    if stageType == DiscoveryStageType.Plot then
        autoFightShow = false
    else
        local missionCfg = Cfg.cfg_campaign_mission[stageId]
        if missionCfg then
            local enableParam = missionCfg.EnableSerialAutoFight
            local tb = {
                [CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_DISABLE] = false,
                [CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_ENABLE] = true,
                [CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_NEED_UNLOCK] = true
            }
            autoFightShow = tb[enableParam]
        end
    end
    return autoFightShow
end