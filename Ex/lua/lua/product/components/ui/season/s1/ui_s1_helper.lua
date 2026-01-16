--[[
    活动辅助类
]]
---@class UIS1Helper : Object
_class("UIS1Helper", Object)
UIS1Helper = UIS1Helper

--region Phase

function UIS1Helper.CheckPhase()
    ---@type SeasonModule
    local seasonModule = GameGlobal.GetModule(SeasonModule)
    local seasonObj = seasonModule:GetCurSeasonObj()
    ---@type SeasonMissionComponent
    local component = seasonObj:GetComponent(ECCampaignSeasonComponentID.SEASON_MISSION)
    if not component then
        return 1
    end

    local tb = {
        [1] = {
            id = 8001001,
            mask = SeasonEventPointProgress.SEPP_NotStart
        },
        [2] = {
            id = 8001001,
            mask = SeasonEventPointProgress.SEPP_Finish
        }
    }
    for i, v in ipairs(tb) do
        local mask = component:GetMask(v.id)
        if mask == nil then
            return i
        end
        if mask < v.mask then
            return i - 1
        end
    end
    return #phase
end

function UIS1Helper.GetPhaseSpine(phase)
    local tb = {
        "yifu_kv_1_spine_idle",
        "yifu_kv_2_spine_idle"
    }
    return tb[phase]
end
