--[[
    伊芙醒山活动辅助类
]]
---@class UIActivityEveSinsaHelper
_class("UIActivityEveSinsaHelper", Object)
UIActivityEveSinsaHelper = UIActivityEveSinsaHelper

function UIActivityEveSinsaHelper:Constructor()
end

--region TimePhase
-- 活动时间阶段
--- @class EActivityEveSinsaTimePhase
local EActivityEveSinsaTimePhase = {
    EPhase_Line = 1,
    EPhase_Tree = 2,
    EPhase_Shop = 3,
    EPhase_Over = 4
}
_enum("EActivityEveSinsaTimePhase", EActivityEveSinsaTimePhase)

function UIActivityEveSinsaHelper.CheckTimePhase(campaign)
    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)

    local endTime = UIActivityEveSinsaHelper.GetPhaseEndTime(campaign, EActivityEveSinsaTimePhase.EPhase_Line)
    local stamp = endTime - curTime
    if stamp > 0 then
        return EActivityEveSinsaTimePhase.EPhase_Line
    end

    endTime = UIActivityEveSinsaHelper.GetPhaseEndTime(campaign, EActivityEveSinsaTimePhase.EPhase_Tree)
    stamp = endTime - curTime
    if stamp > 0 then
        return EActivityEveSinsaTimePhase.EPhase_Tree
    end

    endTime = UIActivityEveSinsaHelper.GetPhaseEndTime(campaign, EActivityEveSinsaTimePhase.EPhase_Shop)
    stamp = endTime - curTime
    if stamp > 0 then
        return EActivityEveSinsaTimePhase.EPhase_Shop
    end

    return EActivityEveSinsaTimePhase.EPhase_Over
end

---@param phase EActivityEveSinsaTimePhase
function UIActivityEveSinsaHelper.GetPhaseEndTime(campaign, phase)
    -- EPhase_Line = 1 | 线性关卡阶段，结束点使用树形组件的 unlock_time
    -- EPhase_Tree = 2 | 树形关卡阶段，结束点使用树形组件的 close_time
    -- EPhase_Shop = 3 | 商店阶段，结束点使用第一个兑换组件的 close_time
    -- EPhase_Shop = 4 | 活动结束

    if phase == EActivityEveSinsaTimePhase.EPhase_Over then
        Log.error("UIActivityEveSinsaHelper.GetPhaseEndTime phase = ", phase)
        return 0
    end

    local phase2id = {
        ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_TREE_MISSION,
        ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_TREE_MISSION,
        ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_EXCHANGE1
    }
    local id = phase2id[phase]

    local phase2name = {
        "m_unlock_time",
        "m_close_time",
        "m_close_time"
    }
    local name = phase2name[phase]

    --- @type ICampaignComponentInfo
    local componentInfo = campaign:GetComponentInfo(id)

    return componentInfo and componentInfo[name] or 0
end

function UIActivityEveSinsaHelper.GetPhaseBgUrl(campaign, phase)
    local cfg_campaign = Cfg.cfg_campaign {CampaignID = campaign._id}
    if cfg_campaign then
        local url = cfg_campaign[1].BGImage
        return url[phase]
    end
end
--endregion

--region 特殊处理  线性关卡，S 关卡提前显示，不可挑战
function UIActivityEveSinsaHelper.CheckSpecialMissionShow(campaign)
    if UIActivityEveSinsaHelper.CheckSpecialMissionCanPlay(campaign) then -- 已经正常解锁
        return false
    end

    local cmptId = ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_LINE_MISSION
    ---@type LineMissionComponent
    local component = campaign:GetComponent(cmptId)

    local missionId, needId = UIActivityEveSinsaHelper.GetSpecialMission(campaign)
    --if missionId and component:ComponentIsUnLock() then -- 当树形关卡解锁时，S 关卡提前显示
    --伊芙活动S关的前置关卡，写死；只用一次，此后无S关只显示不能挑战的需求
    local pre_mission_id = 5011013
    if component:IsPassCamMissionID(pre_mission_id) then
        return true, missionId
    end

    return false
end

function UIActivityEveSinsaHelper.CheckSpecialMissionCanPlay(campaign)
    local cmptId = ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_TREE_MISSION
    ---@type TreeMissionComponent
    local component = campaign:GetComponent(cmptId)

    local missionId, needId = UIActivityEveSinsaHelper.GetSpecialMission(campaign)
    if missionId and component:IsPassCamMissionID(needId) then
        return true
    end
    return false
end

function UIActivityEveSinsaHelper.GetSpecialMission(campaign)
    local cmptId = ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_LINE_MISSION
    ---@type LineMissionComponent
    local component = campaign:GetComponent(cmptId)

    local componentCfgId = component:GetComponentCfgId()

    -- 找到需要特殊处理的 SLevel
    local lineCfg = UIActivityEveSinsaHelper.MakeLineConfig(componentCfgId)

    for k, v in pairs(lineCfg) do
        local otherComponentId = v.NeedMissionComponentID
        if otherComponentId and otherComponentId ~= 0 and v.WayPointType == WayPointType.WayPointType_S then
            return k, v.NeedMissionId
        end
    end
end

function UIActivityEveSinsaHelper.MakeLineConfig(componentId)
    local newConfig = {}
    local config = Cfg.cfg_component_line_mission {ComponentID = componentId}
    for _, v in ipairs(config) do
        newConfig[v.CampaignMissionId] = v
    end
    return newConfig
end
--endregion
